"""추천 시스템 스코링 서비스 (룰베이스)"""
import json
import logging
from typing import Optional, List, Dict, Tuple
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.schemas.pet_summary import PetSummaryResponse
from app.models.product import Product, ProductIngredientProfile, ProductNutritionFacts
from app.models.ingredient_config import HarmfulIngredient, AllergenKeyword

logger = logging.getLogger(__name__)


class RecommendationScoringService:
    """추천 시스템 스코링 서비스 - 룰베이스 기반 점수 계산"""
    
    # 가장 흔한 알레르겐 Top 8 (하위 호환성을 위해 유지, DB에서 동적으로 로드 가능)
    COMMON_ALLERGENS_DOG = ["BEEF", "DAIRY", "CHICKEN", "WHEAT", "SOY", "EGG", "LAMB", "CORN"]
    COMMON_ALLERGENS_CAT = ["BEEF", "FISH", "DAIRY", "CHICKEN"]
    
    # 유해 성분 리스트 (하위 호환성을 위해 유지, DB에서 동적으로 로드 가능)
    # DEPRECATED: DB에서 조회하도록 변경됨. _get_harmful_ingredients() 사용 권장
    HARMFUL_INGREDIENTS = [
        "인공색소", "인공향료", "BHA", "BHT", "에톡시퀸",
        "옥수수 시럽", "설탕", "소금 과다"
    ]
    
    # 건강 고민 → Benefits Tags 매핑
    HEALTH_CONCERN_TO_BENEFITS = {
        "OBESITY": "weight_management",
        "SKIN_ALLERGY": "hypoallergenic",
        "JOINT": "joint_support",
        "DIGESTIVE": "digestive",
        "URINARY": "urinary",
        "DIABETES": "weight_management",
        "DENTAL": "dental",
        "SKIN_COAT": "skin_coat",
        "IMMUNE": "immune_support",
    }
    
    # 건강 고민별 가중치
    HEALTH_CONCERN_WEIGHTS = {
        "OBESITY": 10,
        "SKIN_ALLERGY": 8,
        "JOINT": 8,
        "DIGESTIVE": 7,
        "URINARY": 7,
        "DIABETES": 10,
        "DENTAL": 6,
        "SKIN_COAT": 6,
        "IMMUNE": 6,
    }
    
    # 건강 고민 키워드 매핑
    HEALTH_CONCERN_KEYWORDS = {
        "OBESITY": ["저칼로리", "다이어트", "light", "weight", "weight management"],
        "SKIN_ALLERGY": ["저알레르기", "hypoallergenic", "단일단백질", "limited ingredient"],
        "JOINT": ["글루코사민", "콘드로이틴", "glucosamine", "chondroitin", "joint"],
        "DIGESTIVE": ["섬유질", "프로바이오틱스", "probiotic", "fiber", "digestive"],
        "URINARY": ["저인", "저마그네슘", "urinary", "low phosphorus"],
        "DIABETES": ["저탄수화물", "low carb", "grain free", "diabetic"],
        "DENTAL": ["dental", "구강", "치아", "tartar"],
        "SKIN_COAT": ["skin", "coat", "피모", "오메가"],
        "IMMUNE": ["immune", "면역", "antioxidant"],
    }
    
    # 품종 그룹 분류
    SMALL_BREED_CODES = ["말티즈", "푸들", "요크셔테리어", "치와와", "포메라니안"]
    LARGE_BREED_CODES = ["골든리트리버", "래브라도리트리버", "하스키", "세인트버나드"]
    BRACHYCEPHALIC_CODES = ["퍼그", "프렌치불독", "보스턴테리어", "불독"]
    
    @staticmethod
    async def calculate_safety_score(
        pet: PetSummaryResponse,
        product: Product,
        parsed: dict,
        ingredients_text: str = "",
        user_prefs: dict = None,
        db: Optional[AsyncSession] = None,
        harmful_ingredients_cache: Optional[List[str]] = None
    ) -> Tuple[float, List[str]]:
        """
        안전성 점수 계산 (0~100점)
        
        Returns:
            (점수, 매칭 이유 리스트)
        """
        reasons = []
        
        # UPDATED: Customization support - 사용자 선호도 적용
        if user_prefs is None:
            user_prefs = {}
        
        # Hard exclude 알레르겐 합치기 (pet 알레르기 + user_prefs)
        pet_allergies = set(pet.food_allergies or [])
        user_hard_exclude = set(user_prefs.get("hard_exclude_allergens", []))
        combined_hard_exclude = pet_allergies | user_hard_exclude
        
        # 1. 알레르기 체크 (50점 만점) - user_prefs 전달
        allergy_score, allergy_reasons = RecommendationScoringService._check_allergies(
            pet, parsed, ingredients_text, user_prefs, combined_hard_exclude
        )
        reasons.extend(allergy_reasons)
        
        if allergy_score == 0:
            if user_hard_exclude:
                return (0.0, ["Hard excluded due to user setting"])
            return (0.0, ["알레르기 위험으로 제외"])
        
        # UPDATED: Customization support - Soft avoid 성분 체크
        soft_avoid_ingredients = user_prefs.get("soft_avoid_ingredients", [])
        if soft_avoid_ingredients:
            ingredients_lower = ingredients_text.lower()
            for avoid_ingredient in soft_avoid_ingredients:
                if avoid_ingredient.lower() in ingredients_lower:
                    allergy_score -= 20.0
                    reasons.append(f"사용자 설정: {avoid_ingredient} soft avoid 적용 (-20점)")
                    break  # 첫 번째 매칭만 적용
        
        # 2. 유해 성분 체크 (20점 만점)
        harmful_score, harmful_reasons = await RecommendationScoringService._check_harmful_ingredients(
            parsed, ingredients_text, db, harmful_ingredients_cache
        )
        reasons.extend(harmful_reasons)
        
        # UPDATED: Customization support - SAFE 모드일 때 안전성 페널티 강화
        weights_preset = user_prefs.get("weights_preset", "BALANCED")
        if weights_preset == "SAFE":
            # 안전성 관련 페널티 1.2배 강화
            if allergy_score < 50.0:
                penalty = (50.0 - allergy_score) * 0.2
                allergy_score -= penalty
                reasons.append("안전 우선 모드: 알레르기 페널티 강화")
            if harmful_score < 20.0:
                penalty = (20.0 - harmful_score) * 0.2
                harmful_score -= penalty
                reasons.append("안전 우선 모드: 유해 성분 페널티 강화")
        
        # 3. 품질 지표 (30점 만점)
        quality_score, quality_reasons = RecommendationScoringService._calculate_quality_score(parsed)
        reasons.extend(quality_reasons)
        
        total_score = allergy_score + harmful_score + quality_score
        
        return (total_score, reasons)
    
    @staticmethod
    def _check_allergies(
        pet: PetSummaryResponse,
        parsed: dict,
        ingredients_text: str,
        user_prefs: dict = None,
        combined_hard_exclude: set = None
    ) -> Tuple[float, List[str]]:
        """알레르기 체크 (50점 만점)"""
        score = 50.0
        reasons = []
        
        # UPDATED: Customization support - Hard Exclude: pet 알레르기 + user_prefs 합쳐서 체크
        if combined_hard_exclude is None:
            combined_hard_exclude = set(pet.food_allergies or [])
        
        product_allergens = set(parsed.get("potential_allergens", []))
        
        if combined_hard_exclude & product_allergens:
            return (0.0, ["알레르기 성분 포함으로 제외"])
        
        # 2. High Confidence 알레르겐 Penalty
        allergen_confidence = parsed.get("allergen_confidence", {})
        if allergen_confidence:
            common_allergens = (
                RecommendationScoringService.COMMON_ALLERGENS_DOG
                if pet.species == "DOG"
                else RecommendationScoringService.COMMON_ALLERGENS_CAT
            )
            
            for allergen, confidence in allergen_confidence.items():
                if confidence == "high" and allergen in common_allergens:
                    score -= 20.0
                    reasons.append(f"흔한 알레르겐({allergen}) 포함")
                    break  # 첫 번째 high confidence만 체크
        
        # 3. Other Allergies 텍스트 매칭
        if pet.other_allergies:
            other_allergies_lower = pet.other_allergies.lower()
            ingredients_lower = ingredients_text.lower()
            
            if other_allergies_lower in ingredients_lower:
                return (0.0, ["기타 알레르기 성분 포함으로 제외"])
            
            # 부분 매칭 체크
            keywords = other_allergies_lower.split()
            if any(kw in ingredients_lower for kw in keywords if len(kw) > 2):
                return (0.0, ["기타 알레르기 성분 포함으로 제외"])
        
        if score == 50.0:
            reasons.append("알레르기 안전")
        
        return (max(score, 0.0), reasons)
    
    @staticmethod
    async def _get_harmful_ingredients(db: AsyncSession) -> List[str]:
        """DB에서 활성화된 유해 성분 목록 조회"""
        result = await db.execute(
            select(HarmfulIngredient.name)
            .where(HarmfulIngredient.is_active == True)
        )
        return [row[0] for row in result.all()]
    
    @staticmethod
    async def _get_allergen_keywords(db: AsyncSession, allergen_code: str) -> List[str]:
        """DB에서 알레르기 코드에 해당하는 키워드 목록 조회"""
        result = await db.execute(
            select(AllergenKeyword.keyword)
            .where(
                and_(
                    AllergenKeyword.allergen_code == allergen_code,
                    AllergenKeyword.is_active == True
                )
            )
        )
        return [row[0] for row in result.all()]
    
    @staticmethod
    async def _check_harmful_ingredients(
        parsed: dict,
        ingredients_text: str,
        db: Optional[AsyncSession] = None,
        harmful_ingredients_cache: Optional[List[str]] = None
    ) -> Tuple[float, List[str]]:
        """유해 성분 체크 (20점 만점)"""
        score = 20.0
        reasons = []
        
        ingredients_ordered = parsed.get("ingredients_ordered", [])
        all_ingredients = " ".join(ingredients_ordered).lower() + " " + ingredients_text.lower()
        
        # DB에서 유해 성분 조회 (캐시 우선)
        if harmful_ingredients_cache is not None:
            harmful_ingredients = harmful_ingredients_cache
        elif db is not None:
            harmful_ingredients = await RecommendationScoringService._get_harmful_ingredients(db)
        else:
            # Fallback: 하드코딩된 리스트 사용 (하위 호환성)
            harmful_ingredients = RecommendationScoringService.HARMFUL_INGREDIENTS
        
        harmful_count = 0
        for harmful in harmful_ingredients:
            if harmful.lower() in all_ingredients:
                harmful_count += 1
                score -= 5.0
        
        if harmful_count > 0:
            reasons.append(f"유해 성분 {harmful_count}개 포함")
        else:
            reasons.append("유해 성분 없음")
        
        return (max(score, 0.0), reasons)
    
    @staticmethod
    def _calculate_quality_score(parsed: dict) -> Tuple[float, List[str]]:
        """품질 지표 계산 (30점 만점)"""
        score = 0.0
        reasons = []
        
        # 첫 번째 성분이 고기인지 (10점)
        if parsed.get("first_ingredient_is_meat", False):
            score += 10.0
            reasons.append("첫 성분이 고기")
        
        # 단백질 원천 품질 (10점)
        protein_quality = parsed.get("protein_source_quality", "low")
        if protein_quality == "high":
            score += 10.0
            reasons.append("고품질 단백질")
        elif protein_quality == "medium":
            score += 5.0
            reasons.append("중품질 단백질")
        
        # AI 품질 점수 활용 (10점)
        quality_score = parsed.get("quality_score", 0)
        if isinstance(quality_score, (int, float)):
            score += (quality_score / 100) * 10.0
            if quality_score >= 70:
                reasons.append("높은 품질 점수")
        
        return (score, reasons)
    
    @staticmethod
    def calculate_fitness_score(
        pet: PetSummaryResponse,
        product: Product,
        parsed: dict,
        nutrition_facts: Optional[ProductNutritionFacts] = None,
        user_prefs: dict = None
    ) -> Tuple[float, List[str], float]:
        """
        적합성 점수 계산 (0~100점)
        
        Returns:
            (점수, 매칭 이유 리스트, 나이 단계 패널티)
        """
        reasons = []
        
        # 1. 종류 매칭 (20점)
        species_score, species_reasons = RecommendationScoringService._match_species(pet, product)
        reasons.extend(species_reasons)
        
        if species_score == 0:
            return (0.0, ["종류 불일치로 제외"])
        
        # 2. 나이 단계 매칭 (25점)
        age_score, age_reasons, age_penalty = RecommendationScoringService._match_age_stage(
            pet, product, parsed
        )
        reasons.extend(age_reasons)
        
        # UPDATED: Customization support - 사용자 선호도 적용
        if user_prefs is None:
            user_prefs = {}
        
        weights_preset = user_prefs.get("weights_preset", "BALANCED")
        health_concern_priority = user_prefs.get("health_concern_priority", False)
        
        # 3. 건강 고민 매칭 (30점) - user_prefs 전달
        health_score, health_reasons = RecommendationScoringService._match_health_concerns(
            pet, parsed, user_prefs, health_concern_priority
        )
        reasons.extend(health_reasons)
        
        # 4. 품종 특성 매칭 (15점)
        breed_score, breed_reasons = RecommendationScoringService._match_breed(pet, product, parsed)
        reasons.extend(breed_reasons)
        
        # UPDATED: Customization support - VALUE 모드일 때 health_score, breed_score 가중치 낮추기
        if weights_preset == "VALUE":
            health_score = health_score * 0.8
            breed_score = breed_score * 0.8
            if health_score < 30.0 or breed_score < 15.0:
                reasons.append("가성비 우선 모드: 건강 고민/품종 가중치 감소")
        
        # 5. 영양 적합성 (20점)
        nutrition_score, nutrition_reasons = RecommendationScoringService._calculate_nutritional_fitness(
            pet, parsed, nutrition_facts
        )
        reasons.extend(nutrition_reasons)
        
        total_score = species_score + age_score + health_score + breed_score + nutrition_score
        
        # 최대 100점 제한
        total_score = min(total_score, 100.0)
        
        return (total_score, reasons, age_penalty)
    
    @staticmethod
    def _match_species(pet: PetSummaryResponse, product: Product) -> Tuple[float, List[str]]:
        """종류 매칭 (20점 만점)"""
        if product.species is None:
            return (20.0, ["공용 사료 (모든 종류 적합)"])
        elif product.species.value == pet.species:
            return (20.0, [f"{pet.species} 전용 사료"])
        else:
            return (0.0, ["종류 불일치"])
    
    @staticmethod
    def _match_age_stage(
        pet: PetSummaryResponse,
        product: Product,
        parsed: dict
    ) -> Tuple[float, List[str], float]:
        """나이 단계 매칭 (25점 만점) + 패널티"""
        score = 0.0
        reasons = []
        penalty = 0.0
        
        pet_age = pet.age_stage
        if not pet_age:
            return (20.0, ["나이 정보 없음"], 0.0)
        
        # parsed.life_stage 우선 체크
        life_stage = parsed.get("life_stage")
        product_name_lower = product.product_name.lower()
        
        if life_stage == "all_life_stages":
            if pet_age == "PUPPY":
                score = 20.0
            elif pet_age == "ADULT":
                score = 22.0
            elif pet_age == "SENIOR":
                score = 20.0
            else:
                score = 20.0
            reasons.append("전연령 사료")
        
        elif pet_age == "PUPPY":
            if life_stage == "puppy":
                score = 25.0
                reasons.append("강아지용 사료")
            elif life_stage == "adult":
                score = 15.0
                reasons.append("성견용 사료 (강아지도 가능)")
            elif life_stage == "senior":
                score = 0.0
                penalty = 20.0
                reasons.append("노견용 사료 (강아지에게 부적합)")
            elif "퍼피" in product_name_lower or "puppy" in product_name_lower:
                score = 25.0
                reasons.append("강아지용 사료")
            elif "어덜트" in product_name_lower or "adult" in product_name_lower:
                score = 15.0
                reasons.append("성견용 사료")
            elif "시니어" in product_name_lower or "senior" in product_name_lower:
                score = 0.0
                penalty = 20.0
                reasons.append("노견용 사료 (강아지에게 부적합)")
            else:
                score = 15.0
        
        elif pet_age == "ADULT":
            if life_stage == "adult":
                score = 25.0
                reasons.append("성견용 사료")
            elif life_stage == "puppy":
                score = 10.0
                reasons.append("강아지용 사료 (성견도 가능)")
            elif life_stage == "senior":
                score = 20.0
                reasons.append("노견용 사료 (성견도 가능)")
            elif life_stage == "all_life_stages":
                score = 22.0
                reasons.append("전연령 사료")
            elif "어덜트" in product_name_lower or "adult" in product_name_lower:
                score = 25.0
                reasons.append("성견용 사료")
            elif "퍼피" in product_name_lower or "puppy" in product_name_lower:
                score = 10.0
                reasons.append("강아지용 사료")
            elif "시니어" in product_name_lower or "senior" in product_name_lower:
                score = 20.0
                reasons.append("노견용 사료")
            else:
                score = 20.0
        
        elif pet_age == "SENIOR":
            if life_stage == "senior":
                score = 25.0
                reasons.append("노견용 사료")
            elif life_stage == "adult":
                score = 20.0
                reasons.append("성견용 사료 (노견도 가능)")
            elif life_stage == "puppy":
                score = 0.0
                penalty = 15.0
                reasons.append("강아지용 사료 (노견에게 부적합)")
            elif life_stage == "all_life_stages":
                score = 20.0
                reasons.append("전연령 사료")
            elif "시니어" in product_name_lower or "senior" in product_name_lower:
                score = 25.0
                reasons.append("노견용 사료")
            elif "어덜트" in product_name_lower or "adult" in product_name_lower:
                score = 20.0
                reasons.append("성견용 사료")
            elif "퍼피" in product_name_lower or "puppy" in product_name_lower:
                score = 0.0
                penalty = 15.0
                reasons.append("강아지용 사료 (노견에게 부적합)")
            else:
                score = 15.0
        
        return (score, reasons, penalty)
    
    @staticmethod
    def _match_health_concerns(
        pet: PetSummaryResponse, 
        parsed: dict,
        user_prefs: dict = None,
        health_concern_priority: bool = False
    ) -> Tuple[float, List[str]]:
        """건강 고민 매칭 (30점 만점)"""
        score = 0.0
        reasons = []
        
        health_concerns = pet.health_concerns or []
        if not health_concerns:
            return (0.0, [])
        
        benefits_tags = parsed.get("benefits_tags", [])
        notes = parsed.get("notes", "").lower()
        ingredients_ordered = parsed.get("ingredients_ordered", [])
        search_text = notes + " " + " ".join(ingredients_ordered).lower()
        
        # UPDATED: Customization support - 건강 고민 우선 모드 가중치
        health_multiplier = 1.5 if health_concern_priority else 1.0
        
        for concern in health_concerns:
            if concern not in RecommendationScoringService.HEALTH_CONCERN_WEIGHTS:
                continue
            
            base_weight = RecommendationScoringService.HEALTH_CONCERN_WEIGHTS[concern]
            matched = False
            
            # Benefits Tags 우선 체크 (1.5배 가중치)
            if benefits_tags:
                benefit_tag = RecommendationScoringService.HEALTH_CONCERN_TO_BENEFITS.get(concern)
                if benefit_tag and benefit_tag in benefits_tags:
                    score += base_weight * 1.5 * health_multiplier
                    reasons.append(f"{concern} 건강 고민 매칭 (태그)")
                    matched = True
            
            # 키워드 매칭 (fallback)
            if not matched:
                keywords = RecommendationScoringService.HEALTH_CONCERN_KEYWORDS.get(concern, [])
                for keyword in keywords:
                    if keyword.lower() in search_text:
                        score += base_weight * health_multiplier
                        reasons.append(f"{concern} 건강 고민 매칭 (키워드)")
                        matched = True
                        break
        
        # 최대 30점 제한
        score = min(score, 30.0)
        
        if health_concern_priority and score > 0:
            reasons.append("건강 고민 우선 모드: 가중치 1.5배 적용")
        
        return (score, reasons)
    
    @staticmethod
    def _match_breed(
        pet: PetSummaryResponse,
        product: Product,
        parsed: dict
    ) -> Tuple[float, List[str]]:
        """품종 특성 매칭 (15점 만점)"""
        score = 10.0  # 기본 점수
        reasons = []
        
        breed_code = pet.breed_code
        if not breed_code:
            return (score, [])
        
        product_name_lower = product.product_name.lower()
        benefits_tags = parsed.get("benefits_tags", [])
        
        # 품종 그룹 판별
        breed_group = None
        if breed_code in RecommendationScoringService.SMALL_BREED_CODES:
            breed_group = "small"
        elif breed_code in RecommendationScoringService.LARGE_BREED_CODES:
            breed_group = "large"
        elif breed_code in RecommendationScoringService.BRACHYCEPHALIC_CODES:
            breed_group = "brachycephalic"
        
        if breed_group == "small":
            if parsed.get("is_grain_free", False):
                score += 5.0
                reasons.append("무곡물 (소형견 적합)")
            if "소형견" in product.product_name or "small" in product_name_lower:
                score += 5.0
                reasons.append("소형견 전용")
            if benefits_tags and "hypoallergenic" in benefits_tags:
                score += 3.0
                reasons.append("저알레르기 (소형견 적합)")
        
        elif breed_group == "large":
            if "대형견" in product.product_name or "large" in product_name_lower:
                score += 5.0
                reasons.append("대형견 전용")
            if benefits_tags and "joint_support" in benefits_tags:
                score += 5.0
                reasons.append("관절 지원 (대형견 적합)")
            elif RecommendationScoringService._match_health_concern_keyword("JOINT", parsed):
                score += 3.5
                reasons.append("관절 지원 (대형견 적합)")
        
        elif breed_group == "brachycephalic":
            if "다이어트" in product.product_name or "light" in product_name_lower:
                score += 5.0
                reasons.append("저칼로리 (브라키세팔릭 적합)")
            if benefits_tags and "weight_management" in benefits_tags:
                score += 5.0
                reasons.append("체중 관리 (브라키세팔릭 적합)")
        
        # 최대 15점 제한
        score = min(score, 15.0)
        
        return (score, reasons)
    
    @staticmethod
    def _match_health_concern_keyword(concern: str, parsed: dict) -> bool:
        """건강 고민 키워드 매칭 헬퍼"""
        keywords = RecommendationScoringService.HEALTH_CONCERN_KEYWORDS.get(concern, [])
        notes = parsed.get("notes", "").lower()
        ingredients = " ".join(parsed.get("ingredients_ordered", [])).lower()
        search_text = notes + " " + ingredients
        
        return any(kw.lower() in search_text for kw in keywords)
    
    @staticmethod
    def _calculate_nutritional_fitness(
        pet: PetSummaryResponse,
        parsed: dict,
        nutrition_facts: Optional[ProductNutritionFacts]
    ) -> Tuple[float, List[str]]:
        """영양 적합성 계산 (20점 만점) - DER 기반"""
        score = 10.0  # 기본 점수
        reasons = []
        
        # 1. DER 계산
        der = RecommendationScoringService._calculate_der(
            pet.weight_kg,
            pet.age_stage,
            pet.is_neutered,
            pet.species
        )
        
        # 2. kcal_per_kg 가져오기
        kcal_per_kg = None
        
        # parsed.nutritional_profile 우선
        nutritional_profile = parsed.get("nutritional_profile", {})
        if nutritional_profile:
            if "kcal_per_kg" in nutritional_profile:
                kcal_per_kg = nutritional_profile["kcal_per_kg"]
            elif "kcal_per_100g" in nutritional_profile:
                kcal_per_kg = nutritional_profile["kcal_per_100g"] * 10
        
        # nutrition_facts 테이블 fallback
        if kcal_per_kg is None and nutrition_facts and nutrition_facts.kcal_per_100g:
            kcal_per_kg = float(nutrition_facts.kcal_per_100g) * 10
        
        if kcal_per_kg is None:
            return (score, ["칼로리 정보 없음"])
        
        # 3. 하루 급여량 계산 (g/day)
        daily_amount_g = (der / kcal_per_kg) * 1000
        
        # 4. 적정 급여량 범위 체크
        if pet.weight_kg < 10:  # 소형견
            min_amount = pet.weight_kg * 20  # 2% of body weight
            max_amount = pet.weight_kg * 40  # 4% of body weight
        elif pet.weight_kg < 25:  # 중형견
            min_amount = pet.weight_kg * 18
            max_amount = pet.weight_kg * 35
        else:  # 대형견
            min_amount = pet.weight_kg * 15
            max_amount = pet.weight_kg * 30
        
        # 5. 점수 계산
        if min_amount <= daily_amount_g <= max_amount:
            score = 20.0
            reasons.append("적정 급여량 범위")
        elif min_amount * 0.8 <= daily_amount_g <= max_amount * 1.2:
            score = 15.0
            reasons.append("약간 벗어난 급여량")
        elif min_amount * 0.6 <= daily_amount_g <= max_amount * 1.4:
            score = 10.0
            reasons.append("급여량 범위 벗어남")
        else:
            score = 5.0
            reasons.append("급여량 범위 크게 벗어남")
        
        # 6. 중성화 상태 추가 고려
        if pet.is_neutered:
            if daily_amount_g > max_amount:
                score -= 3.0
                reasons.append("중성화 펫에게 칼로리 높음")
            benefits_tags = parsed.get("benefits_tags", [])
            if benefits_tags and "weight_management" in benefits_tags:
                score += 2.0
                reasons.append("체중 관리 사료 (중성화 펫 적합)")
        
        return (max(score, 0.0), reasons)
    
    @staticmethod
    def _calculate_der(
        weight_kg: float,
        age_stage: Optional[str],
        is_neutered: Optional[bool],
        species: str
    ) -> float:
        """
        DER (Daily Energy Requirement) 계산
        RER = 70 * (weight_kg ** 0.75)
        DER = RER * multiplier
        """
        rer = 70 * (weight_kg ** 0.75)
        
        if age_stage == "PUPPY":
            multiplier = 2.5  # 성장기
        elif age_stage == "ADULT":
            if is_neutered:
                multiplier = 1.6
            else:
                multiplier = 1.8
        elif age_stage == "SENIOR":
            multiplier = 1.5
        else:
            multiplier = 1.6  # 기본값
        
        return rer * multiplier
    
    @staticmethod
    def calculate_total_score(
        safety_score: float,
        fitness_score: float,
        age_penalty: float = 0.0,
        user_prefs: dict = None
    ) -> float:
        """
        총점 계산
        
        Args:
            safety_score: 안전성 점수
            fitness_score: 적합성 점수
            age_penalty: 나이 단계 부적합 패널티
            user_prefs: 사용자 선호도 설정
        
        Returns:
            총점 (0 이상)
        """
        # UPDATED: Customization support - 사용자 선호도에 따른 동적 가중치
        if user_prefs is None:
            user_prefs = {}
        
        weights_preset = user_prefs.get("weights_preset", "BALANCED")
        
        # 안전성 점수가 0이면 즉시 제외
        if safety_score == 0:
            return -1.0
        
        # UPDATED: Customization support - weights_preset에 따른 동적 가중치
        if weights_preset == "SAFE":
            # 안전 우선: 0.7 * safety + 0.3 * fitness
            if safety_score < 40:
                total = (safety_score * 0.4) + (fitness_score * 0.1)
            else:
                total = (safety_score * 0.7) + (fitness_score * 0.3)
        elif weights_preset == "VALUE":
            # 가성비 우선: 0.5 * safety + 0.5 * fitness
            if safety_score < 40:
                total = (safety_score * 0.25) + (fitness_score * 0.15)
            else:
                total = (safety_score * 0.5) + (fitness_score * 0.5)
        else:  # BALANCED (기본)
            # 안전성 Hard-Floor 적용
            if safety_score < 40:
                total = (safety_score * 0.3) + (fitness_score * 0.1)
            else:
                total = (safety_score * 0.6) + (fitness_score * 0.4)
        
        # Note: max_price_per_kg 페널티는 ProductService에서 적용 (product 정보 필요)
        
        # 나이 단계 부적합 패널티 적용
        total -= age_penalty
        
        # 최종 점수는 0 이상으로 제한
        return max(total, 0.0)
