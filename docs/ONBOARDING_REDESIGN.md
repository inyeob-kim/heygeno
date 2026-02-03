# 🚀 HeyZeno 온보딩 리디자인: 6~7단계 MVP 설계

**출시 직전 MVP 설계 리뷰 - 정규화 DB + 짧고 재밌는 UX + 서버 업서트**

---

## 📋 목차

1. [최종 6~7단계 온보딩 플로우](#1-최종-67단계-온보딩-플로우)
2. [정규화 DB DDL 전체](#2-정규화-db-ddl-전체)
3. [API 명세 (Pydantic 포함)](#3-api-명세-pydantic-포함)
4. [completeOnboarding 업서트 순서 + 트랜잭션 코드](#4-completeonboarding-업서트-순서--트랜잭션-코드)
5. [과설계 방지 체크리스트](#5-과설계-방지-체크리스트)

---

## 1. 최종 6~7단계 온보딩 플로우

### 플로우 다이어그램

```
[앱 시작]
    ↓
Step A (5~8초): 이름 + 종
    ├─ 닉네임 (2~12자)
    ├─ 아이 이름 (1~20자)
    └─ 종 선택 (강아지/고양이) 🐶🐱
    ↓
Step B (8~12초): 나이 + 품종(강아지만)
    ├─ 나이 모드 토글 (기본: "대략")
    ├─ 대략 나이 입력 (연령/개월 스테퍼)
    └─ [강아지만] 품종 선택 (펼치기) 🐕
    ↓
Step C (5~8초): 성별 + 중성화
    ├─ 성별 (남/여) ♂️♀️
    └─ 중성화 (예/아니오/모름) ✂️
    ↓
Step D (10~15초): 몸무게 + 체형
    ├─ 몸무게 슬라이더 (0.1~99.9kg) ⚖️
    └─ BCS 슬라이더 (1~9) 🧡
    ↓
Step E (8~12초): 건강 + 알레르기
    ├─ 건강 고민 (기본: "없어요" 선택) 🩺
    └─ 음식 알레르기 (기본: "없어요" 선택) 🍗
    ↓
Step F (5~10초): 사진 (선택)
    ├─ 사진 선택/촬영 📸
    └─ "건너뛰기" 버튼 (눈에 띄게)
    ↓
[헤이제노 시작하기]
    ↓
[서버 업서트 트랜잭션]
    ↓
[메인 홈]
```

**총 예상 소요 시간: 41~65초** (기본값 활용 시 최소 클릭)

---

### Step A: 이름 + 종 (5~8초)

**보이는 질문**: "안녕하세요! 😊 우리 아이 이름은 뭐예요?"

**수집 필드**:
- `nickname`: String (2~12자)
- `petName`: String (1~20자)
- `species`: String ('dog' | 'cat')

**UI 레이아웃**:
```
[상단]
  이모지: 😊 (80px)
  타이틀: "안녕하세요! 😊"
  서브타이틀: "우리 아이 이름은 뭐예요?"

[중앙]
  ┌─────────────────────┐
  │ 닉네임 입력          │
  │ (플레이스홀더: "헤이제노에서 쓸 닉네임") │
  │ [🎲 추천받기] 버튼   │
  └─────────────────────┘
  
  ┌─────────────────────┐
  │ 아이 이름 입력      │
  │ (플레이스홀더: "우리 아이 이름") │
  └─────────────────────┘

  [종 선택]
  ┌──────────┐  ┌──────────┐
  │  🐶      │  │  🐱      │
  │ 강아지   │  │ 고양이   │
  └──────────┘  └──────────┘

[하단]
  [다음] 버튼 (disabled: nickname<2 || petName.isEmpty || species==null)
```

**기본값**:
- 닉네임: 없음 (입력 필수)
- 아이 이름: 없음 (입력 필수)
- 종: 없음 (선택 필수)

**재밌는 장치**:
- 닉네임 입력 시 실시간 글자 수 표시 + 이모지 반응 (2자 이상 시 ✨)
- 종 선택 시 선택된 카드에 하트 애니메이션 💚
- "추천받기" 버튼 클릭 시 랜덤 닉네임 생성 + 축하 애니메이션 🎉

**검증**:
- 닉네임: 2~12자
- 아이 이름: 1~20자
- 종: 필수 선택

---

### Step B: 나이 + 품종 (8~12초)

**보이는 질문**: "나이는 어떻게 알려주실래요? 🎂"

**수집 필드**:
- `ageMode`: String ('APPROX' | 'BIRTHDATE') - 기본: 'APPROX'
- `approxAgeMonths`: int? (ageMode == 'APPROX'일 때)
- `birthdate`: Date? (ageMode == 'BIRTHDATE'일 때)
- `breedCode`: String? (강아지만, 펼치기)

**UI 레이아웃**:
```
[상단]
  이모지: 🎂 (80px)
  타이틀: "나이는 어떻게 알려주실래요? 🎂"

[중앙]
  [모드 토글] (기본: "대략적인 나이만")
  ┌─────────────────────┐
  │ 🎈 대략적인 나이만  │ ← 기본 선택
  └─────────────────────┘
  ┌─────────────────────┐
  │ 📅 생년월일 알아요  │
  └─────────────────────┘

  [조건부 컨텐츠]
  if (ageMode == 'APPROX'):
    ┌─────────────────────┐
    │ 연령: [0]살         │
    │ 개월: [0]개월       │
    │ [+][-] 스테퍼       │
    └─────────────────────┘
  else:
    ┌─────────────────────┐
    │ [CupertinoDatePicker]│
    └─────────────────────┘

  [강아지일 때만 - 펼치기]
  ┌─────────────────────┐
  │ [▼] 품종 선택        │ ← 클릭 시 펼침
  └─────────────────────┘
    (펼침 시)
    [검색 바]
    [인기 품종 칩들]
    [전체 품종 목록]
    [믹스/잘 모르겠어요]

[하단]
  [다음] 버튼
```

**기본값**:
- `ageMode`: 'APPROX'
- `approxAgeMonths`: 12 (1살)
- `breedCode`: null (강아지일 때만 필수, 펼치기로 숨김)

**재밌는 장치**:
- 나이 입력 시 실시간으로 "X살 X개월" 표시 + 이모지 반응 (어린이면 🍼, 성견이면 🐕)
- 품종 펼치기 시 부드러운 슬라이드 애니메이션
- 품종 선택 시 해당 품종 이모지 표시 (예: 골든리트리버 → 🦮)

**검증**:
- `ageMode == 'APPROX'` → `approxAgeMonths` 필수 (0~240개월)
- `ageMode == 'BIRTHDATE'` → `birthdate` 필수
- 강아지일 때 → `breedCode` 필수 (펼치기에서 선택)

---

### Step C: 성별 + 중성화 (5~8초)

**보이는 질문**: "성별과 중성화 정보를 알려주세요 ✨"

**수집 필드**:
- `sex`: String ('MALE' | 'FEMALE')
- `isNeutered`: Boolean? (null = 모름)

**UI 레이아웃**:
```
[상단]
  이모지: ✨ (80px)
  타이틀: "성별과 중성화 정보를 알려주세요 ✨"

[중앙]
  [성별 섹션]
  ┌──────────┐  ┌──────────┐
  │   ♂️     │  │   ♀️     │
  │  남아    │  │  여아    │
  └──────────┘  └──────────┘

  [중성화 섹션]
  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │  했어요  │  │ 안 했어요│  │ 잘 모르겠어요│
  └──────────┘  └──────────┘  └──────────┘

[하단]
  [다음] 버튼
```

**기본값**:
- `sex`: 없음 (필수 선택)
- `isNeutered`: null (모름, 기본 선택)

**재밌는 장치**:
- 성별 선택 시 선택된 카드에 별 애니메이션 ⭐
- 중성화 "모름" 선택 시 "괜찮아요! 나중에 수정할 수 있어요" 메시지 표시

**검증**:
- `sex`: 필수
- `isNeutered`: 선택 (null 허용)

---

### Step D: 몸무게 + 체형 (10~15초)

**보이는 질문**: "몸무게와 체형을 알려주세요 ⚖️"

**수집 필드**:
- `weightKg`: double (0.1~99.9)
- `bodyConditionScore`: int (1~9)

**UI 레이아웃**:
```
[상단]
  이모지: ⚖️ (80px)
  타이틀: "몸무게와 체형을 알려주세요 ⚖️"

[중앙]
  [몸무게 섹션]
  ┌─────────────────────┐
  │    [3.5]kg          │ ← 큰 숫자 표시
  │  [슬라이더]         │
  │  [빠른 조절: -0.1 +0.1] │
  └─────────────────────┘

  [체형 섹션]
  ┌─────────────────────┐
  │  [캐릭터 실루엣]    │ ← BCS에 따라 변화
  │  [슬라이더: 1~9]    │
  │  마른 편 ← → 통통한 편│
  │  [피드백 텍스트]     │
  └─────────────────────┘

[하단]
  [다음] 버튼
```

**기본값**:
- `weightKg`: 종/나이 기반 추정값 (소형견 3kg, 중형견 10kg, 고양이 4kg)
- `bodyConditionScore`: 5 (중간값)

**재밌는 장치**:
- 몸무게 변경 시 숫자 스케일 애니메이션
- BCS 슬라이더 변경 시 캐릭터 실루엣 부드럽게 변화
- 첫 BCS 선택 시 하트 팝업 애니메이션 💚
- BCS 4~6 구간 선택 시 "딱 좋아요! 💚" 메시지 + 축하 애니메이션

**검증**:
- `weightKg`: 0.1~99.9
- `bodyConditionScore`: 1~9

---

### Step E: 건강 + 알레르기 (8~12초)

**보이는 질문**: "건강 고민이나 알레르기가 있나요? 🩺"

**수집 필드**:
- `healthConcerns`: String[] (코드 배열, 기본: [])
- `foodAllergies`: String[] (코드 배열, 기본: [])
- `otherAllergyText`: String? (선택)

**UI 레이아웃**:
```
[상단]
  이모지: 🩺 (80px)
  타이틀: "건강 고민이나 알레르기가 있나요? 🩺"

[중앙]
  [건강 고민 섹션]
  ┌─────────────────────┐
  │ [✓] 없어요          │ ← 기본 선택됨
  │ [ ] 알레르기        │
  │ [ ] 장/소화         │
  │ [ ] 치아/구강       │
  │ [ ] 비만            │
  │ [ ] 호흡기          │
  │ [ ] 피부/털         │
  │ [ ] 관절            │
  │ [ ] 눈/눈물         │
  │ [ ] 신장/요로       │
  │ [ ] 심장            │
  │ [ ] 노령            │
  └─────────────────────┘

  [음식 알레르기 섹션]
  ┌─────────────────────┐
  │ [✓] 없어요          │ ← 기본 선택됨
  │ [ ] 소고기           │
  │ [ ] 닭고기           │
  │ [ ] 돼지고기         │
  │ [ ] 생선             │
  │ [ ] 계란             │
  │ [ ] 유제품           │
  │ [ ] 밀/글루텐        │
  │ [ ] 옥수수           │
  │ [ ] 콩               │
  │ [ ] 기타             │ ← 선택 시 텍스트 필드 표시
  └─────────────────────┘

[하단]
  [다음] 버튼 (항상 활성화, 기본값으로 통과 가능)
```

**기본값**:
- `healthConcerns`: [] (빈 배열 = "없어요")
- `foodAllergies`: [] (빈 배열 = "없어요")
- `otherAllergyText`: null

**재밌는 장치**:
- "없어요" 기본 선택 상태로 표시 (체크박스 체크됨)
- 다른 항목 선택 시 "없어요" 자동 해제 + 부드러운 애니메이션
- "없어요" 다시 선택 시 다른 항목 모두 해제
- 항목 선택 시 해당 이모지 표시 (예: 알레르기 → 🤧)

**검증**:
- `healthConcerns`: 배열 (빈 배열 허용 = "없어요")
- `foodAllergies`: 배열 (빈 배열 허용 = "없어요")
- "기타" 선택 시 `otherAllergyText` 입력 가능

---

### Step F: 사진 (5~10초)

**보이는 질문**: "아이 사진을 올려볼까요? 📸"

**수집 필드**:
- `photoUrl`: String? (선택)

**UI 레이아웃**:
```
[상단]
  이모지: 📸 (80px)
  타이틀: "아이 사진을 올려볼까요? 📸"
  서브타이틀: "나중에 해도 괜찮아요"

[중앙]
  ┌─────────────────────┐
  │                     │
  │   [사진 미리보기]   │ ← 200x200 원형
  │   또는              │
  │   📷 플레이스홀더   │
  │                     │
  └─────────────────────┘

  [액션 버튼]
  [사진 선택] [사진 찍기]

[하단]
  ┌─────────────────────┐
  │ [건너뛰기] 버튼     │ ← 눈에 띄게 (큰 버튼)
  └─────────────────────┘
  
  ┌─────────────────────┐
  │ [헤이제노 시작하기] │ ← Primary 버튼
  └─────────────────────┘
```

**기본값**:
- `photoUrl`: null (선택 사항)

**재밌는 장치**:
- 사진 선택 시 원형 프레임에 부드러운 페이드인 애니메이션
- "건너뛰기" 버튼 클릭 시 "나중에 올려도 괜찮아요! 😊" 메시지
- "헤이제노 시작하기" 버튼 클릭 시 축하 애니메이션 + 하트 이펙트 💚

**검증**:
- `photoUrl`: 선택 사항 (null 허용)

---

## 2. 정규화 DB DDL 전체

### 2-1) ENUM 정의

```sql
-- Auth Provider
CREATE TYPE auth_provider AS ENUM ('DEVICE');

-- Pet Species
CREATE TYPE pet_species AS ENUM ('DOG', 'CAT');

-- Pet Sex
CREATE TYPE pet_sex AS ENUM ('MALE', 'FEMALE', 'UNKNOWN');

-- Age Input Mode
CREATE TYPE age_input_mode AS ENUM ('BIRTHDATE', 'APPROX');

-- Age Stage (서버 계산)
CREATE TYPE age_stage AS ENUM ('PUPPY', 'ADULT', 'SENIOR');
```

### 2-2) users 테이블

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider auth_provider NOT NULL DEFAULT 'DEVICE',
    provider_user_id VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) NOT NULL,
    timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Seoul',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT uq_user_provider UNIQUE (provider, provider_user_id)
);

CREATE INDEX idx_users_provider_user_id ON users(provider, provider_user_id);
CREATE INDEX idx_users_nickname ON users(nickname);
```

### 2-3) pets 테이블

```sql
CREATE TABLE pets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 기본 정보
    name VARCHAR(100) NOT NULL,
    species pet_species NOT NULL,
    
    -- 나이 입력
    age_mode age_input_mode NOT NULL,
    birthdate DATE NULL,  -- age_mode = 'BIRTHDATE'일 때
    approx_age_months INTEGER NULL,  -- age_mode = 'APPROX'일 때 (개월)
    
    -- 품종 (강아지 필수, 고양이 선택)
    breed_code VARCHAR(50) NULL,
    
    -- 성별 및 중성화
    sex pet_sex NOT NULL DEFAULT 'UNKNOWN',
    is_neutered BOOLEAN NULL,  -- null = 모름
    
    -- 체중 및 체형
    weight_kg NUMERIC(5, 2) NOT NULL,
    body_condition_score INTEGER NOT NULL CHECK (body_condition_score BETWEEN 1 AND 9),
    
    -- 계산된 필드 (서버에서 계산해서 저장)
    age_stage age_stage NOT NULL,
    
    -- 사진
    photo_url VARCHAR(500) NULL,
    
    -- 기본 펫 여부
    is_primary BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pets_user_id ON pets(user_id);
CREATE INDEX idx_pets_species_breed ON pets(species, breed_code);
CREATE INDEX idx_pets_age_stage ON pets(age_stage);
```

### 2-4) 정규화 코드 테이블

```sql
-- 건강 고민 코드
CREATE TABLE health_concern_codes (
    code VARCHAR(30) PRIMARY KEY,
    display_name VARCHAR(50) NOT NULL
);

-- 펫-건강고민 매핑 (멀티선택)
CREATE TABLE pet_health_concerns (
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    concern_code VARCHAR(30) NOT NULL REFERENCES health_concern_codes(code),
    
    PRIMARY KEY (pet_id, concern_code)
);

CREATE INDEX idx_pet_health_concerns_concern ON pet_health_concerns(concern_code);

-- 알레르겐 코드
CREATE TABLE allergen_codes (
    code VARCHAR(30) PRIMARY KEY,
    display_name VARCHAR(50) NOT NULL
);

-- 펫-알레르겐 매핑 (멀티선택)
CREATE TABLE pet_food_allergies (
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    allergen_code VARCHAR(30) NOT NULL REFERENCES allergen_codes(code),
    
    PRIMARY KEY (pet_id, allergen_code)
);

CREATE INDEX idx_pet_food_allergies_allergen ON pet_food_allergies(allergen_code);

-- 펫 기타 알레르기 (텍스트)
CREATE TABLE pet_other_allergies (
    pet_id UUID PRIMARY KEY REFERENCES pets(id) ON DELETE CASCADE,
    other_text TEXT NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

### 2-5) 초기 데이터 (코드 테이블)

```sql
-- 건강 고민 코드 초기 데이터
INSERT INTO health_concern_codes (code, display_name) VALUES
('ALLERGY', '알레르기'),
('DIGESTIVE', '장/소화'),
('DENTAL', '치아/구강'),
('OBESITY', '비만'),
('RESPIRATORY', '호흡기'),
('SKIN', '피부/털'),
('JOINT', '관절'),
('EYE', '눈/눈물'),
('KIDNEY', '신장/요로'),
('HEART', '심장'),
('SENIOR', '노령');

-- 알레르겐 코드 초기 데이터
INSERT INTO allergen_codes (code, display_name) VALUES
('BEEF', '소고기'),
('CHICKEN', '닭고기'),
('PORK', '돼지고기'),
('DUCK', '오리고기'),
('LAMB', '양고기'),
('FISH', '생선'),
('EGG', '계란'),
('DAIRY', '유제품'),
('WHEAT', '밀/글루텐'),
('CORN', '옥수수'),
('SOY', '콩');
```

### 2-6) 기존 테이블 연동 (trackings, alerts 등)

```sql
-- trackings 테이블 (기존 유지)
CREATE TABLE trackings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT uq_tracking_user_product UNIQUE (user_id, product_id)
);

CREATE INDEX idx_trackings_user_pet ON trackings(user_id, pet_id);
CREATE INDEX idx_trackings_product ON trackings(product_id);

-- alerts 테이블 (기존 유지, final_price 사용)
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    target_price NUMERIC(10, 2) NOT NULL,  -- final_price 기준
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_user_product ON alerts(user_id, product_id);
CREATE INDEX idx_alerts_active ON alerts(is_active);
```

### 2-7) Alembic 마이그레이션 팁

**ENUM 생성 순서**:
1. ENUM 타입 먼저 생성 (auth_provider, pet_species, pet_sex, age_input_mode, age_stage)
2. 외래키가 없는 테이블부터 (users, health_concern_codes, allergen_codes)
3. 외래키가 있는 테이블 순서대로 (pets, pet_health_concerns, pet_food_allergies, pet_other_allergies)
4. 초기 데이터 삽입 (health_concern_codes, allergen_codes)

**충돌 방지**:
- 기존 ENUM이 있으면 `ALTER TYPE ... ADD VALUE` 사용
- 기존 테이블이 있으면 `ALTER TABLE` 사용
- autogenerate 시 `compare_type=True` 옵션 확인

---

## 3. API 명세 (Pydantic 포함)

### 3-1) 엔드포인트

```
POST /v1/onboarding/complete
```

### 3-2) Request Schema

```python
from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import date
from uuid import UUID

class AutoTrackConfig(BaseModel):
    enable: bool = False
    product_ids: Optional[List[UUID]] = None

class OnboardingCompleteRequest(BaseModel):
    device_uid: str = Field(..., min_length=1, description="Device UID (UUID v4)")
    nickname: str = Field(..., min_length=2, max_length=12, description="사용자 닉네임")
    
    # Pet 정보
    pet_name: str = Field(..., min_length=1, max_length=20)
    species: str = Field(..., regex="^(DOG|CAT)$")
    
    # 나이
    age_mode: str = Field(..., regex="^(BIRTHDATE|APPROX)$")
    birthdate: Optional[date] = None
    approx_age_months: Optional[int] = Field(None, ge=0, le=240)
    
    # 품종 (강아지 필수)
    breed_code: Optional[str] = None
    
    # 성별 및 중성화
    sex: str = Field(..., regex="^(MALE|FEMALE)$")
    is_neutered: Optional[bool] = None  # null = 모름
    
    # 체중 및 체형
    weight_kg: float = Field(..., ge=0.1, le=99.9)
    body_condition_score: int = Field(..., ge=1, le=9)
    
    # 건강 및 알레르기
    health_concerns: List[str] = Field(default_factory=list)  # 코드 배열, 빈 배열 = "없어요"
    food_allergies: List[str] = Field(default_factory=list)  # 코드 배열, 빈 배열 = "없어요"
    other_allergy_text: Optional[str] = Field(None, max_length=200)
    
    # 사진
    photo_url: Optional[str] = None
    
    # 자동 추적 설정 (선택)
    auto_track: Optional[AutoTrackConfig] = None
    
    @validator('birthdate', 'approx_age_months')
    def validate_age_fields(cls, v, values):
        age_mode = values.get('age_mode')
        if age_mode == 'BIRTHDATE' and not values.get('birthdate'):
            raise ValueError('birthdate is required when age_mode is BIRTHDATE')
        if age_mode == 'APPROX' and not values.get('approx_age_months'):
            raise ValueError('approx_age_months is required when age_mode is APPROX')
        return v
    
    @validator('breed_code')
    def validate_breed(cls, v, values):
        if values.get('species') == 'DOG' and not v:
            raise ValueError('breed_code is required for DOG')
        return v
```

### 3-3) Response Schema

```python
class OnboardingCompleteResponse(BaseModel):
    success: bool
    user_id: UUID
    pet_id: UUID
    message: str = "온보딩이 완료되었습니다."
```

---

## 4. completeOnboarding 업서트 순서 + 트랜잭션 코드

### 4-1) 트랜잭션 순서

```
1. BEGIN TRANSACTION
2. users UPSERT (ON CONFLICT DO UPDATE)
3. pets CREATE/UPDATE (primary pet 정책)
4. pet_health_concerns: DELETE 기존 → BULK INSERT
5. pet_food_allergies: DELETE 기존 → BULK INSERT
6. pet_other_allergies: UPSERT (텍스트 있을 때만)
7. (선택) trackings 생성
8. (선택) 기본 alerts 생성
9. COMMIT
```

### 4-2) SQLAlchemy 트랜잭션 코드

```python
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.models.user import User, AuthProvider
from app.models.pet import Pet, PetSpecies, AgeInputMode, AgeStage, PetSex
from app.models.pet import PetHealthConcern, PetFoodAllergy, PetOtherAllergy
from app.models.tracking import Tracking
from app.models.alert import Alert
from datetime import date, datetime
from typing import Optional, List
import uuid

def calculate_age_stage(age_months: Optional[int], birthdate: Optional[date]) -> AgeStage:
    """나이 단계 계산 (PUPPY/ADULT/SENIOR)"""
    if age_months is not None:
        months = age_months
    elif birthdate:
        today = date.today()
        months = (today.year - birthdate.year) * 12 + (today.month - birthdate.month)
    else:
        return AgeStage.ADULT  # 기본값
    
    if months < 12:
        return AgeStage.PUPPY
    elif months < 84:  # 7년
        return AgeStage.ADULT
    else:
        return AgeStage.SENIOR

def complete_onboarding(
    db: Session,
    request: OnboardingCompleteRequest
) -> OnboardingCompleteResponse:
    """
    온보딩 완료 트랜잭션
    """
    try:
        # 1. Users UPSERT
        user = db.query(User).filter(
            User.provider == AuthProvider.DEVICE,
            User.provider_user_id == request.device_uid
        ).first()
        
        if user:
            user.nickname = request.nickname
            user.updated_at = datetime.utcnow()
        else:
            user = User(
                provider=AuthProvider.DEVICE,
                provider_user_id=request.device_uid,
                nickname=request.nickname,
                timezone='Asia/Seoul'
            )
            db.add(user)
        
        db.flush()  # user.id를 얻기 위해
        
        # 2. Pets CREATE/UPDATE (primary pet 정책)
        # 기존 primary pet이 있으면 업데이트, 없으면 생성
        pet = db.query(Pet).filter(
            Pet.user_id == user.id,
            Pet.is_primary == True
        ).first()
        
        age_stage = calculate_age_stage(
            request.approx_age_months,
            request.birthdate
        )
        
        if pet:
            # 업데이트
            pet.name = request.pet_name
            pet.species = PetSpecies[request.species]
            pet.age_mode = AgeInputMode[request.age_mode]
            pet.birthdate = request.birthdate
            pet.approx_age_months = request.approx_age_months
            pet.breed_code = request.breed_code
            pet.sex = PetSex[request.sex]
            pet.is_neutered = request.is_neutered
            pet.weight_kg = request.weight_kg
            pet.body_condition_score = request.body_condition_score
            pet.age_stage = age_stage
            pet.photo_url = request.photo_url
            pet.updated_at = datetime.utcnow()
        else:
            # 생성
            pet = Pet(
                user_id=user.id,
                name=request.pet_name,
                species=PetSpecies[request.species],
                age_mode=AgeInputMode[request.age_mode],
                birthdate=request.birthdate,
                approx_age_months=request.approx_age_months,
                breed_code=request.breed_code,
                sex=PetSex[request.sex],
                is_neutered=request.is_neutered,
                weight_kg=request.weight_kg,
                body_condition_score=request.body_condition_score,
                age_stage=age_stage,
                photo_url=request.photo_url,
                is_primary=True
            )
            db.add(pet)
        
        db.flush()  # pet.id를 얻기 위해
        
        # 3. pet_health_concerns: DELETE 기존 → BULK INSERT
        db.query(PetHealthConcern).filter(
            PetHealthConcern.pet_id == pet.id
        ).delete()
        
        if request.health_concerns:  # 빈 배열이 아니면
            health_concerns = [
                PetHealthConcern(
                    pet_id=pet.id,
                    concern_code=code
                )
                for code in request.health_concerns
            ]
            db.bulk_save_objects(health_concerns)
        
        # 4. pet_food_allergies: DELETE 기존 → BULK INSERT
        db.query(PetFoodAllergy).filter(
            PetFoodAllergy.pet_id == pet.id
        ).delete()
        
        if request.food_allergies:  # 빈 배열이 아니면
            food_allergies = [
                PetFoodAllergy(
                    pet_id=pet.id,
                    allergen_code=code
                )
                for code in request.food_allergies
            ]
            db.bulk_save_objects(food_allergies)
        
        # 5. pet_other_allergies: UPSERT
        if request.other_allergy_text:
            other_allergy = db.query(PetOtherAllergy).filter(
                PetOtherAllergy.pet_id == pet.id
            ).first()
            
            if other_allergy:
                other_allergy.other_text = request.other_allergy_text
                other_allergy.updated_at = datetime.utcnow()
            else:
                other_allergy = PetOtherAllergy(
                    pet_id=pet.id,
                    other_text=request.other_allergy_text
                )
                db.add(other_allergy)
        else:
            # 텍스트가 없으면 삭제
            db.query(PetOtherAllergy).filter(
                PetOtherAllergy.pet_id == pet.id
            ).delete()
        
        # 6. (선택) trackings 생성
        if request.auto_track and request.auto_track.enable:
            if request.auto_track.product_ids:
                for product_id in request.auto_track.product_ids:
                    # 중복 체크
                    existing = db.query(Tracking).filter(
                        Tracking.user_id == user.id,
                        Tracking.product_id == product_id
                    ).first()
                    
                    if not existing:
                        tracking = Tracking(
                            user_id=user.id,
                            pet_id=pet.id,
                            product_id=product_id
                        )
                        db.add(tracking)
        
        # 7. COMMIT
        db.commit()
        
        return OnboardingCompleteResponse(
            success=True,
            user_id=user.id,
            pet_id=pet.id
        )
        
    except Exception as e:
        db.rollback()
        raise e
```

### 4-3) FastAPI 엔드포인트

```python
from fastapi import APIRouter, Depends, HTTPException
from app.db.session import get_db
from app.schemas.onboarding import OnboardingCompleteRequest, OnboardingCompleteResponse
from app.services.onboarding_service import complete_onboarding

router = APIRouter()

@router.post("/complete", response_model=OnboardingCompleteResponse)
async def complete_onboarding_endpoint(
    request: OnboardingCompleteRequest,
    db: Session = Depends(get_db)
):
    """
    온보딩 완료 API
    - 트랜잭션으로 한번에 저장
    - 실패 시 롤백
    """
    try:
        return complete_onboarding(db, request)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="온보딩 완료 중 오류가 발생했습니다.")
```

---

## 5. 과설계 방지 체크리스트

### 🚫 지금은 하지 말 것

1. **다중 펫 지원**
   - 현재: `is_primary=True` 하나만
   - 이유: MVP는 단일 펫만 지원, 나중에 확장

2. **품종 자동완성/검색 최적화**
   - 현재: 간단한 검색 바 + 인기 품종
   - 이유: 초기에는 하드코딩 목록으로 충분

3. **사진 서버 업로드**
   - 현재: 로컬 경로만 저장
   - 이유: MVP는 로컬 저장, 나중에 S3/Cloud Storage 연동

4. **온보딩 중단 복귀 최적화**
   - 현재: SecureStorage에 draft 저장
   - 이유: 기본 기능만, 복잡한 상태 관리 불필요

5. **추천 시스템 연동**
   - 현재: 온보딩 완료 시 추천 생성 안 함
   - 이유: 별도 API로 처리, 온보딩과 분리

### ✅ 지금 해야 할 것

1. ✅ 6~7단계 플로우 구현
2. ✅ 기본값 활용 (최소 클릭)
3. ✅ 정규화 DB 스키마
4. ✅ 트랜잭션 업서트
5. ✅ 기본 검증 및 에러 처리

---

**Made with ❤️ for HeyZeno MVP**
