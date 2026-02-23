# 맞춤 사료 추천 시스템 설계

## 개요
홈화면에서 "딱 맞는 사료 보기" 버튼을 클릭하면, 펫 프로필 정보를 기반으로 `parsed` JSON이 적재된 상품들 중에서 가장 안전하고 적합한 사료를 추천하는 시스템입니다.

---

## 1. API 호출 흐름

### 1.1 프론트엔드 → 백엔드 호출
```
GET /api/v1/products/recommendations?pet_id={pet_id}
```

**현재 상태:**
- 엔드포인트: `backend/app/api/v1/products.py`의 `get_recommendations()`
- 현재 구현: Mock 데이터 반환 (TODO 상태)
- 변경 필요: 실제 추천 로직 구현

### 1.2 백엔드 처리 흐름
```
1. pet_id로 PetSummary 조회 (기존 PetService.get_primary_pet_by_device_uid 사용)
   ↓
2. 활성 상품 중 parsed JSON이 있는 상품만 필터링
   ↓
3. 각 상품에 대해 스코링 (점수 계산)
   ↓
4. 점수 순으로 정렬 (높은 점수 우선)
   ↓
5. 상위 N개 추천 (예: 상위 10개)
   ↓
6. 각 추천 상품에 판매처 정보(가격 등) 추가
   ↓
7. RecommendationResponse 반환
```

---

## 2. 데이터 구조

### 2.1 입력: 펫 프로필 정보 (`PetSummaryResponse`)
```python
{
    "id": UUID,
    "name": str,
    "species": "DOG" | "CAT",
    "age_stage": "PUPPY" | "ADULT" | "SENIOR" | None,
    "approx_age_months": int | None,
    "weight_kg": float,
    "breed_code": str | None,  # 품종 코드
    "sex": "MALE" | "FEMALE" | "UNKNOWN" | None,
    "is_neutered": bool | None,
    "health_concerns": List[str],  # 건강 고민 코드 리스트
    "food_allergies": List[str],  # 알레르기 코드 리스트 (예: ["CHICKEN", "CORN"])
    "other_allergies": str | None,  # 기타 알레르기 텍스트
}
```

### 2.2 입력: 상품의 `parsed` JSON 구조

#### 2.2.1 기본 필드 (현재 구조)
```json
{
    "raw_text": "...",
    "ingredients_ordered": ["옥수수", "닭고기분", "동물성 지방", ...],
    "first_five": ["옥수수", "닭고기분", "동물성 지방", "밀", "쌀"],
    "animal_proteins": ["닭고기분", "닭고기 부산물", "어분"],
    "plant_proteins": [],
    "grains": ["옥수수", "밀", "쌀"],
    "potential_allergens": ["CHICKEN", "CORN", "WHEAT"],  // 알레르겐 코드 배열
    "additives": ["비타민E", "비타민C"],
    "is_grain_free": false,
    "first_ingredient_is_meat": false,
    "protein_source_quality": "low" | "medium" | "high",
    "quality_score": 0-100,
    "notes": "한 줄 요약"
}
```

#### 2.2.2 확장 필드 제안 (추천 시스템 강화를 위해 추가 권장)
```json
{
    // 기존 필드...
    
    // 생애 단계 정보
    "life_stage": "puppy" | "adult" | "senior" | "all_life_stages" | null,
    
    // 건강 기능 태그 (benefits)
    "benefits_tags": [
        "joint_support",      // 관절 지원
        "weight_management",  // 체중 관리
        "hypoallergenic",     // 저알레르기
        "urinary",            // 요로 건강
        "digestive",          // 소화 건강
        "dental",             // 구강 건강
        "skin_coat",          // 피모 건강
        "immune_support"      // 면역 지원
    ],
    
    // 영양 프로필 (정량적 정보)
    "nutritional_profile": {
        "protein_min": 25.0,      // 단백질 최소값 (%)
        "fat_min": 12.0,          // 지방 최소값 (%)
        "fiber_max": 5.0,         // 섬유질 최대값 (%)
        "kcal_per_kg": 3500,      // 1kg당 칼로리 (kcal/kg)
        "kcal_per_100g": 350      // 100g당 칼로리 (kcal/100g)
    },
    
    // 알레르겐 신뢰도 (선택적, 있으면 더 정확한 필터링 가능)
    "allergen_confidence": {
        "CHICKEN": "high",    // "high" | "medium" | "low"
        "CORN": "medium",
        "WHEAT": "low"
    }
}
```

