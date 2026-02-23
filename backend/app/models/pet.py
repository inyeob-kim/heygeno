from sqlalchemy import Column, String, Boolean, ForeignKey, Enum as SQLEnum, Index, Numeric, Date, Integer, CheckConstraint, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
import enum

from app.db.base import Base, TimestampMixin


class PetSpecies(str, enum.Enum):
    DOG = "DOG"
    CAT = "CAT"
    BIRD = "BIRD"
    SMALL_MAMMAL = "SMALL_MAMMAL"
    REPTILE = "REPTILE"
    FISH = "FISH"


class WeightUnit(str, enum.Enum):
    KG = "KG"
    LB = "LB"


class PetSex(str, enum.Enum):
    MALE = "MALE"
    FEMALE = "FEMALE"
    UNKNOWN = "UNKNOWN"


class AgeInputMode(str, enum.Enum):
    BIRTHDATE = "BIRTHDATE"
    APPROX = "APPROX"


class AgeStage(str, enum.Enum):
    PUPPY = "PUPPY"
    ADULT = "ADULT"
    SENIOR = "SENIOR"


class Pet(Base, TimestampMixin):
    __tablename__ = "pets"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # 기본 정보
    name = Column(String(100), nullable=False)
    species = Column(SQLEnum(PetSpecies), nullable=False)
    
    # 나이 입력
    age_mode = Column(SQLEnum(AgeInputMode), nullable=False)
    birthdate = Column(Date, nullable=True)  # age_mode == 'BIRTHDATE'일 때
    approx_age_months = Column(Integer, nullable=True)  # age_mode == 'APPROX'일 때 (개월)
    
    # 품종 (강아지 필수, 고양이 선택)
    breed_code = Column(String(50), nullable=True)
    
    # 성별 및 중성화
    sex = Column(SQLEnum(PetSex), nullable=False, server_default='UNKNOWN')
    is_neutered = Column(Boolean, nullable=True)  # 모름이면 null
    
    # 체중 및 체형
    weight_numeric = Column(Numeric(5, 2), nullable=False)  # 무게 숫자
    weight_unit = Column(SQLEnum(WeightUnit), nullable=False, server_default='LB')  # US lb 기본
    body_condition_score = Column(Integer, nullable=False)
    
    # 호환성 프로퍼티: weight_kg (kg 단위로 변환)
    @property
    def weight_kg(self) -> float:
        """weight_numeric을 kg 단위로 변환하여 반환 (호환성 유지)"""
        if self.weight_unit == WeightUnit.KG:
            return float(self.weight_numeric)
        else:  # LB
            return float(self.weight_numeric) / 2.20462
    
    @weight_kg.setter
    def weight_kg(self, value: float):
        """weight_kg 값을 받아서 weight_numeric (lb)로 변환하여 저장"""
        # US 시장 기본이므로 lb로 저장
        self.weight_numeric = value * 2.20462
        self.weight_unit = WeightUnit.LB
    
    # 계산된 필드 (서버에서 계산해서 저장)
    age_stage = Column(SQLEnum(AgeStage), nullable=False)  # puppy/adult/senior
    
    # 사진
    photo_url = Column(String(500), nullable=True)
    
    # 기본 펫 여부
    is_primary = Column(Boolean, default=True, nullable=False)

    __table_args__ = (
        CheckConstraint('body_condition_score BETWEEN 1 AND 9', name='pets_bcs_check'),
        Index('idx_pets_species_breed', 'species', 'breed_code'),
        Index('idx_pets_age_stage', 'age_stage'),
    )

    # Relationships
    user = relationship("User", back_populates="pets")
    trackings = relationship("Tracking", back_populates="pet", cascade="all, delete-orphan")
    health_concerns = relationship("PetHealthConcern", back_populates="pet", cascade="all, delete-orphan")
    food_allergies = relationship("PetFoodAllergy", back_populates="pet", cascade="all, delete-orphan")
    other_allergies = relationship("PetOtherAllergy", back_populates="pet", cascade="all, delete-orphan", uselist=False)
    current_foods = relationship("PetCurrentFood", back_populates="pet", cascade="all, delete-orphan")


# 건강 고민 코드 테이블
class HealthConcernCode(Base):
    __tablename__ = "health_concern_codes"
    
    code = Column(String(30), primary_key=True)
    display_name = Column(String(50), nullable=False)
    display_name_en = Column(String(50), nullable=False)  # 영어 추가


# 펫-건강고민 (멀티선택)
class PetHealthConcern(Base):
    __tablename__ = "pet_health_concerns"
    
    pet_id = Column(UUID(as_uuid=True), ForeignKey("pets.id", ondelete="CASCADE"), primary_key=True)
    concern_code = Column(String(30), ForeignKey("health_concern_codes.code"), primary_key=True)
    
    # Relationships
    pet = relationship("Pet", back_populates="health_concerns")
    concern = relationship("HealthConcernCode")


# 알레르겐 코드 테이블
class AllergenCode(Base):
    __tablename__ = "allergen_codes"
    
    code = Column(String(30), primary_key=True)
    display_name = Column(String(50), nullable=False)
    display_name_en = Column(String(50), nullable=False)  # 영어 추가


# 펫-알레르겐 (멀티선택)
class PetFoodAllergy(Base):
    __tablename__ = "pet_food_allergies"
    
    pet_id = Column(UUID(as_uuid=True), ForeignKey("pets.id", ondelete="CASCADE"), primary_key=True)
    allergen_code = Column(String(30), ForeignKey("allergen_codes.code"), primary_key=True)
    
    # Relationships
    pet = relationship("Pet", back_populates="food_allergies")
    allergen = relationship("AllergenCode")


# 펫 기타 알레르기 (텍스트)
class PetOtherAllergy(Base, TimestampMixin):
    __tablename__ = "pet_other_allergies"
    
    pet_id = Column(UUID(as_uuid=True), ForeignKey("pets.id", ondelete="CASCADE"), primary_key=True)
    other_text = Column(Text, nullable=False)
    
    # Relationships
    pet = relationship("Pet", back_populates="other_allergies")