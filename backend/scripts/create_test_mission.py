"""
미션 테스트 데이터 생성 스크립트
특정 provider_user_id로 미션 생성
"""
import asyncio
import sys
from pathlib import Path
from datetime import datetime, timezone, timedelta

# 프로젝트 루트를 Python path에 추가
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy import select
from app.models.user import User
from app.models.campaign import (
    Campaign, CampaignAction, CampaignKind, CampaignTrigger, CampaignActionType
)
from app.core.config import settings


async def create_or_get_user(
    session: AsyncSession,
    provider_user_id: str,
    nickname: str = "테스트 사용자"
) -> User:
    """사용자 생성 또는 조회"""
    user_result = await session.execute(
        select(User).where(
            User.provider == 'DEVICE',
            User.provider_user_id == provider_user_id
        )
    )
    user = user_result.scalar_one_or_none()
    
    if user:
        print(f"✅ 기존 사용자 찾음: {user.nickname} (id: {user.id})")
        return user
    
    # 새 사용자 생성
    user = User(
        provider='DEVICE',
        provider_user_id=provider_user_id,
        nickname=nickname
    )
    session.add(user)
    await session.flush()
    await session.refresh(user)
    print(f"✅ 새 사용자 생성: {user.nickname} (id: {user.id})")
    return user


async def create_test_mission(
    session: AsyncSession,
    provider_user_id: str,
    mission_title: str = "오늘 추천 사료 찜하기",
    mission_description: str = "홈에서 추천된 사료를 찜 목록에 추가하세요",
    target_value: int = 1,
    reward_points: int = 50,
    trigger: CampaignTrigger = CampaignTrigger.TRACKING_CREATED,
    progress_increment: int = 1,
    auto_claim: bool = False
):
    """테스트 미션 생성"""
    
    # 1. 사용자 생성 또는 조회
    user = await create_or_get_user(session, provider_user_id, "테스트 사용자")
    
    # 2. 캠페인 생성
    now = datetime.now(timezone.utc)
    import uuid
    unique_suffix = str(uuid.uuid4())[:8]  # 고유한 8자리 문자열
    campaign_key = f"test_mission_{provider_user_id[:8]}_{unique_suffix}"
    
    campaign = Campaign(
        key=campaign_key,
        kind=CampaignKind.MISSION,
        placement="BENEFITS_PAGE",  # 혜택 페이지에 표시
        template="mission_card",
        priority=100,
        is_enabled=True,
        start_at=now - timedelta(days=1),  # 어제부터 시작
        end_at=now + timedelta(days=30),  # 30일 후까지
        content={
            "title": mission_title,
            "description": mission_description,
            "target_value": target_value,
            "reward_points": reward_points,
        }
    )
    
    session.add(campaign)
    await session.flush()  # campaign.id를 얻기 위해
    print(f"✅ 캠페인 생성: {campaign.key} (id: {campaign.id})")
    
    # 3. CampaignAction 생성 (UPDATE_PROGRESS)
    action = CampaignAction(
        campaign_id=campaign.id,
        trigger=trigger.value,
        action_type=CampaignActionType.UPDATE_PROGRESS.value,
        action={
            "progress_increment": progress_increment,
            "auto_claim": auto_claim
        }
    )
    
    session.add(action)
    await session.flush()
    print(f"✅ 액션 생성: trigger={trigger.value}, action_type={action.action_type}")
    
    await session.commit()
    
    print(f"\n🎉 미션 생성 완료!")
    print(f"   캠페인 ID: {campaign.id}")
    print(f"   제목: {mission_title}")
    print(f"   목표: {target_value}")
    print(f"   보상: {reward_points}P")
    print(f"   트리거: {trigger.value}")
    
    return campaign


async def main():
    """메인 함수"""
    provider_user_id = "63d73fba-0bbb-4872-9b65-b2f2b59f1e59"
    
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
            # 예시 미션 1: 추적 생성 미션
            await create_test_mission(
                session=session,
                provider_user_id=provider_user_id,
                mission_title="오늘 추천 사료 찜하기",
                mission_description="홈에서 추천된 사료를 찜 목록에 추가하세요",
                target_value=1,
                reward_points=50,
                trigger=CampaignTrigger.TRACKING_CREATED,
                progress_increment=1,
                auto_claim=False
            )
            
            # 예시 미션 2: 알림 생성 미션
            await create_test_mission(
                session=session,
                provider_user_id=provider_user_id,
                mission_title="알림 설정하기",
                mission_description="사료 급여 알림을 설정하세요",
                target_value=1,
                reward_points=30,
                trigger=CampaignTrigger.ALERT_CREATED,
                progress_increment=1,
                auto_claim=False
            )
            
            # 예시 미션 3: 첫 추적 생성 미션 (즉시 보상)
            await create_test_mission(
                session=session,
                provider_user_id=provider_user_id,
                mission_title="첫 추적 기록하기",
                mission_description="첫 번째 사료 급여 기록을 남겨보세요",
                target_value=1,
                reward_points=100,
                trigger=CampaignTrigger.FIRST_TRACKING_CREATED,
                progress_increment=1,
                auto_claim=True  # 자동 지급
            )
            
        except Exception as e:
            await session.rollback()
            print(f"❌ 에러 발생: {e}")
            raise
        finally:
            await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