**변경/추가 내용:** parsed JSON 스키마에 `life_stage`, `benefits_tags`, `nutritional_profile`, `allergen_confidence` 필드 추가 제안. 이 필드들이 있으면 추천 정확도가 크게 향상됨.

---

## 3. 스코링 시스템 설계

### 3.1 전체 점수 계산식

#### 3.1.1 기본 가중치
```
기본 총점 = 안전성 점수 × 0.6 + 적합성 점수 × 0.4
```

**가중치 설명:**
- **안전성 (60%)**: 알레르기, 유해 성분 등 안전 관련
- **적합성 (40%)**: 나이, 품종, 건강 상태 등 적합성 관련

#### 3.1.2 안전성 Hard-Floor 적용
```
if 안전성_점수 < 40:
    # 안전성이 낮으면 강하게 페널티
    총점 = 안전성_점수 × 0.3 + 적합성_점수 × 0.1
else:
    총점 = 안전성_점수 × 0.6 + 적합성_점수 × 0.4
```

**변경/추가 내용:** 안전성 점수가 40점 미만이면 총점 계산 시 가중치를 크게 낮춰 안전하지 않은 상품을 하위로 밀어냄. 안전성 0점 상품은 여전히 즉시 제외.

### 3.2 안전성 점수 (Safety Score) - 0~100점

#### 3.2.1 알레르기 체크 (가장 중요) - 50점 만점

**알레르겐 코드 표준화:**
- `potential_allergens`는 알레르겐 코드 배열 (예: `["CHICKEN", "CORN", "WHEAT"]`)
- 가장 흔한 알레르겐 Top 8:
  - **강아지 (DOG)**: BEEF, DAIRY, CHICKEN, WHEAT, SOY, EGG, LAMB, CORN
  - **고양이 (CAT)**: BEEF, FISH, DAIRY, CHICKEN

**점수 계산 로직:**
```
알레르기 점수 = 50점
Allergy prodigy Chicago
# 1. Hard Exclude: 펫의 food_allergies와 상품의 potential_allergens 겹침 체크
펫_알레르기_셋 = set(펫.food_allergies)
상품_알레르겐_셋 = set(상품.parsed.potential_allergens)

if 펫_알레르기_셋 & 상품_알레르겐_셋:  # 교집합이 있으면
    알레르기 점수 = 0점 (즉시 제외)
    return 0점

# 2. High Confidence 알레르겐 Penalty (펫 알레르기 목록에 없어도)
if 상품.parsed.allergen_confidence가 있으면:
    for 알레르겐, 신뢰도 in 상품.parsed.allergen_confidence.items():
        if 신뢰도 == "high":
            # 가장 흔한 알레르겐 Top 8에 포함되면 penalty
            if 알레르겐 in ["BEEF", "DAIRY", "CHICKEN", "WHEAT", "SOY", "EGG", "LAMB", "CORN"]:
                알레르기 점수 -= 20점 (최소 0점)
                break  # 첫 번째 high confidence 알레르겐만 체크

# 3. Other Allergies 텍스트 매칭 (Fuzzy/KW 포함)
if 펫.other_allergies:
    other_allergies_lower = 펫.other_allergies.lower()
    ingredients_text_lower = " ".join(상품.parsed.ingredients_ordered).lower()
    
    # 키워드 포함 여부로 체크 (간단한 fuzzy matching)
    if other_allergies_lower in ingredients_text_lower:
        알레르기 점수 = 0점 (즉시 제외)
    # 부분 매칭도 체크 (예: "닭" → "닭고기" 매칭)
    elif any(키워드 in ingredients_text_lower for 키워드 in other_allergies_lower.split()):
        알레르기 점수 = 0점 (즉시 제외)
```

**예시:**
- 펫 알레르기: `["CHICKEN", "CORN"]`
- 상품 알레르겐: `["CHICKEN", "WHEAT"]` → 겹침: `CHICKEN` → **0점 (제외)**
- 상품 알레르겐: `["BEEF", "FISH"]`, `allergen_confidence: {"BEEF": "high"}` → 펫 알레르기 없지만 high confidence → **30점 (50-20)**
- 상품 알레르겐: `["BEEF", "FISH"]`, 신뢰도 없음 → **50점**

**변경/추가 내용:** 알레르기 체크 강화 - food_allergies는 hard exclude 유지, high confidence 알레르겐에 대해 -20점 penalty 추가, other_allergies는 키워드 포함/fuzzy matching으로 체크.

