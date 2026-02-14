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

SYSTEM_PROMPT_TECHNICAL = """너는 반려동물 사료 추천 시스템의 설명 생성기다.
사용자에게 추천 과정을 친절하고 명확하게 설명해줘.
한국어로 자연스럽게 설명하고, 전문 용어는 피하고 쉬운 말로 풀어서 설명해줘.
설명은 2-3문장으로 간결하게 작성하고, 다음 내용을 포함해줘:
1. 펫의 특성(나이, 건강 고민, 알레르기 등)과 사료의 연결점
2. 추천 시스템이 이 상품을 선택한 이유
3. 구체적인 혜택이나 효과"""

SYSTEM_PROMPT_EXPERT = """너는 반려동물 사료 추천 전문가다.
사용자에게 추천 이유를 친절하고 상세하게 설명해줘.
한국어로 자연스럽게 설명하고, 전문 용어는 피하고 쉬운 말로 풀어서 설명해줘.
설명은 3-5문장으로 상세하게 작성하고, 다음 내용을 포함해줘:
1. 펫의 특성(나이, 건강 고민, 알레르기 등)과 사료의 연결점
2. 주요 성분이나 특징이 펫에게 왜 좋은지
3. 참고 자료가 있으면 그것을 근거로 한 전문적인 설명
4. 구체적인 혜택이나 효과"""

USER_PROMPT_TEMPLATE_TECHNICAL = """펫 정보:
- 이름: {pet_name}
- 종류: {pet_species}
- 나이 단계: {pet_age_stage}
- 체중: {pet_weight}kg
- 품종: {pet_breed}
- 중성화: {pet_neutered}
- 건강 고민: {health_concerns}
- 알레르기: {allergies}

추천 상품:
- 브랜드: {brand_name}
- 상품명: {product_name}

추천 이유 (기술적):
{technical_reasons}

사용자 선호도:
{user_prefs_text}

위 정보를 바탕으로, 추천 시스템이 이 사료를 왜 선택했는지 자연스럽고 명확하게 설명해줘.

다음 내용을 포함해서 2-3문장으로 작성해줘:
1. 펫의 이름을 사용해서 친근하게 시작
2. 펫의 특성(나이 단계, 건강 고민, 알레르기 등)과 사료의 연결점을 구체적으로 설명
3. 추천 시스템이 이 상품을 선택한 기술적 이유를 설명
4. 사용자 선호도가 있으면 그것도 자연스럽게 언급

설명은 간결하고 명확하게 작성하되, 전문 용어는 피하고 쉬운 말로 풀어서 설명해줘."""

