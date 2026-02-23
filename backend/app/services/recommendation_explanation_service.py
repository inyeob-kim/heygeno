"""추천 이유 설명 생성 서비스 (RAG 기반)"""
import logging
from pathlib import Path
from typing import List, Optional, Dict, Tuple
from app.utils.openai_client import get_openai_client
from app.core.config import settings

logger = logging.getLogger(__name__)

# Chroma Vector Store 사용
try:
    import chromadb
    CHROMA_AVAILABLE = True
except ImportError:
    CHROMA_AVAILABLE = False
    logger.warning("chromadb가 설치되지 않았습니다. RAG 기능을 사용하려면 'pip install chromadb' 실행 필요")

# TODO: RAG 구현 (v1.1.0)
# 1. Vector Store 구축
#    - Veterinary Allergy 4th Edition 임베딩
#    - FEDIAF 2025 Nutritional Guidelines 임베딩
#    - AAFCO 2025 Official Publication 임베딩
#    - Small Animal Clinical Nutrition (5th Edition) 임베딩
# 2. Retrieval 파이프라인
#    - 펫 프로필 + 상품 정보를 쿼리로 변환
#    - 벡터 유사도 검색으로 Top 5 관련 청크 추출
#    - 각 청크에 출처 메타데이터 포함
# 3. Confidence Score 계산
#    - LLM 응답의 신뢰도 점수 (0~100)
#    - 75점 미만 시 fallback 메시지 사용

SYSTEM_PROMPT_TECHNICAL = """You are an explanation generator for a pet food recommendation system.
Explain the recommendation process to users in a friendly and clear manner.
Write naturally in English, avoiding technical jargon and using simple language.
Keep the explanation concise (2-3 sentences) and include the following:
1. The connection between the pet's characteristics (age, health concerns, allergies, etc.) and the food
2. Why the recommendation system selected this product
3. Specific benefits or effects"""

SYSTEM_PROMPT_EXPERT = """You are a pet food recommendation expert.
Explain the recommendation reasons to users in a friendly and detailed manner.
Write naturally in English, avoiding technical jargon and using simple language.
Write a detailed explanation (3-5 sentences) including the following:
1. The connection between the pet's characteristics (age, health concerns, allergies, etc.) and the food
2. Why the key ingredients or features are beneficial for the pet
3. Professional explanation based on reference materials if available
4. Specific benefits or effects"""

USER_PROMPT_TEMPLATE_TECHNICAL = """Pet Information:
- Name: {pet_name}
- Species: {pet_species}
- Age Stage: {pet_age_stage}
- Weight: {pet_weight} lb
- Breed: {pet_breed}
- Neutered: {pet_neutered}
- Health Concerns: {health_concerns}
- Allergies: {allergies}

Recommended Product:
- Brand: {brand_name}
- Product Name: {product_name}

Technical Reasons:
{technical_reasons}

User Preferences:
{user_prefs_text}

Based on the above information, explain naturally and clearly why the recommendation system selected this food.

Write 2-3 sentences including the following:
1. Start warmly using the pet's name
2. Specifically explain the connection between the pet's characteristics (age stage, health concerns, allergies, etc.) and the food
3. Explain the technical reasons why the recommendation system selected this product
4. If user preferences exist, mention them naturally

Keep the explanation concise and clear, avoiding technical jargon and using simple language."""

USER_PROMPT_TEMPLATE_EXPERT = """Pet Information:
- Name: {pet_name}
- Species: {pet_species}
- Age Stage: {pet_age_stage}
- Weight: {pet_weight} lb
- Breed: {pet_breed}
- Neutered: {pet_neutered}
- Health Concerns: {health_concerns}
- Allergies: {allergies}

Recommended Product:
- Brand: {brand_name}
- Product Name: {product_name}

Technical Reasons:
{technical_reasons}

User Preferences:
{user_prefs_text}

{rag_context}

Based on the above information, explain naturally, kindly, and in detail why this food is recommended for this pet.

Write 3-5 sentences including the following:
1. Start warmly using the pet's name
2. Specifically explain the connection between the pet's characteristics (age stage, health concerns, allergies, etc.) and the food
3. Explain in detail what benefits the key ingredients or features provide to the pet
4. If reference materials (rag_context) are available, add professional and trustworthy explanations based on them
5. If user preferences exist, mention them naturally

Write the explanation specifically and in detail, avoiding technical jargon and using simple language."""