#### 3.2.2 유해 성분 체크 - 20점 만점
```
유해 성분 점수 = 20점

# 일반적으로 피해야 할 성분들 (예시)
유해_성분_리스트 = [
    "인공색소", "인공향료", "BHA", "BHT", "에톡시퀸", 
    "옥수수 시럽", "설탕", "소금 과다"
]

for 성분 in 상품.ingredients_ordered:
    if 성분 in 유해_성분_리스트:
        유해_성분_점수 -= 5점 (최소 0점)
```

#### 3.2.3 품질 지표 - 30점 만점
```
품질 점수 = 0점

# 첫 번째 성분이 고기인지 (10점)
if parsed.first_ingredient_is_meat == true:
    품질 점수 += 10점

# 단백질 원천 품질 (10점)
if parsed.protein_source_quality == "high":
    품질 점수 += 10점
elif parsed.protein_source_quality == "medium":
    품질 점수 += 5점

# AI 품질 점수 활용 (10점)
품질 점수 += (parsed.quality_score / 100) * 10점
```

**안전성 점수 최종 계산:**
```
안전성 점수 = 알레르기 점수 + 유해_성분_점수 + 품질_점수

# 알레르기 점수가 0점이면 안전성 점수도 0점 (즉시 제외)
if 알레르기 점수 == 0:
    안전성 점수 = 0
```

### 3.3 적합성 점수 (Fitness Score) - 0~100점

#### 3.3.1 종류 매칭 - 20점 만점
```
종류 점수 = 0점

if 상품.species == None:  # 공용 사료
    종류 점수 = 20점 (공용은 모든 종류에 적합)
elif 상품.species == 펫.species:
    종류 점수 = 20점
else:
    종류 점수 = 0점 (제외)
```

#### 3.3.2 나이 단계 매칭 - 25점 만점

**나이 단계 정보 우선순위:**
1. `parsed.life_stage` 필드 (가장 정확)
2. `product_name` 키워드 매칭 (fallback)

```
나이 점수 = 0점

# parsed.life_stage 우선 체크
if 상품.parsed.life_stage:
    if 상품.parsed.life_stage == "all_life_stages":
        # 전연령 사료는 모든 나이 단계에 적합 (약간 낮은 점수)
        if 펫.age_stage == "PUPPY":
            나이 점수 = 20점
        elif 펫.age_stage == "ADULT":
            나이 점수 = 22점
        elif 펫.age_stage == "SENIOR":
            나이 점수 = 20점
        else:
            나이 점수 = 20점
            
    elif 펫.age_stage == "PUPPY":
        if 상품.parsed.life_stage == "puppy":
            나이 점수 = 25점
        elif 상품.parsed.life_stage == "adult":
            나이 점수 = 15점
        elif 상품.parsed.life_stage == "senior":
            나이 점수 = 0점  # 시니어 사료는 퍼피에게 부적합
            나이 점수 -= 20점 패널티  # 총점에서 추가 감점
            
    elif 펫.age_stage == "ADULT":
        if 상품.parsed.life_stage == "adult":
            나이 점수 = 25점
        elif 상품.parsed.life_stage == "puppy":
            나이 점수 = 10점
        elif 상품.parsed.life_stage == "senior":
            나이 점수 = 20점
        elif 상품.parsed.life_stage == "all_life_stages":
            나이 점수 = 22점
            
    elif 펫.age_stage == "SENIOR":
        if 상품.parsed.life_stage == "senior":
            나이 점수 = 25점
        elif 상품.parsed.life_stage == "adult":
            나이 점수 = 20점
        elif 상품.parsed.life_stage == "puppy":
            나이 점수 = 0점  # 퍼피 사료는 시니어에게 부적합
            나이 점수 -= 15점 패널티  # 총점에서 추가 감점
        elif 상품.parsed.life_stage == "all_life_stages":
            나이 점수 = 20점

# parsed.life_stage가 없으면 product_name 키워드 매칭 (fallback)
else:
    if 펫.age_stage == "PUPPY":
        if "퍼피" in 상품.product_name.lower() or "puppy" in 상품.product_name.lower():
            나이 점수 = 25점
        elif "어덜트" in 상품.product_name.lower() or "adult" in 상품.product_name.lower():
            나이 점수 = 15점
        elif "시니어" in 상품.product_name.lower() or "senior" in 상품.product_name.lower():
            나이 점수 = 0점
            나이 점수 -= 20점 패널티
        else:
            나이 점수 = 15점
            
    elif 펫.age_stage == "ADULT":
        if "어덜트" in 상품.product_name.lower() or "adult" in 상품.product_name.lower():
            나이 점수 = 25점
        elif "퍼피" in 상품.product_name.lower() or "puppy" in 상품.product_name.lower():
            나이 점수 = 10점
        elif "시니어" in 상품.product_name.lower() or "senior" in 상품.product_name.lower():
            나이 점수 = 20점
        else:
            나이 점수 = 20점
            
    elif 펫.age_stage == "SENIOR":
        if "시니어" in 상품.product_name.lower() or "senior" in 상품.product_name.lower():
            나이 점수 = 25점
        elif "어덜트" in 상품.product_name.lower() or "adult" in 상품.product_name.lower():
            나이 점수 = 20점
        elif "퍼피" in 상품.product_name.lower() or "puppy" in 상품.product_name.lower():
            나이 점수 = 0점
            나이 점수 -= 15점 패널티
        else:
            나이 점수 = 15점
```

