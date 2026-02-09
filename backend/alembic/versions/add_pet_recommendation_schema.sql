-- =========================================================
-- 펫 추천 시스템 스키마 마이그레이션
-- =========================================================
-- 이 파일은 직접 SQL로 실행하거나 Alembic 마이그레이션으로 적용할 수 있습니다.
-- 
-- 사용 방법:
-- 1. 직접 실행: psql -U postgres -d petfood -f add_pet_recommendation_schema.sql
-- 2. Alembic: alembic upgrade head
-- =========================================================

-- =========================================================
-- 0) 사전: 확장 함수 (gen_random_uuid 사용 중이면 필요)
-- =========================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- 1) ENUM 추가 (이미 있으면 스킵)
--    - 활동량
--    - 건강상태 코드
--    - 회피/알레르기 레벨
-- =========================================================

DO $$ BEGIN
    CREATE TYPE activitylevel AS ENUM ('LOW', 'MEDIUM', 'HIGH');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    -- 건강 이슈 (필요시 계속 추가)
    CREATE TYPE healthconditioncode AS ENUM (
        'SKIN', 'JOINT', 'GI', 'KIDNEY', 'URINARY', 'DENTAL',
        'DIABETES', 'HEART', 'LIVER', 'OBESITY', 'UNDERWEIGHT'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    -- 회피/알레르기 성격
    CREATE TYPE avoidlevel AS ENUM ('CONFIRMED', 'SUSPECTED', 'PREFERENCE');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    -- 정보 출처
    CREATE TYPE infosource AS ENUM ('OWNER', 'VET', 'TRIAL', 'LAB', 'UNKNOWN');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- =========================================================
-- 2) pets 테이블 보완 (추천 정확도 직결)
--    - activity_level: 활동량
--    - current_product_id: 현재 먹는 사료(비교 기준)
--    - is_neutered: NULL 제거(가능하면)
--    - updated_at 자동 갱신 트리거용 준비
-- =========================================================

ALTER TABLE pets
    ADD COLUMN IF NOT EXISTS activity_level activitylevel NULL,
    ADD COLUMN IF NOT EXISTS current_product_id UUID NULL,            -- products(id) FK는 아래에서 추가
    ADD COLUMN IF NOT EXISTS current_food_started_at DATE NULL,       -- 선택: 언제부터 먹었는지
    ADD COLUMN IF NOT EXISTS note TEXT NULL;                          -- 선택: 메모(특이사항)

-- is_neutered가 NULL 허용이면, 데이터가 이미 있을 수 있으니 안전하게 2단계로
-- 2-1) 기존 NULL을 false로 채움 (원하면 UNKNOWN enum으로 바꿀 수도 있음)
UPDATE pets
SET is_neutered = FALSE
WHERE is_neutered IS NULL;

-- 2-2) NOT NULL + DEFAULT (원치 않으면 주석 처리 가능)
ALTER TABLE pets
    ALTER COLUMN is_neutered SET DEFAULT FALSE;

DO $$ BEGIN
    ALTER TABLE pets
        ALTER COLUMN is_neutered SET NOT NULL;
EXCEPTION
    WHEN others THEN
        -- 만약 데이터/제약 때문에 실패하면, 일단 NOT NULL은 보류
        -- (Cursor에서 실패 로그 보고 조정하면 됨)
        NULL;
END $$;

-- =========================================================
-- 3) 건강 상태 태그 테이블 (정교한 추천 핵심)
-- =========================================================

CREATE TABLE IF NOT EXISTS pet_health_conditions (
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    condition_code healthconditioncode NOT NULL,
    severity SMALLINT NOT NULL DEFAULT 50 CHECK (severity BETWEEN 0 AND 100),
    source infosource NOT NULL DEFAULT 'OWNER',
    note TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (pet_id, condition_code)
);

CREATE INDEX IF NOT EXISTS idx_pet_health_conditions_pet
    ON pet_health_conditions(pet_id);

