"""
이벤트 시스템 테스트 스크립트
- 테스트 사용자 생성
- 테스트 캠페인 생성 (첫 추적 시 1000P 지급)
- 첫 추적 생성하여 트리거 발생
- 결과 확인
"""
import asyncio
import sys
from pathlib import Path
from datetime import datetime, timedelta
from uuid import UUID

# 프로젝트 루트를 Python path에 추가
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy import select, func

from app.core.config import settings
from app.models.user import User
from app.models.pet import Pet, PetSpecies, PetSex, AgeInputMode, AgeStage
from app.models.product import Product
from app.models.tracking import Tracking, TrackingStatus
from app.models.campaign import (
    Campaign, CampaignAction, CampaignKind, CampaignPlacement,
    CampaignTemplate, CampaignTrigger, CampaignActionType,
    UserCampaignReward, UserMissionProgress
)
from app.models.point import PointWallet, PointLedger
from app.services.mission_service import MissionService
from app.services.tracking_service import TrackingService
from app.services.user_service import UserService
from app.schemas.tracking import TrackingCreate


# 테스트용 고정 UUID (재현 가능한 테스트를 위해)
TEST_USER_ID = UUID("11111111-1111-1111-1111-111111111111")
TEST_PET_ID = UUID("22222222-2222-2222-2222-222222222222")
TEST_PRODUCT_ID = UUID("33333333-3333-3333-3333-333333333333")
TEST_CAMPAIGN_ID = UUID("44444444-4444-4444-4444-444444444444")
TEST_DEVICE_UID = "test-device-uid-event-system"