**변경/추가 내용:** 나이 단계 매칭 현실화 - `parsed.life_stage` 필드 우선 사용, `all_life_stages`는 모든 나이에 20~22점, 부적합한 나이 단계(퍼피→시니어, 시니어→퍼피)는 패널티 적용.

#### 3.3.3 건강 고민 매칭 - 30점 만점

**건강 고민 → Benefits Tags 매핑:**
```python
건강_고민_to_benefits = {
    "OBESITY": "weight_management",
    "SKIN_ALLERGY": "hypoallergenic",
    "JOINT": "joint_support",
    "DIGESTIVE": "digestive",
    "URINARY": "urinary",
    "DIABETES": "weight_management",  # 당뇨도 체중 관리와 연관
    "DENTAL": "dental",
    "SKIN_COAT": "skin_coat",
    "IMMUNE": "immune_support",
}
```

**점수 계산 로직:**
```
건강_고민_점수 = 0점

# 건강 고민별 가중치
건강_고민_가중치 = {
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

for 고민 in 펫.health_concerns:
    if 고민 not in 건강_고민_가중치:
        continue
        
    기본_가중치 = 건강_고민_가중치[고민]
    매칭_점수 = 0
    
    # 1. Benefits Tags 체크 (우선순위 높음, 1.5배 가중치)
    if 상품.parsed.benefits_tags:
        benefits_tag = 건강_고민_to_benefits.get(고민)
        if benefits_tag and benefits_tag in 상품.parsed.benefits_tags:
            매칭_점수 = 기본_가중치 * 1.5  # benefits_tags 매칭 시 1.5배
            건강_고민_점수 += 매칭_점수
            continue  # benefits_tags 매칭되면 키워드 체크 스킵
    
    # 2. 키워드 매칭 (fallback)
    if 건강_고민_키워드_매칭(고민, 상품):
        매칭_점수 = 기본_가중치
        건강_고민_점수 += 매칭_점수

# 최대 30점 제한
건강_고민_점수 = min(건강_고민_점수, 30)
```

**건강 고민 키워드 매칭 함수:**
```python
def 건강_고민_키워드_매칭(고민, 상품):
    키워드_맵 = {
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
    
    키워드들 = 키워드_맵.get(고민, [])
    검색_텍스트 = (
        (상품.parsed.notes or "").lower() + " " +
        " ".join(상품.parsed.ingredients_ordered).lower()
    )
    
    for 키워드 in 키워드들:
        if 키워드 in 검색_텍스트:
            return True
    return False
```

**변경/추가 내용:** 건강 고민 매칭을 `benefits_tags` 중심으로 전환 - benefits_tags 매칭 시 가중치 1.5배 적용, 키워드 매칭은 fallback으로 유지.

#### 3.3.4 품종 특성 매칭 - 15점 만점

**품종 분류 및 요구사항 (간소화된 룰 기반):**
```python
# 품종 그룹 분류
소형견_품종 = ["말티즈", "푸들", "요크셔테리어", "치와와", "포메라니안"]
대형견_품종 = ["골든리트리버", "래브라도리트리버", "하스키", "세인트버나드"]
브라키세팔릭_품종 = ["퍼그", "프렌치불독", "보스턴테리어", "불독"]

품종_특수_요구사항 = {
    # 소형견 그룹
    "소형견": {
        "grain_free": True,      # 소형견은 알레르기 빈도 높음
        "small_breed": True,     # 소형견 전용 사료
        "점수": {"grain_free": 5, "small_breed": 5}
    },
    # 대형견 그룹
    "대형견": {
        "large_breed": True,
        "joint_support": True,   # 대형견은 관절 건강 중요
        "점수": {"large_breed": 5, "joint_support": 5}
    },
    # 브라키세팔릭 그룹
    "브라키세팔릭": {
        "low_calorie": True,     # 호흡기 문제로 비만 위험 높음
        "breathing": True,
        "점수": {"low_calorie": 5, "breathing": 5}
    }
}
```