USER_PROMPT_TEMPLATE_EXPERT = """펫 정보:
- 이름: {pet_name}
- 종류: {pet_species}
- 나이 단계: {pet_age_stage}
- 체중: {pet_weight}kg
- 품종: {pet_breed}
- 중성화: {pet_neutered}
- 건강 고민: {health_concerns}
- 알레르기: {allergies}

추천 상품:
- 브랜드: {brand_name}
- 상품명: {product_name}

추천 이유 (기술적):
{technical_reasons}

사용자 선호도:
{user_prefs_text}

{rag_context}

위 정보를 바탕으로, 이 사료가 왜 이 펫에게 추천되는지 자연스럽고 친절하게 상세하게 설명해줘.

다음 내용을 포함해서 3-5문장으로 작성해줘:
1. 펫의 이름을 사용해서 친근하게 시작
2. 펫의 특성(나이 단계, 건강 고민, 알레르기 등)과 사료의 연결점을 구체적으로 설명
3. 주요 성분이나 특징이 펫에게 어떤 혜택을 주는지 상세히 설명
4. 참고 자료(rag_context)가 있으면 그것을 근거로 전문적이고 신뢰할 수 있는 설명 추가
5. 사용자 선호도가 있으면 그것도 자연스럽게 언급

설명은 구체적이고 상세하게 작성하되, 전문 용어는 피하고 쉬운 말로 풀어서 설명해줘."""


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
            try:
                logger.info("[RAG] 🔍 컬렉션 'pet_food_rag' 조회 시도...")
                collection = client.get_collection(name="pet_food_rag")
                logger.info(f"[RAG] ✅ 컬렉션 조회 성공: {collection.name}, 문서 수: {collection.count()}")
            except Exception as e:
                logger.warning(f"[RAG] ⚠️ 컬렉션을 찾을 수 없습니다: {str(e)}")
                return []
            
            # 쿼리 텍스트 생성
            query_parts = []
            if pet_species:
                query_parts.append(f"{pet_species} 사료")
            if health_concerns:
                query_parts.extend(health_concerns)
            if allergies:
                query_parts.extend([f"{allergy} 알레르기" for allergy in allergies])
            if product_name:
                query_parts.append(product_name)
            
            query_text = " ".join(query_parts) if query_parts else product_name or "반려동물 사료"
            
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
            
            # 나이 단계 한글 변환
            age_stage_kr = {
                "PUPPY": "강아지",
                "ADULT": "성견",
                "SENIOR": "노견"
            }.get(pet_age_stage or "", "성견")
            
            # 종류 한글 변환
            species_kr = "강아지" if pet_species == "DOG" else "고양이"
            
            # 중성화 여부 텍스트
            neutered_text = "완료" if pet_neutered else "미완료" if pet_neutered is False else "모름"
            
            # 건강 고민 텍스트
            health_concerns_text = ", ".join(health_concerns) if health_concerns else "없음"
            
            # 알레르기 텍스트
            allergies_text = ", ".join(allergies) if allergies else "없음"
            
            # 품종 텍스트
            breed_text = pet_breed or "정보 없음"
            
            # 사용자 선호도 텍스트 생성
            user_prefs_text = "없음"
            if user_prefs:
                weights_preset = user_prefs.get("weights_preset", "BALANCED")
                hard_exclude = user_prefs.get("hard_exclude_allergens", [])
                soft_avoid = user_prefs.get("soft_avoid_ingredients", [])
                max_price = user_prefs.get("max_price_per_kg")
                
                preset_kr = {
                    "SAFE": "안전 우선",
                    "BALANCED": "균형",
                    "VALUE": "가성비 우선"
                }.get(weights_preset, weights_preset)
                
                prefs_parts = [f"모드: {preset_kr}"]
                if hard_exclude:
                    prefs_parts.append(f"제외 알레르겐: {', '.join(hard_exclude)}")
                if soft_avoid:
                    prefs_parts.append(f"피하고 싶은 성분: {', '.join(soft_avoid)}")
                if max_price:
                    prefs_parts.append(f"최대 가격: {max_price}원/kg")
                
                user_prefs_text = ", ".join(prefs_parts) if prefs_parts else "없음"
            
            prompt = USER_PROMPT_TEMPLATE_TECHNICAL.format(
                pet_name=pet_name,
                pet_species=species_kr,
                pet_age_stage=age_stage_kr,
                pet_weight=pet_weight,
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
            
            # RAG 컨텍스트 생성
            rag_context = ""
            if retrieved_chunks:
                rag_context = "\n참고 자료 (전문 문서):\n"
                for idx, chunk in enumerate(retrieved_chunks[:5], 1):
                    source = chunk.get("source", "Unknown")
                    content = chunk.get("content", "")[:500]  # 프롬프트에는 500자만 사용
                    distance = chunk.get("distance", 0.0)
                    rag_context += f"{idx}. [{source}] (유사도: {1-distance:.2f})\n{content}\n\n"
                
                # RAG 컨텍스트 전체 로그 출력
                logger.info("[RAG] 📄 LLM에 전달될 RAG 컨텍스트:")
                logger.info("=" * 80)
                logger.info(rag_context)
                logger.info("=" * 80)
            else:
                rag_context = "\n참고 자료: 없음\n"
                logger.info("[RAG] ⚠️ RAG 컨텍스트 없음 (retrieved_chunks가 비어있음)")
            
            # 기술적 이유를 문자열로 변환
            reasons_text = "\n".join([f"- {reason}" for reason in technical_reasons])
            
            # 나이 단계 한글 변환
            age_stage_kr = {
                "PUPPY": "강아지",
                "ADULT": "성견",
                "SENIOR": "노견"
            }.get(pet_age_stage or "", "성견")
            
            # 종류 한글 변환
            species_kr = "강아지" if pet_species == "DOG" else "고양이"
            
            # 중성화 여부 텍스트
            neutered_text = "완료" if pet_neutered else "미완료" if pet_neutered is False else "모름"
            
            # 건강 고민 텍스트
            health_concerns_text = ", ".join(health_concerns) if health_concerns else "없음"
            
            # 알레르기 텍스트
            allergies_text = ", ".join(allergies) if allergies else "없음"
            
            # 품종 텍스트
            breed_text = pet_breed or "정보 없음"
            
            # 사용자 선호도 텍스트 생성
            user_prefs_text = "없음"
            if user_prefs:
                weights_preset = user_prefs.get("weights_preset", "BALANCED")
                hard_exclude = user_prefs.get("hard_exclude_allergens", [])
                soft_avoid = user_prefs.get("soft_avoid_ingredients", [])
                max_price = user_prefs.get("max_price_per_kg")
                
                preset_kr = {
                    "SAFE": "안전 우선",
                    "BALANCED": "균형",
                    "VALUE": "가성비 우선"
                }.get(weights_preset, weights_preset)
                
                prefs_parts = [f"모드: {preset_kr}"]
                if hard_exclude:
                    prefs_parts.append(f"제외 알레르겐: {', '.join(hard_exclude)}")
                if soft_avoid:
                    prefs_parts.append(f"피하고 싶은 성분: {', '.join(soft_avoid)}")
                if max_price:
                    prefs_parts.append(f"최대 가격: {max_price}원/kg")
                
                user_prefs_text = ", ".join(prefs_parts) if prefs_parts else "없음"
            
            prompt = USER_PROMPT_TEMPLATE_EXPERT.format(
                pet_name=pet_name,
                pet_species=species_kr,
                pet_age_stage=age_stage_kr,
                pet_weight=pet_weight,
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
        """LLM 실패 시 기본 설명 생성"""
        if not technical_reasons:
            return f"{pet_name}에게 적합한 사료입니다."
        
        # 주요 이유만 선택 (최대 3개)
        main_reasons = technical_reasons[:3]
        reasons_text = ", ".join(main_reasons)
        
        return f"{pet_name}에게 {reasons_text} 등의 이유로 추천되는 사료입니다."