async def setup_test_data(db: AsyncSession):
    """테스트 데이터 생성"""
    print("\n=== 테스트 데이터 생성 시작 ===")
    
    # 1. 테스트 사용자 생성
    print("\n1. 테스트 사용자 생성 중...")
    user_result = await db.execute(
        select(User).where(User.id == TEST_USER_ID)
    )
    user = user_result.scalar_one_or_none()
    
    if not user:
        user = User(
            id=TEST_USER_ID,
            provider="DEVICE",
            provider_user_id=TEST_DEVICE_UID,
            nickname="테스트 사용자",
            timezone="Asia/Seoul"
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        print(f"   ✓ 사용자 생성 완료: {user.id} ({user.nickname})")
    else:
        print(f"   ✓ 사용자 이미 존재: {user.id} ({user.nickname})")
    
    # 2. 테스트 펫 생성
    print("\n2. 테스트 펫 생성 중...")
    pet_result = await db.execute(
        select(Pet).where(Pet.id == TEST_PET_ID)
    )
    pet = pet_result.scalar_one_or_none()
    
    if not pet:
        pet = Pet(
            id=TEST_PET_ID,
            user_id=TEST_USER_ID,
            name="테스트 강아지",
            species=PetSpecies.DOG,
            sex=PetSex.MALE,
            age_mode=AgeInputMode.APPROX,
            approx_age_months=24,
            age_stage=AgeStage.ADULT,
            weight_kg=10.0,
            body_condition_score=5,
            is_neutered=True
        )
        db.add(pet)
        await db.commit()
        await db.refresh(pet)
        print(f"   ✓ 펫 생성 완료: {pet.id} ({pet.name})")
    else:
        print(f"   ✓ 펫 이미 존재: {pet.id} ({pet.name})")
    
    # 3. 테스트 상품 확인 (없으면 생성)
    print("\n3. 테스트 상품 확인 중...")
    product_result = await db.execute(
        select(Product).where(Product.id == TEST_PRODUCT_ID)
    )
    product = product_result.scalar_one_or_none()
    
    if not product:
        product = Product(
            id=TEST_PRODUCT_ID,
            category="FOOD",
            brand_name="테스트 브랜드",
            product_name="테스트 사료",
            is_active=True
        )
        db.add(product)
        await db.commit()
        await db.refresh(product)
        print(f"   ✓ 상품 생성 완료: {product.id} ({product.product_name})")
    else:
        print(f"   ✓ 상품 이미 존재: {product.id} ({product.product_name})")
    
    # 4. 테스트 캠페인 생성
    print("\n4. 테스트 캠페인 생성 중...")
    campaign_result = await db.execute(
        select(Campaign).where(Campaign.id == TEST_CAMPAIGN_ID)
    )
    campaign = campaign_result.scalar_one_or_none()
    
    if not campaign:
        now = datetime.utcnow()
        campaign = Campaign(
            id=TEST_CAMPAIGN_ID,
            key="test_first_tracking_1000p",
            kind=CampaignKind.EVENT,
            placement=CampaignPlacement.HOME_MODAL,
            template=CampaignTemplate.IMAGE_TOP,
            priority=10,
            is_enabled=True,
            start_at=now - timedelta(days=1),
            end_at=now + timedelta(days=30),
            content={
                "title": "첫 추적 시작하고 1000P 받기!",
                "description": "첫 번째 상품 추적을 시작하면 1000P를 드립니다",
                "image_url": "https://example.com/event.jpg",
                "reward_points": 1000
            }
        )
        db.add(campaign)
        await db.flush()  # ID 생성
        
        # 캠페인 액션 생성
        action = CampaignAction(
            campaign_id=TEST_CAMPAIGN_ID,
            trigger=CampaignTrigger.FIRST_TRACKING_CREATED.value,
            action_type=CampaignActionType.GRANT_POINTS.value,
            action={"points": 1000}
        )
        db.add(action)
        await db.commit()
        await db.refresh(campaign)
        print(f"   ✓ 캠페인 생성 완료: {campaign.id} ({campaign.key})")
        print(f"   ✓ 액션 생성 완료: trigger={action.trigger}, action_type={action.action_type}")
    else:
        print(f"   ✓ 캠페인 이미 존재: {campaign.id} ({campaign.key})")
    
    print("\n=== 테스트 데이터 생성 완료 ===\n")
    return user, pet, product, campaign


async def check_initial_state(db: AsyncSession):
    """초기 상태 확인"""
    print("\n=== 초기 상태 확인 ===")
    
    # 포인트 잔액 확인
    wallet_result = await db.execute(
        select(PointWallet).where(PointWallet.user_id == TEST_USER_ID)
    )
    wallet = wallet_result.scalar_one_or_none()
    initial_balance = wallet.balance if wallet else 0
    print(f"초기 포인트 잔액: {initial_balance}P")
    
    # 기존 추적 개수 확인
    tracking_count_result = await db.execute(
        select(func.count(Tracking.id))
        .where(Tracking.user_id == TEST_USER_ID)
    )
    tracking_count = tracking_count_result.scalar()
    print(f"기존 추적 개수: {tracking_count}개")
    
    # 기존 보상 기록 확인
    reward_result = await db.execute(
        select(UserCampaignReward).where(
            UserCampaignReward.user_id == TEST_USER_ID,
            UserCampaignReward.campaign_id == TEST_CAMPAIGN_ID
        )
    )
    existing_reward = reward_result.scalar_one_or_none()
    if existing_reward:
        print(f"⚠️  이미 보상이 지급되어 있습니다: {existing_reward.granted_at}")
        return False
    
    return True


async def test_first_tracking(db: AsyncSession, pet: Pet, product: Product):
    """첫 추적 생성 테스트"""
    print("\n=== 첫 추적 생성 테스트 ===")
    
    # 기존 추적 삭제 (깨끗한 테스트를 위해)
    print("\n1. 기존 추적 삭제 중...")
    existing_trackings_result = await db.execute(
        select(Tracking).where(
            Tracking.user_id == TEST_USER_ID,
            Tracking.status != TrackingStatus.DELETED
        )
    )
    existing_trackings = existing_trackings_result.scalars().all()
    for tracking in existing_trackings:
        tracking.status = TrackingStatus.DELETED
    await db.commit()
    print(f"   ✓ {len(existing_trackings)}개 추적 삭제 완료")
    
    # 첫 추적 생성
    print("\n2. 첫 추적 생성 중...")
    tracking_data = TrackingCreate(
        pet_id=TEST_PET_ID,
        product_id=TEST_PRODUCT_ID
    )
    
    try:
        tracking = await TrackingService.create_tracking(
            user_id=TEST_USER_ID,
            tracking_data=tracking_data,
            db=db
        )
        print(f"   ✓ 추적 생성 완료: {tracking.id}")
        print(f"   ✓ 상태: {tracking.status}")
    except Exception as e:
        print(f"   ✗ 추적 생성 실패: {str(e)}")
        raise
    
    return tracking


async def verify_results(db: AsyncSession):
    """결과 검증"""
    print("\n=== 결과 검증 ===")
    
    # 1. 포인트 지급 확인
    print("\n1. 포인트 지급 확인...")
    wallet_result = await db.execute(
        select(PointWallet).where(PointWallet.user_id == TEST_USER_ID)
    )
    wallet = wallet_result.scalar_one_or_none()
    
    if wallet:
        print(f"   ✓ 포인트 잔액: {wallet.balance}P")
        if wallet.balance >= 1000:
            print(f"   ✓ 포인트 지급 성공! (+{wallet.balance}P)")
        else:
            print(f"   ⚠️  포인트가 예상보다 적습니다: {wallet.balance}P (예상: 1000P)")
    else:
        print(f"   ✗ 포인트 지갑이 없습니다")
    
    # 2. 포인트 장부 확인
    print("\n2. 포인트 장부 확인...")
    ledger_result = await db.execute(
        select(PointLedger)
        .where(PointLedger.user_id == TEST_USER_ID)
        .order_by(PointLedger.created_at.desc())
        .limit(5)
    )
    ledgers = ledger_result.scalars().all()
    
    if ledgers:
        print(f"   ✓ 최근 장부 기록 {len(ledgers)}개:")
        for ledger in ledgers[:3]:
            print(f"      - {ledger.delta:+d}P | {ledger.reason} | {ledger.created_at}")
    else:
        print(f"   ⚠️  장부 기록이 없습니다")
    
    # 3. 보상 기록 확인
    print("\n3. 보상 기록 확인...")
    reward_result = await db.execute(
        select(UserCampaignReward).where(
            UserCampaignReward.user_id == TEST_USER_ID,
            UserCampaignReward.campaign_id == TEST_CAMPAIGN_ID
        )
    )
    reward = reward_result.scalar_one_or_none()
    
    if reward:
        print(f"   ✓ 보상 기록 존재: {reward.id}")
        print(f"   ✓ 상태: {reward.status}")
        print(f"   ✓ 지급 시간: {reward.granted_at}")
    else:
        print(f"   ✗ 보상 기록이 없습니다!")
    
    # 4. 중복 지급 방지 테스트
    print("\n4. 중복 지급 방지 테스트...")
    print("   (같은 트리거를 다시 발생시켜도 보상이 중복 지급되지 않아야 함)")
    
    # 보상 기록 개수 확인 (현재)
    reward_result_before = await db.execute(
        select(UserCampaignReward).where(
            UserCampaignReward.user_id == TEST_USER_ID,
            UserCampaignReward.campaign_id == TEST_CAMPAIGN_ID
        )
    )
    reward_count_before = reward_result_before.scalars().count()
    print(f"   현재 보상 기록 개수: {reward_count_before}개")
    
    # 포인트 잔액 확인 (현재)
    wallet_before_result = await db.execute(
        select(PointWallet).where(PointWallet.user_id == TEST_USER_ID)
    )
    wallet_before = wallet_before_result.scalar_one_or_none()
    balance_before = wallet_before.balance if wallet_before else 0
    print(f"   현재 포인트 잔액: {balance_before}P")
    
    # 트리거를 직접 다시 발생시켜보기 (중복 지급 방지 테스트)
    print("\n   트리거를 다시 발생시킴...")
    try:
        from app.models.campaign import CampaignTrigger
        await MissionService.update_progress(
            db, TEST_USER_ID, CampaignTrigger.FIRST_TRACKING_CREATED
        )
        print("   ✓ 트리거 처리 완료")
        
        # 보상 기록 재확인
        reward_result_after = await db.execute(
            select(UserCampaignReward).where(
                UserCampaignReward.user_id == TEST_USER_ID,
                UserCampaignReward.campaign_id == TEST_CAMPAIGN_ID
            )
        )
        reward_count_after = reward_result_after.scalars().count()
        
        # 포인트 잔액 재확인
        wallet_after_result = await db.execute(
            select(PointWallet).where(PointWallet.user_id == TEST_USER_ID)
        )
        wallet_after = wallet_after_result.scalar_one_or_none()
        balance_after = wallet_after.balance if wallet_after else 0
        
        print(f"   이후 보상 기록 개수: {reward_count_after}개")
        print(f"   이후 포인트 잔액: {balance_after}P")
        
        if reward_count_after == reward_count_before and balance_after == balance_before:
            print(f"   ✓ 중복 지급 방지 성공! (보상 기록: {reward_count_before} → {reward_count_after}, 포인트: {balance_before}P → {balance_after}P)")
        else:
            print(f"   ✗ 중복 지급 발생! (보상 기록: {reward_count_before} → {reward_count_after}, 포인트: {balance_before}P → {balance_after}P)")
    except Exception as e:
        print(f"   ⚠️  트리거 재발생 중 오류: {str(e)}")
    
    print("\n=== 결과 검증 완료 ===\n")


async def main():
    """메인 실행 함수"""
    print("=" * 60)
    print("이벤트 시스템 테스트 시작")
    print("=" * 60)
    
    # DB 연결
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=False
    )
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        try:
            # 테스트 데이터 생성
            user, pet, product, campaign = await setup_test_data(db)
            
            # 초기 상태 확인
            if not await check_initial_state(db):
                print("\n⚠️  이미 보상이 지급되어 있어 테스트를 건너뜁니다.")
                print("   테스트를 다시 실행하려면 DB에서 보상 기록을 삭제하세요.")
                return
            
            # 첫 추적 생성 테스트
            tracking = await test_first_tracking(db, pet, product)
            
            # 결과 검증
            await verify_results(db)
            
            print("=" * 60)
            print("✅ 테스트 완료!")
            print("=" * 60)
            
        except Exception as e:
            print(f"\n❌ 테스트 실패: {str(e)}")
            import traceback
            traceback.print_exc()
            await db.rollback()
        finally:
            await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