**점수 계산 로직:**
```
품종_점수 = 10점  # 기본 점수

if 펫.breed_code:
    품종_그룹 = None
    
    # 품종 그룹 판별
    if 펫.breed_code in 소형견_품종:
        품종_그룹 = "소형견"
    elif 펫.breed_code in 대형견_품종:
        품종_그룹 = "대형견"
    elif 펫.breed_code in 브라키세팔릭_품종:
        품종_그룹 = "브라키세팔릭"
    
    if 품종_그룹 and 품종_그룹 in 품종_특수_요구사항:
        요구사항 = 품종_특수_요구사항[품종_그룹]
        
        # 소형견 체크
        if 품종_그룹 == "소형견":
            if 상품.parsed.is_grain_free:
                품종_점수 += 요구사항["점수"]["grain_free"]
            if "소형견" in 상품.product_name or "small" in 상품.product_name.lower():
                품종_점수 += 요구사항["점수"]["small_breed"]
            # benefits_tags 체크
            if 상품.parsed.benefits_tags and "hypoallergenic" in 상품.parsed.benefits_tags:
                품종_점수 += 3  # 추가 보너스
        
        # 대형견 체크
        elif 품종_그룹 == "대형견":
            if "대형견" in 상품.product_name or "large" in 상품.product_name.lower():
                품종_점수 += 요구사항["점수"]["large_breed"]
            if 상품.parsed.benefits_tags and "joint_support" in 상품.parsed.benefits_tags:
                품종_점수 += 요구사항["점수"]["joint_support"]
            elif 건강_고민_키워드_매칭("JOINT", 상품):
                품종_점수 += 요구사항["점수"]["joint_support"] * 0.7  # 키워드 매칭은 낮은 점수
        
        # 브라키세팔릭 체크
        elif 품종_그룹 == "브라키세팔릭":
            if "다이어트" in 상품.product_name or "light" in 상품.product_name.lower():
                품종_점수 += 요구사항["점수"]["low_calorie"]
            if 상품.parsed.benefits_tags and "weight_management" in 상품.parsed.benefits_tags:
                품종_점수 += 요구사항["점수"]["low_calorie"]
            # 호흡기 관련은 키워드로만 체크 (benefits_tags에 없을 수 있음)
            if "breathing" in 상품.product_name.lower() or "호흡" in 상품.product_name:
                품종_점수 += 요구사항["점수"]["breathing"]

# 최대 15점 제한
품종_점수 = min(품종_점수, 15)
```

**변경/추가 내용:** 품종 특성 매칭을 간소화된 룰 기반으로 변경 - 소형견/대형견/브라키세팔릭 3개 그룹으로 분류, 각 그룹별 2~3개 요구사항만 체크하여 구현 복잡도 감소.

#### 3.3.5 영양 적합성 (DER 기반 급여량 적합도) - 20점 만점

**DER (Daily Energy Requirement) 계산:**
```python
def calculate_der(weight_kg, age_stage, is_neutered, species):
    """
    RER (Resting Energy Requirement) = 70 * (weight_kg ** 0.75)
    DER = RER * multiplier
    """
    rer = 70 * (weight_kg ** 0.75)
    
    # Multiplier 설정
    if age_stage == "PUPPY":
        multiplier = 2.5  # 성장기 (평균값)
    elif age_stage == "ADULT":
        if is_neutered:
            multiplier = 1.6
        else:
            multiplier = 1.8
    elif age_stage == "SENIOR":
        multiplier = 1.5  # 평균값
    else:
        multiplier = 1.6  # 기본값
    
    der = rer * multiplier
    return der  # kcal/day
```