CREATE INDEX IF NOT EXISTS idx_pet_health_conditions_condition
    ON pet_health_conditions(condition_code);

-- =========================================================
-- 4) 회피/알레르기 성분 테이블
--    - allergen_code는 네가 이미 쓰는 allergen_codes.code를 재사용 권장
-- =========================================================

CREATE TABLE IF NOT EXISTS pet_avoid_allergens (
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    allergen_code VARCHAR(50) NOT NULL,  -- allergen_codes.code에 맞춰 길이 조정
    level avoidlevel NOT NULL DEFAULT 'SUSPECTED',
    confidence SMALLINT NOT NULL DEFAULT 80 CHECK (confidence BETWEEN 0 AND 100),
    source infosource NOT NULL DEFAULT 'OWNER',
    note TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (pet_id, allergen_code)
);

-- allergen_codes 테이블이 있다면 FK 추가 (없으면 주석)
DO $$ BEGIN
    ALTER TABLE pet_avoid_allergens
        ADD CONSTRAINT fk_pet_avoid_allergens_code
        FOREIGN KEY (allergen_code) REFERENCES allergen_codes(code);
EXCEPTION
    WHEN undefined_table THEN NULL;
    WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_pet_avoid_allergens_pet
    ON pet_avoid_allergens(pet_id);

CREATE INDEX IF NOT EXISTS idx_pet_avoid_allergens_code
    ON pet_avoid_allergens(allergen_code);

-- =========================================================
-- 5) (선택) 제품 선호/비선호 테이블 (기호 반영)
--    - 알레르기는 아니지만 "안 먹어요" 같은 데이터
-- =========================================================

DO $$ BEGIN
    CREATE TYPE tastepreference AS ENUM ('LIKE', 'DISLIKE', 'NEUTRAL');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS pet_product_preferences (
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    product_id UUID NOT NULL,  -- products(id)
    preference tastepreference NOT NULL DEFAULT 'NEUTRAL',
    reason TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (pet_id, product_id)
);

-- products 테이블이 있다면 FK 추가 (없으면 주석)
DO $$ BEGIN
    ALTER TABLE pet_product_preferences
        ADD CONSTRAINT fk_pet_product_preferences_product
        FOREIGN KEY (product_id) REFERENCES products(id);
EXCEPTION
    WHEN undefined_table THEN NULL;
    WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_pet_product_preferences_pet
    ON pet_product_preferences(pet_id);

CREATE INDEX IF NOT EXISTS idx_pet_product_preferences_product
    ON pet_product_preferences(product_id);

-- =========================================================
-- 6) pets.current_product_id FK (products 테이블 있을 때)
-- =========================================================

DO $$ BEGIN
    ALTER TABLE pets
        ADD CONSTRAINT fk_pets_current_product
        FOREIGN KEY (current_product_id) REFERENCES products(id);
EXCEPTION
    WHEN undefined_table THEN NULL;
    WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_pets_current_product_id
    ON pets(current_product_id);

CREATE INDEX IF NOT EXISTS idx_pets_species_age_stage
    ON pets(species, age_stage);

-- =========================================================
-- 7) updated_at 자동 갱신 트리거 (pets + 확장 테이블)
-- =========================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- pets
DO $$ BEGIN
    CREATE TRIGGER trg_pets_set_updated_at
    BEFORE UPDATE ON pets
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- pet_health_conditions
DO $$ BEGIN
    CREATE TRIGGER trg_pet_health_conditions_set_updated_at
    BEFORE UPDATE ON pet_health_conditions
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- pet_avoid_allergens
DO $$ BEGIN
    CREATE TRIGGER trg_pet_avoid_allergens_set_updated_at
    BEFORE UPDATE ON pet_avoid_allergens
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- pet_product_preferences
DO $$ BEGIN
    CREATE TRIGGER trg_pet_product_preferences_set_updated_at
    BEFORE UPDATE ON pet_product_preferences
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
