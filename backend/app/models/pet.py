from sqlalchemy import Column, String, Boolean, ForeignKey, Enum as SQLEnum, Index, Numeric, Date, Integer, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
import enum

from app.db.base import Base, TimestampMixin


class PetSpecies(str, enum.Enum):
    DOG = "DOG"
    CAT = "CAT"


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
    weight_kg = Column(Numeric(5, 2), nullable=False)
    body_condition_score = Column(Integer, nullable=False)
    
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


# 건강 고민 코드 테이블
class HealthConcernCode(Base):
    __tablename__ = "health_concern_codes"
    
    code = Column(String(30), primary_key=True)
    display_name = Column(String(50), nullable=False)


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


# 펫-알레르겐 (멀티선택)
class PetFoodAllergy(Base):
    __tablename__ = "pet_food_allergies"
    
    pet_id = Column(UUID(as_uuid=True), ForeignKey("pets.id", ondelete="CASCADE"), primary_key=True)
    allergen_code = Column(String(30), ForeignKey("allergen_codes.code"), primary_key=True)
    
    # Relationships
    pet = relationship("Pet", back_populates="food_allergies")
    allergen = relationship("AllergenCode")