**하루 급여량 적합도 점수:**
```
영양_적합성_점수 = 0점

# 1. DER 계산
펫_der = calculate_der(펫.weight_kg, 펫.age_stage, 펫.is_neutered, 펫.species)

# 2. 상품의 kcal_per_kg 가져오기
if 상품.parsed.nutritional_profile and 상품.parsed.nutritional_profile.get("kcal_per_kg"):
    kcal_per_kg = 상품.parsed.nutritional_profile["kcal_per_kg"]
elif 상품.parsed.nutritional_profile and 상품.parsed.nutritional_profile.get("kcal_per_100g"):
    kcal_per_kg = 상품.parsed.nutritional_profile["kcal_per_100g"] * 10
elif 상품.nutrition_facts and 상품.nutrition_facts.kcal_per_100g:
    kcal_per_kg = 상품.nutrition_facts.kcal_per_100g * 10
else:
    # 칼로리 정보가 없으면 기본 점수만 부여
    영양_적합성_점수 = 10점
    goto 중성화_체크

# 3. 하루 급여량 계산 (g/day)
하루_급여량_g = (펫_der / kcal_per_kg) * 1000

# 4. 적합한 급여량 범위 체크
# 일반적으로 체중의 2~4%가 적정 (소형견은 높게, 대형견은 낮게)
if 펫.weight_kg < 10:  # 소형견
    적정_최소 = 펫.weight_kg * 20  # 2% of body weight (g)
    적정_최대 = 펫.weight_kg * 40  # 4% of body weight (g)
elif 펫.weight_kg < 25:  # 중형견
    적정_최소 = 펫.weight_kg * 18
    적정_최대 = 펫.weight_kg * 35
else:  # 대형견
    적정_최소 = 펫.weight_kg * 15
    적정_최대 = 펫.weight_kg * 30

# 5. 점수 계산
if 적정_최소 <= 하루_급여량_g <= 적정_최대:
    영양_적합성_점수 = 20점  # 완벽한 범위
elif 적정_최소 * 0.8 <= 하루_급여량_g <= 적정_최대 * 1.2:
    영양_적합성_점수 = 15점  # 약간 벗어남
elif 적정_최소 * 0.6 <= 하루_급여량_g <= 적정_최대 * 1.4:
    영양_적합성_점수 = 10점  # 많이 벗어남
else:
    영양_적합성_점수 = 5점  # 매우 부적합

중성화_체크:
# 6. 중성화 상태 추가 고려 (중성화 시 칼로리 조절 중요)
if 펫.is_neutered == True:
    if 하루_급여량_g > 적정_최대:
        영양_적합성_점수 -= 3점  # 중성화된데 칼로리가 높으면 추가 감점
    if 상품.parsed.benefits_tags and "weight_management" in 상품.parsed.benefits_tags:
        영양_적합성_점수 += 2점  # 체중 관리 사료면 보너스
```

**변경/추가 내용:** 영양 적합성 섹션 추가 - DER 계산 로직과 하루 급여량 적합도 점수(20점) 추가. 중성화 상태는 영양 적합성 점수 계산에 통합.

**적합성 점수 최종 계산:**
```
적합성 점수 = 종류_점수 + 나이_점수 + 건강_고민_점수 + 품종_점수 + 영양_적합성_점수

# 최대 100점 제한 (각 항목 합계가 100점을 초과할 수 있음)
적합성 점수 = min(적합성_점수, 100)
```

**변경/추가 내용:** 적합성 점수 계산에 영양 적합성 점수 포함, 중성화 점수는 영양 적합성에 통합됨.

### 3.4 최종 점수 계산

```
# 1. 안전성 점수가 0점이면 즉시 제외
if 안전성_점수 == 0:
    총점 = -1 (제외)
    return

# 2. 안전성 Hard-Floor 적용
if 안전성_점수 < 40:
    # 안전성이 낮으면 강하게 페널티
    총점 = (안전성_점수 × 0.3) + (적합성_점수 × 0.1)
else:
    # 정상 가중치
    총점 = (안전성_점수 × 0.6) + (적합성_점수 × 0.4)

# 3. 나이 단계 부적합 패널티 적용 (총점에서 직접 차감)
if 나이_단계_부적합_패널티 > 0:
    총점 -= 나이_단계_부적합_패널티

# 4. 최종 점수는 0 이상으로 제한
총점 = max(총점, 0)
```

**변경/추가 내용:** 최종 점수 계산에 안전성 hard-floor 로직 반영, 나이 단계 부적합 패널티를 총점에서 직접 차감하도록 수정.

---

## 4. 필터링 및 정렬

### 4.1 필터링 조건
```
1. 상품.is_active == True (활성 상품만)
2. 상품.ingredient_profile.parsed IS NOT NULL (parsed JSON이 있는 상품만)
3. 안전성_점수 > 0 (알레르기 등으로 제외된 상품 제외)
4. 종류_점수 > 0 (종류가 맞지 않는 상품 제외)
```

### 4.2 정렬
```
1. 총점 내림차순 (높은 점수 우선)
2. 동점일 경우:
   - 안전성_점수 내림차순
   - 상품.updated_at 내림차순 (최신 상품 우선)
```

