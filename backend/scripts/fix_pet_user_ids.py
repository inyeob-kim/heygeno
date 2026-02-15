"""
잘못 저장된 pet.user_id 수정 스크립트
provider_user_id가 저장된 경우 올바른 users.id로 업데이트
"""
import asyncio
import sys
from pathlib import Path

# 프로젝트 루트를 Python path에 추가
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy import select, text
from app.models.user import User
from app.models.pet import Pet
from app.core.config import settings


async def fix_pet_user_ids(session: AsyncSession):
    """잘못 저장된 pet.user_id 수정"""
    
    # 1. 모든 pet 조회
    result = await session.execute(select(Pet))
    pets = result.scalars().all()
    
    print(f"총 {len(pets)}개의 pet 발견")
    
    fixed_count = 0
    error_count = 0
    
    for pet in pets:
        try:
            # 2. pet.user_id가 UUID 형식인지 확인
            user_id_str = str(pet.user_id)
            
            # UUID 형식이 아니거나 provider_user_id처럼 보이는 경우
            # (예: 하이픈이 4개가 아니거나, 길이가 다름)
            if len(user_id_str) != 36 or user_id_str.count('-') != 4:
                print(f"\n⚠️  Pet {pet.id}의 user_id가 이상함: {user_id_str}")
                
                # provider_user_id로 사용자를 찾기 시도
                user_result = await session.execute(
                    select(User).where(User.provider_user_id == user_id_str)
                )
                user = user_result.scalar_one_or_none()
                
                if user:
                    print(f"   ✅ 사용자 찾음: {user.nickname} (id: {user.id})")
                    # 올바른 user_id로 업데이트
                    pet.user_id = user.id
                    fixed_count += 1
                    print(f"   ✅ Pet {pet.id}의 user_id를 {user.id}로 수정")
                else:
                    print(f"   ❌ provider_user_id={user_id_str}로 사용자를 찾을 수 없음")
                    error_count += 1
            else:
                # UUID 형식이 맞는 경우, 실제로 users 테이블에 존재하는지 확인
                user_result = await session.execute(
                    select(User).where(User.id == pet.user_id)
                )
                user = user_result.scalar_one_or_none()
                
                if not user:
                    print(f"\n⚠️  Pet {pet.id}의 user_id={pet.user_id}가 users 테이블에 없음")
                    # provider_user_id로 찾기 시도
                    user_result2 = await session.execute(
                        select(User).where(User.provider_user_id == str(pet.user_id))
                    )
                    user2 = user_result2.scalar_one_or_none()
                    
                    if user2:
                        print(f"   ✅ provider_user_id로 사용자 찾음: {user2.nickname} (id: {user2.id})")
                        pet.user_id = user2.id
                        fixed_count += 1
                        print(f"   ✅ Pet {pet.id}의 user_id를 {user2.id}로 수정")
                    else:
                        print(f"   ❌ 사용자를 찾을 수 없음")
                        error_count += 1
        
        except Exception as e:
            print(f"\n❌ Pet {pet.id} 처리 중 에러: {e}")
            error_count += 1
    
    await session.commit()
    
    print(f"\n📊 수정 완료:")
    print(f"   ✅ 수정된 pet: {fixed_count}개")
    print(f"   ❌ 에러: {error_count}개")
    print(f"   ℹ️  총 pet: {len(pets)}개")


async def main():
    """메인 함수"""
    # 데이터베이스 연결
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=False,
    )
    
    async_session_maker = async_sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with async_session_maker() as session:
        try:
            await fix_pet_user_ids(session)
        except Exception as e:
            await session.rollback()
            print(f"❌ 에러 발생: {e}")
            raise
        finally:
            await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