class RecommendationExplanationService:
    """추천 이유 설명 생성 서비스 (RAG 기반)"""
    
    @staticmethod
    async def _retrieve_relevant_chunks(
        pet_species: str,
        health_concerns: List[str],
        allergies: List[str],
        product_name: str,
        top_k: int = 5
    ) -> List[Dict]:
        """
        Vector Store에서 관련 문서 청크 검색
        
        Returns:
            List[Dict]: 각 청크는 {'content': str, 'source': str, 'metadata': dict} 형태
        """
        if not CHROMA_AVAILABLE:
            logger.warning("[RAG] ⚠️ ChromaDB가 설치되지 않아 RAG 검색을 스킵합니다.")
            return []
        
        try:
            # Vector Store 경로
            project_root = Path(__file__).parent.parent.parent
            vector_store_path = project_root / "data" / "vector_store"
            
            logger.info(f"[RAG] 🔍 Vector Store 경로 확인: {vector_store_path}")
            logger.info(f"[RAG] 🔍 Vector Store 존재 여부: {vector_store_path.exists()}")
            
            if not vector_store_path.exists():
                logger.warning(f"[RAG] ⚠️ Vector Store가 없습니다: {vector_store_path}")
                return []
            
            # Chroma 클라이언트 초기화
            client = chromadb.PersistentClient(path=str(vector_store_path))
            
            # 컬렉션 가져오기 (없으면 빈 리스트 반환)
            metadata_corrupted = False
            
            try:
                logger.info("[RAG] 🔍 컬렉션 'pet_food_rag' 조회 시도...")
                
                # list_collections()는 메타데이터 손상 시 실패할 수 있으므로 선택적으로 실행
                try:
                    collections = client.list_collections()
                    collection_names = [c.name for c in collections]
                    logger.info(f"[RAG] 📋 사용 가능한 컬렉션: {collection_names}")
                    
                    if "pet_food_rag" not in collection_names:
                        logger.warning(f"[RAG] ⚠️ 컬렉션 'pet_food_rag'이 존재하지 않습니다. 사용 가능한 컬렉션: {collection_names}")
                        return []
                except KeyError as list_error:
                    # _type KeyError는 메타데이터 손상을 의미
                    if "_type" in str(list_error):
                        metadata_corrupted = True
                        logger.warning(f"[RAG] ⚠️ ChromaDB 메타데이터 손상 감지 (list_collections 실패). 직접 조회 시도...")
                    else:
                        logger.warning(f"[RAG] ⚠️ 컬렉션 목록 조회 실패: {type(list_error).__name__}: {str(list_error)}")
                except Exception as list_error:
                    # 기타 에러는 무시하고 직접 조회 시도
                    logger.debug(f"[RAG] 컬렉션 목록 조회 실패 (무시): {type(list_error).__name__}: {str(list_error)}")
                
                # 직접 컬렉션 조회 시도
                try:
                    collection = client.get_collection(name="pet_food_rag")
                    logger.info(f"[RAG] ✅ 컬렉션 조회 성공: {collection.name}, 문서 수: {collection.count()}")
                except KeyError as get_error:
                    # get_collection()도 _type 에러 발생 시 메타데이터 손상으로 판단
                    if "_type" in str(get_error):
                        metadata_corrupted = True
                        raise  # 외부 except로 전달
                    else:
                        raise
                        
            except KeyError as e:
                # _type KeyError 처리
                if "_type" in str(e) or metadata_corrupted:
                    logger.error(f"[RAG] ❌ ChromaDB 메타데이터 손상으로 컬렉션을 사용할 수 없습니다. "
                               f"해결 방법: vector_store 디렉토리 삭제 후 재생성하거나 ChromaDB를 업데이트하세요.")
                    return []
                else:
                    logger.warning(f"[RAG] ⚠️ 컬렉션 조회 실패: {type(e).__name__}: {str(e)}")
                    return []
            except Exception as e:
                error_type = type(e).__name__
                error_msg = str(e)
                
                # ChromaDB의 특정 에러 타입 확인
                if error_type == "InvalidCollectionException" or "does not exist" in error_msg.lower():
                    logger.warning(f"[RAG] ⚠️ 컬렉션 'pet_food_rag'이 존재하지 않습니다.")
                else:
                    logger.warning(f"[RAG] ⚠️ 컬렉션 조회 실패: {error_type}: {error_msg}")
                
                return []
            
            # Query text generation
            query_parts = []
            if pet_species:
                query_parts.append(f"{pet_species} food")
            if health_concerns:
                query_parts.extend(health_concerns)
            if allergies:
                query_parts.extend([f"{allergy} allergy" for allergy in allergies])
            if product_name:
                query_parts.append(product_name)
            
            query_text = " ".join(query_parts) if query_parts else product_name or "pet food"
            
            logger.info(f"[RAG] 🔍 검색 쿼리: {query_text}")
            
            # 쿼리 임베딩 생성
            openai_client = get_openai_client()
            query_response = openai_client.embeddings.create(
                model="text-embedding-3-small",
                input=query_text
            )
            query_embedding = query_response.data[0].embedding
            
            # Vector Store에서 유사한 문서 검색
            logger.info(f"[RAG] 🔍 Vector Store 검색 시작: top_k={top_k}")
            results = collection.query(
                query_embeddings=[query_embedding],
                n_results=top_k,
                include=["documents", "metadatas", "distances"]
            )
            logger.info(f"[RAG] 🔍 검색 결과: ids={len(results.get('ids', [[]])[0]) if results.get('ids') else 0}개")
            
            # 결과 변환
            chunks = []
            if results["ids"] and len(results["ids"][0]) > 0:
                for idx, doc_id in enumerate(results["ids"][0]):
                    chunk = {
                        "content": results["documents"][0][idx],
                        "source": results["metadatas"][0][idx].get("source", "Unknown"),
                        "file": results["metadatas"][0][idx].get("file", "Unknown"),
                        "distance": results["distances"][0][idx],
                        "metadata": results["metadatas"][0][idx]
                    }
                    chunks.append(chunk)
                
                logger.info(f"[RAG] ✅ {len(chunks)}개 관련 문서 청크 검색 완료")
                
                # RAG 반환값 상세 로그 출력
                logger.info("=" * 80)
                logger.info("[RAG] 📋 RAG 검색 결과 상세:")
                logger.info("=" * 80)
                for idx, chunk in enumerate(chunks, 1):
                    logger.info(f"\n[청크 {idx}/{len(chunks)}]")
                    logger.info(f"  📄 출처 (Source): {chunk.get('source', 'Unknown')}")
                    logger.info(f"  📁 파일 (File): {chunk.get('file', 'Unknown')}")
                    logger.info(f"  📏 유사도 거리 (Distance): {chunk.get('distance', 0.0):.4f}")
                    content = chunk.get('content', '')
                    logger.info(f"  📝 내용 길이: {len(content)}자")
                    logger.info(f"  📝 내용 (Content) - 전체:")
                    logger.info(f"  {'-' * 76}")
                    # 전체 내용을 여러 줄로 출력 (긴 텍스트도 모두 출력)
                    for line in content.split('\n'):
                        logger.info(f"  {line}")
                    logger.info(f"  {'-' * 76}")
                    logger.info(f"  🏷️  메타데이터: {chunk.get('metadata', {})}")
                logger.info("=" * 80)
            else:
                logger.warning("[RAG] ⚠️ 관련 문서를 찾지 못했습니다.")
            
            return chunks
            
        except Exception as e:
            logger.error(f"[RAG] 문서 검색 실패: {str(e)}", exc_info=True)
            return []
    
    @staticmethod
    def _calculate_confidence_score(
        explanation: str,
        retrieved_chunks: List[Dict],
        llm_response_metadata: Optional[Dict] = None
    ) -> float:
        """
        RAG 기반 설명의 신뢰도 점수 계산 (0~100)
        
        Args:
            explanation: 생성된 설명
            retrieved_chunks: 검색된 문서 청크
            llm_response_metadata: LLM 응답 메타데이터 (logprobs 등)
        
        Returns:
            float: 신뢰도 점수 (0~100)
        """
        if not explanation:
            return 0.0
        
        # RAG 문서가 없으면 낮은 신뢰도
        if not retrieved_chunks:
            return 50.0
        
        # 유사도 점수 기반 신뢰도 계산
        # Chroma의 distance는 작을수록 유사함 (0에 가까울수록 좋음)
        # distance를 신뢰도로 변환: distance가 작을수록 높은 신뢰도
        distances = [chunk.get("distance", 1.0) for chunk in retrieved_chunks]
        avg_distance = sum(distances) / len(distances) if distances else 1.0
        
        # distance를 신뢰도로 변환 (0.0 ~ 1.0 범위를 50 ~ 100 점수로 변환)
        # distance가 0.5 이하면 높은 신뢰도 (80~100)
        # distance가 0.5~1.0이면 중간 신뢰도 (60~80)
        # distance가 1.0 이상이면 낮은 신뢰도 (50~60)
        if avg_distance <= 0.5:
            confidence = 80.0 + (0.5 - avg_distance) * 40.0  # 80~100
        elif avg_distance <= 1.0:
            confidence = 60.0 + (1.0 - avg_distance) * 40.0  # 60~80
        else:
            confidence = 50.0 + max(0, 10.0 - (avg_distance - 1.0) * 10.0)  # 50~60
        
        return min(100.0, max(0.0, confidence))
    
    @staticmethod
    async def generate_technical_explanation(
        pet_name: str,
        pet_species: str,
        pet_age_stage: Optional[str],
        pet_weight: float,
        pet_breed: Optional[str],
        pet_neutered: Optional[bool],
        health_concerns: List[str],
        allergies: List[str],
        brand_name: str,
        product_name: str,
        technical_reasons: List[str],
        user_prefs: dict = None
    ) -> str:
        """
        기술적 추천 이유 기반 설명 생성 (RAG 없음, 빠름)
        
        Args:
            pet_name: 펫 이름
            pet_species: 펫 종류 (DOG/CAT)
            pet_age_stage: 나이 단계 (PUPPY/ADULT/SENIOR)
            pet_weight: 체중 (kg)
            pet_breed: 품종 코드
            pet_neutered: 중성화 여부
            health_concerns: 건강 고민 리스트
            allergies: 알레르기 리스트
            brand_name: 브랜드명
            product_name: 상품명
            technical_reasons: 기술적 추천 이유 리스트
            user_prefs: 사용자 선호도
        
        Returns:
            자연어 설명 문자열
        """
        try:
            logger.info(f"[Explanation Service] 🔧 기술적 설명 생성 시작: {pet_name} - {brand_name} {product_name}")
            
            # 기술적 이유를 문자열로 변환
            reasons_text = "\n".join([f"- {reason}" for reason in technical_reasons])
            
            # Age stage conversion to English
            age_stage_en = {
                "PUPPY": "Puppy",
                "ADULT": "Adult",
                "SENIOR": "Senior"
            }.get(pet_age_stage or "", "Adult")
            
            # Species conversion to English
            species_en = "Dog" if pet_species == "DOG" else "Cat"
            
            # Neutered status text
            neutered_text = "Yes" if pet_neutered else "No" if pet_neutered is False else "Unknown"
            
            # Health concerns text
            health_concerns_text = ", ".join(health_concerns) if health_concerns else "None"
            
            # Allergies text
            allergies_text = ", ".join(allergies) if allergies else "None"
            
            # Breed text
            breed_text = pet_breed or "Unknown"
            
            # User preferences text generation
            user_prefs_text = "None"
            if user_prefs:
                weights_preset = user_prefs.get("weights_preset", "BALANCED")
                hard_exclude = user_prefs.get("hard_exclude_allergens", [])
                soft_avoid = user_prefs.get("soft_avoid_ingredients", [])
                max_price = user_prefs.get("max_price_per_kg")
                
                preset_en = {
                    "SAFE": "Safety First",
                    "BALANCED": "Balanced",
                    "VALUE": "Value First"
                }.get(weights_preset, weights_preset)
                
                prefs_parts = [f"Mode: {preset_en}"]
                if hard_exclude:
                    prefs_parts.append(f"Excluded Allergens: {', '.join(hard_exclude)}")
                if soft_avoid:
                    prefs_parts.append(f"Ingredients to Avoid: {', '.join(soft_avoid)}")
                if max_price:
                    prefs_parts.append(f"Max Price: ${max_price:.2f}/kg")
                
                user_prefs_text = ", ".join(prefs_parts) if prefs_parts else "None"
            
            # Convert weight from kg to lb (1 kg = 2.20462 lb)
            weight_lb = pet_weight * 2.20462
            
            prompt = USER_PROMPT_TEMPLATE_TECHNICAL.format(
                pet_name=pet_name,
                pet_species=species_en,
                pet_age_stage=age_stage_en,
                pet_weight=round(weight_lb, 1),
                pet_breed=breed_text,
                pet_neutered=neutered_text,
                health_concerns=health_concerns_text,
                allergies=allergies_text,
                brand_name=brand_name,
                product_name=product_name,
                technical_reasons=reasons_text,
                user_prefs_text=user_prefs_text
            )
            
            client = get_openai_client()
            
            response = client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                temperature=0.7,
                max_tokens=250,  # 기술적 설명은 더 짧게
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT_TECHNICAL},
                    {"role": "user", "content": prompt},
                ],
            )
            
            explanation = response.choices[0].message.content.strip()
            logger.info(f"[Explanation Service] ✅ 기술적 설명 생성 완료: {explanation[:50]}...")
            
            return explanation
            
        except Exception as e:
            logger.error(f"[Explanation Service] 기술적 설명 생성 실패: {str(e)}", exc_info=True)
            # 실패 시 기본 설명 반환
            return RecommendationExplanationService._generate_fallback_explanation(
                pet_name, technical_reasons
            )
    
    @staticmethod
    async def generate_expert_explanation(
        pet_name: str,
        pet_species: str,
        pet_age_stage: Optional[str],
        pet_weight: float,
        pet_breed: Optional[str],
        pet_neutered: Optional[bool],
        health_concerns: List[str],
        allergies: List[str],
        brand_name: str,
        product_name: str,
        technical_reasons: List[str],
        user_prefs: dict = None
    ) -> str:
        """
        RAG 기반 전문가 수준 설명 생성 (느림)
        
        Args:
            pet_name: 펫 이름
            pet_species: 펫 종류 (DOG/CAT)
            pet_age_stage: 나이 단계 (PUPPY/ADULT/SENIOR)
            pet_weight: 체중 (kg)
            pet_breed: 품종 코드
            pet_neutered: 중성화 여부
            health_concerns: 건강 고민 리스트
            allergies: 알레르기 리스트
            brand_name: 브랜드명
            product_name: 상품명
            technical_reasons: 기술적 추천 이유 리스트
            user_prefs: 사용자 선호도
        
        Returns:
            자연어 설명 문자열
        """
        try:
            # RAG: 관련 문서 검색
            logger.info("=" * 80)
            logger.info(f"[RAG] 🎯 RAG 실행 시작: pet_species={pet_species}, product={product_name}")
            logger.info(f"[RAG] 📋 입력 파라미터: health_concerns={health_concerns}, allergies={allergies}")
            logger.info("=" * 80)
            retrieved_chunks = await RecommendationExplanationService._retrieve_relevant_chunks(
                pet_species=pet_species,
                health_concerns=health_concerns,
                allergies=allergies,
                product_name=product_name,
                top_k=5
            )
            logger.info(f"[RAG] ✅ RAG 검색 완료: {len(retrieved_chunks)}개 문서 청크 발견")
            
            # RAG 반환값 전체 로그 출력
            if retrieved_chunks:
                logger.info("\n" + "=" * 80)
                logger.info("[RAG] 📊 전문가 설명 생성에서 받은 RAG 결과 전체:")
                logger.info("=" * 80)
                for idx, chunk in enumerate(retrieved_chunks, 1):
                    logger.info(f"\n[청크 {idx}/{len(retrieved_chunks)}]")
                    logger.info(f"  출처: {chunk.get('source', 'Unknown')}")
                    logger.info(f"  파일: {chunk.get('file', 'Unknown')}")
                    logger.info(f"  거리: {chunk.get('distance', 0.0):.4f}")
                    content = chunk.get('content', '')
                    logger.info(f"  내용 길이: {len(content)}자")
                    logger.info(f"  내용 (Content) - 전체:")
                    logger.info(f"  {'-' * 76}")
                    # 전체 내용을 여러 줄로 출력
                    for line in content.split('\n'):
                        logger.info(f"  {line}")
                    logger.info(f"  {'-' * 76}")
                    logger.info(f"  메타데이터: {chunk.get('metadata', {})}")
                logger.info("=" * 80 + "\n")
            
            # RAG context generation
            rag_context = ""
            if retrieved_chunks:
                rag_context = "\nReference Materials (Expert Documents):\n"
                for idx, chunk in enumerate(retrieved_chunks[:5], 1):
                    source = chunk.get("source", "Unknown")
                    content = chunk.get("content", "")[:500]  # Use only 500 characters in prompt
                    distance = chunk.get("distance", 0.0)
                    rag_context += f"{idx}. [{source}] (Similarity: {1-distance:.2f})\n{content}\n\n"
                
                # Log full RAG context
                logger.info("[RAG] 📄 RAG context to be passed to LLM:")
                logger.info("=" * 80)
                logger.info(rag_context)
                logger.info("=" * 80)
            else:
                rag_context = "\nReference Materials: None\n"
                logger.info("[RAG] ⚠️ No RAG context (retrieved_chunks is empty)")
            
            # 기술적 이유를 문자열로 변환
            reasons_text = "\n".join([f"- {reason}" for reason in technical_reasons])
            
            # Age stage conversion to English
            age_stage_en = {
                "PUPPY": "Puppy",
                "ADULT": "Adult",
                "SENIOR": "Senior"
            }.get(pet_age_stage or "", "Adult")
            
            # Species conversion to English
            species_en = "Dog" if pet_species == "DOG" else "Cat"
            
            # Neutered status text
            neutered_text = "Yes" if pet_neutered else "No" if pet_neutered is False else "Unknown"
            
            # Health concerns text
            health_concerns_text = ", ".join(health_concerns) if health_concerns else "None"
            
            # Allergies text
            allergies_text = ", ".join(allergies) if allergies else "None"
            
            # Breed text
            breed_text = pet_breed or "Unknown"
            
            # User preferences text generation
            user_prefs_text = "None"
            if user_prefs:
                weights_preset = user_prefs.get("weights_preset", "BALANCED")
                hard_exclude = user_prefs.get("hard_exclude_allergens", [])
                soft_avoid = user_prefs.get("soft_avoid_ingredients", [])
                max_price = user_prefs.get("max_price_per_kg")
                
                preset_en = {
                    "SAFE": "Safety First",
                    "BALANCED": "Balanced",
                    "VALUE": "Value First"
                }.get(weights_preset, weights_preset)
                
                prefs_parts = [f"Mode: {preset_en}"]
                if hard_exclude:
                    prefs_parts.append(f"Excluded Allergens: {', '.join(hard_exclude)}")
                if soft_avoid:
                    prefs_parts.append(f"Ingredients to Avoid: {', '.join(soft_avoid)}")
                if max_price:
                    prefs_parts.append(f"Max Price: ${max_price:.2f}/kg")
                
                user_prefs_text = ", ".join(prefs_parts) if prefs_parts else "None"
            
            # Convert weight from kg to lb (1 kg = 2.20462 lb)
            weight_lb = pet_weight * 2.20462
            
            prompt = USER_PROMPT_TEMPLATE_EXPERT.format(
                pet_name=pet_name,
                pet_species=species_en,
                pet_age_stage=age_stage_en,
                pet_weight=round(weight_lb, 1),
                pet_breed=breed_text,
                pet_neutered=neutered_text,
                health_concerns=health_concerns_text,
                allergies=allergies_text,
                brand_name=brand_name,
                product_name=product_name,
                technical_reasons=reasons_text,
                user_prefs_text=user_prefs_text,
                rag_context=rag_context
            )
            
            # 생성된 프롬프트 전체 로그 출력
            logger.info("[Explanation Service] 📝 생성된 프롬프트 전체:")
            logger.info("=" * 80)
            logger.info(f"System Prompt:\n{SYSTEM_PROMPT_EXPERT}")
            logger.info("-" * 80)
            logger.info(f"User Prompt:\n{prompt}")
            logger.info("=" * 80)
            
            client = get_openai_client()
            
            logger.info(f"[Explanation Service] 🎓 전문가 설명 생성 시작: {pet_name} - {brand_name} {product_name}")
            
            response = client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                temperature=0.7,
                max_tokens=400,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT_EXPERT},
                    {"role": "user", "content": prompt},
                ],
            )
            
            explanation = response.choices[0].message.content.strip()
            
            # LLM 응답 전체 로그 출력
            logger.info("[Explanation Service] 🤖 LLM 응답 전체:")
            logger.info("=" * 80)
            logger.info(explanation)
            logger.info("=" * 80)
            logger.info(f"응답 길이: {len(explanation)}자")
            
            # Confidence Score 계산
            confidence_score = RecommendationExplanationService._calculate_confidence_score(
                explanation=explanation,
                retrieved_chunks=retrieved_chunks
            )
            
            logger.info(f"[Explanation Service] ✅ 전문가 설명 생성 완료: {explanation[:50]}... (신뢰도: {confidence_score:.1f}점)")
            
            # 신뢰도가 75점 미만이면 fallback 메시지 사용
            if confidence_score < 75.0:
                logger.warning(f"[Explanation Service] 신뢰도가 낮아 fallback 메시지 사용: {confidence_score:.1f}점")
                return RecommendationExplanationService._generate_fallback_explanation(
                    pet_name, technical_reasons
                )
            
            return explanation
            
        except Exception as e:
            logger.error(f"[Explanation Service] 전문가 설명 생성 실패: {str(e)}", exc_info=True)
            # 실패 시 기본 설명 반환
            return RecommendationExplanationService._generate_fallback_explanation(
                pet_name, technical_reasons
            )
    
    @staticmethod
    async def generate_explanation(
        pet_name: str,
        pet_species: str,
        pet_age_stage: Optional[str],
        pet_weight: float,
        pet_breed: Optional[str],
        pet_neutered: Optional[bool],
        health_concerns: List[str],
        allergies: List[str],
        brand_name: str,
        product_name: str,
        technical_reasons: List[str],
        user_prefs: dict = None
    ) -> str:
        """
        [Deprecated] 하위 호환성을 위해 유지
        전문가 설명(expert_explanation)을 생성합니다.
        """
        logger.warning("[Explanation Service] generate_explanation은 deprecated입니다. generate_expert_explanation을 사용하세요.")
        return await RecommendationExplanationService.generate_expert_explanation(
            pet_name=pet_name,
            pet_species=pet_species,
            pet_age_stage=pet_age_stage,
            pet_weight=pet_weight,
            pet_breed=pet_breed,
            pet_neutered=pet_neutered,
            health_concerns=health_concerns,
            allergies=allergies,
            brand_name=brand_name,
            product_name=product_name,
            technical_reasons=technical_reasons,
            user_prefs=user_prefs
        )
    
    @staticmethod
    def _generate_fallback_explanation(pet_name: str, technical_reasons: List[str]) -> str:
        """Generate fallback explanation when LLM fails"""
        if not technical_reasons:
            return f"This food is suitable for {pet_name}."
        
        # Select only main reasons (max 3)
        main_reasons = technical_reasons[:3]
        reasons_text = ", ".join(main_reasons)
        
        return f"This food is recommended for {pet_name} because of {reasons_text}."