### 4.3 상위 N개 선택
```
상위 10개 추천 (또는 설정 가능한 개수)
```

---

## 5. 응답 데이터 구조

### 5.1 RecommendationResponse
```python
{
    "pet_id": UUID,
    "items": [
        {
            "product": {
                "id": UUID,
                "brand_name": str,
                "product_name": str,
                "size_label": str,
                "is_active": bool,
            },
            "offer_merchant": "COUPANG" | "NAVER" | "BRAND",
            "current_price": int,
            "avg_price": int,
            "delta_percent": float | None,
            "is_new_low": bool,
            # 추가 필드 (선택사항)
            "match_score": float,  # 총점
            "safety_score": float,  # 안전성 점수
            "fitness_score": float,  # 적합성 점수
            "match_reasons": List[str],  # 매칭 이유 (예: ["알레르기 안전", "나이 단계 적합"])
        }
    ]
}
```

---

## 6. 구현 위치

### 6.1 백엔드

#### 6.1.1 메인 서비스
```
backend/app/services/product_service.py
  └─ ProductService.get_recommendations()
      ├─ 펫 프로필 조회 (PetService.get_primary_pet_by_device_uid)
      ├─ 상품 필터링 (parsed 있는 것만, is_active=True)
      ├─ 스코링 서비스 호출
      └─ 정렬 및 반환
```

#### 6.1.2 스코링 서비스 (신규)
```
backend/app/services/recommendation_scoring_service.py (신규)
  └─ RecommendationScoringService
      ├─ calculate_safety_score(pet, product, parsed)
      │   ├─ check_allergies()  # 알레르기 체크
      │   ├─ check_harmful_ingredients()  # 유해 성분 체크
      │   └─ calculate_quality_score()  # 품질 지표
      │
      ├─ calculate_fitness_score(pet, product, parsed, nutrition_facts)
      │   ├─ match_species()  # 종류 매칭
      │   ├─ match_age_stage()  # 나이 단계 매칭
      │   ├─ match_health_concerns()  # 건강 고민 매칭
      │   ├─ match_breed()  # 품종 특성 매칭
      │   └─ calculate_nutritional_fitness()  # 영양 적합성 (DER 기반)
      │
      ├─ calculate_total_score(safety_score, fitness_score)
      │   └─ apply_safety_hard_floor()  # 안전성 hard-floor 적용
      │
      └─ Helper Functions
          ├─ calculate_der()  # DER 계산
          ├─ match_health_concern_keywords()  # 키워드 매칭
          └─ get_breed_group()  # 품종 그룹 판별
```

**변경/추가 내용:** 구현 위치 섹션에 스코링 서비스의 세부 함수 구조 추가, DER 계산 및 영양 적합성 함수 포함.

### 6.2 프론트엔드
```
frontend/lib/features/home/presentation/controllers/home_controller.dart
  └─ HomeController.loadRecommendations()
      └─ ProductRepository.getRecommendations(petId)
```

**변경 불필요:** 프론트엔드는 이미 `GET /api/v1/products/recommendations?pet_id={pet_id}` 호출 중

---

## 7. 예외 처리

### 7.1 펫 프로필 없음
```
if 펫 프로필이 없으면:
    return RecommendationResponse(
        pet_id=pet_id,
        items=[],
        error="펫 프로필이 없습니다."
    )
```

### 7.2 추천 가능한 상품 없음
```
if 필터링 후 상품이 0개면:
    return RecommendationResponse(
        pet_id=pet_id,
        items=[],
        message="추천 가능한 상품이 없습니다. parsed JSON이 적재된 상품이 없거나, 모든 상품이 알레르기로 제외되었습니다."
    )
```

---

## 8. 성능 고려사항

### 8.1 쿼리 최적화
```
1. parsed IS NOT NULL 조건으로 인덱스 활용
2. 필요한 관계만 eager load (ingredient_profile, nutrition_facts, allergens, offers)
3. 페이징 적용 (상위 10개만 조회)
```

### 8.2 캐싱 (향후)
```
- 펫 프로필 정보 캐싱 (변경 빈도 낮음)
- 상품 parsed JSON 캐싱 (변경 빈도 낮음)
- 추천 결과 캐싱 (펫 프로필 변경 시 무효화)
```

---

## 9. 확장 가능성

### 9.1 가중치 조정
```
- 안전성/적합성 비율 조정 가능
- 건강 고민별 가중치 조정 가능
- 품종별 특수 요구사항 추가 가능
```

### 9.2 추가 스코링 요소
```
- 가격 대비 품질 점수
- 브랜드 신뢰도 점수
- 사용자 리뷰 점수
- 판매량 인기도 점수
```

---

## 10. 테스트 시나리오

### 10.1 기본 시나리오
```
펫: 강아지, 성견, 알레르기 없음
→ 일반 성견용 사료 추천
```

### 10.2 알레르기 시나리오
```
펫: 강아지, 닭고기 알레르기
→ 닭고기가 포함된 상품 제외, 소고기/양고기 등 추천
```

### 10.3 건강 고민 시나리오
```
펫: 강아지, 비만 건강 고민
→ 저칼로리, 다이어트 사료 우선 추천
```

### 10.4 parsed 없는 상품 시나리오
```
parsed JSON이 없는 상품은 추천 목록에서 제외
```

---

## 11. 구현 우선순위

### Phase 1: 기본 추천 시스템 (MVP)
1. ✅ 펫 프로필 조회
2. ✅ parsed 있는 상품 필터링
3. ✅ 기본 안전성 점수
   - 알레르기 체크 (food_allergies hard exclude)
   - High confidence 알레르겐 penalty
   - Other allergies 텍스트 매칭
4. ✅ 기본 적합성 점수
   - 종류 매칭
   - 나이 단계 매칭 (product_name 키워드 기반)
5. ✅ 안전성 hard-floor 적용
6. ✅ 정렬 및 상위 10개 반환

### Phase 2: 고급 스코링
1. ✅ 영양 적합성 추가
   - DER 계산 로직
   - 하루 급여량 적합도 점수
2. ✅ 건강 고민 매칭
   - benefits_tags 우선 매칭 (1.5배 가중치)
   - 키워드 매칭 fallback
3. ✅ 품종 특성 매칭
   - 소형견/대형견/브라키세팔릭 그룹 분류
   - 간소화된 룰 기반 매칭
4. ✅ 유해 성분 체크
5. ✅ 품질 지표 활용
6. ✅ 나이 단계 매칭 개선
   - parsed.life_stage 필드 우선 사용
   - all_life_stages 처리
   - 부적합 나이 단계 패널티

### Phase 3: 스키마 확장 및 최적화
1. parsed JSON 스키마 확장
   - life_stage 필드 추가
   - benefits_tags 필드 추가
   - nutritional_profile 필드 추가
   - allergen_confidence 필드 추가
2. 성능 최적화
   - 인덱스 최적화 (parsed IS NOT NULL)
   - 필요한 관계만 eager load
   - 추천 결과 캐싱
3. 가중치 조정 기능
   - 안전성/적합성 비율 조정
   - 건강 고민별 가중치 조정
   - 품종별 특수 요구사항 확장

### Phase 4: 추가 스코링 요소 (향후)
1. 가격 대비 품질 점수
2. 브랜드 신뢰도 점수
3. 사용자 리뷰 점수
4. 판매량 인기도 점수

---

## 12. 주의사항

1. **알레르기 체크는 절대 우선**: 
   - `food_allergies`와 `potential_allergens` 겹치면 즉시 제외 (0점)
   - `other_allergies` 텍스트 매칭되면 즉시 제외
   - High confidence 알레르겐은 penalty만 적용 (제외 아님)

2. **parsed JSON 필수**: 
   - `parsed` JSON이 없는 상품은 추천 불가
   - `parsed` JSON의 정확도가 추천 품질에 직접 영향
   - 스키마 확장 필드(`life_stage`, `benefits_tags`, `nutritional_profile`)가 있으면 더 정확한 추천 가능

3. **안전성 Hard-Floor**: 
   - 안전성 점수 < 40이면 총점 계산 시 가중치 크게 감소
   - 안전성 0점 상품은 아예 결과에서 제외

4. **영양 적합성**: 
   - DER 계산은 펫의 나이, 중성화 상태, 체중에 따라 달라짐
   - 칼로리 정보가 없으면 기본 점수만 부여 (10점)

5. **나이 단계 부적합 패널티**: 
   - 퍼피 사료를 시니어에게 주면 -20점 패널티
   - 시니어 사료를 퍼피에게 주면 -15점 패널티
   - 패널티는 총점에서 직접 차감

6. **Benefits Tags 우선순위**: 
   - `benefits_tags` 매칭 시 가중치 1.5배 적용
   - 키워드 매칭은 fallback으로만 사용

7. **품종 특성**: 
   - 현재는 소형견/대형견/브라키세팔릭 3개 그룹만 지원
   - 향후 품종 확장 시 그룹 분류 로직 확장 필요
