# 이벤트 시스템 동작 예시 - 단계별 상세 설명

## 시나리오: "첫 추적 시작하고 1000P 받기" 이벤트

---

## Step 1: 관리자가 이벤트 생성 (관리자 페이지)

### 1.1 관리자가 입력한 정보

**화면에서 입력**:
- 제목: "첫 추적 시작하고 1000P 받기!"
- 설명: "첫 번째 상품 추적을 시작하면 1000P를 드립니다"
- 보상: 1000P
- 기간: 2024-01-15 ~ 2024-01-31
- 트리거: 첫 추적 생성 시

### 1.2 API 호출

```http
POST /api/v1/admin/campaigns
Content-Type: application/json

{
  "key": "first_tracking_1000p",
  "kind": "EVENT",
  "placement": "HOME_MODAL",
  "template": "image_top",
  "priority": 10,
  "is_enabled": true,
  "start_at": "2024-01-15T00:00:00Z",
  "end_at": "2024-01-31T23:59:59Z",
  "content": {
    "title": "첫 추적 시작하고 1000P 받기!",
    "description": "첫 번째 상품 추적을 시작하면 1000P를 드립니다",
    "image_url": "https://example.com/event.jpg",
    "reward_points": 1000
  },
  "rules": [],
  "actions": [
    {
      "trigger": "FIRST_TRACKING_CREATED",
      "action_type": "GRANT_POINTS",
      "action": {
        "points": 1000
      }
    }
  ]
}
```

### 1.3 백엔드 처리 (`CampaignService.create_campaign`)

**실행되는 코드**:
```python
# 1. Campaign 테이블에 저장
campaign = Campaign(
    id=UUID("a1b2c3d4-e5f6-7890-abcd-ef1234567890"),  # 자동 생성
    key="first_tracking_1000p",
    kind="EVENT",
    placement="HOME_MODAL",
    template="image_top",
    priority=10,
    is_enabled=True,
    start_at=datetime(2024, 1, 15, 0, 0, 0),
    end_at=datetime(2024, 1, 31, 23, 59, 59),
    content={
        "title": "첫 추적 시작하고 1000P 받기!",
        "description": "...",
        "reward_points": 1000
    }
)
db.add(campaign)
await db.flush()  # ID 생성됨

# 2. CampaignAction 테이블에 저장
action = CampaignAction(
    id=UUID("b2c3d4e5-f6a7-8901-bcde-f12345678901"),  # 자동 생성
    campaign_id=UUID("a1b2c3d4-e5f6-7890-abcd-ef1234567890"),
    trigger="FIRST_TRACKING_CREATED",
    action_type="GRANT_POINTS",
    action={"points": 1000}  # JSONB로 저장
)
db.add(action)

await db.commit()
```

### 1.4 DB에 저장된 데이터

**`campaigns` 테이블**:
```
id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
key: first_tracking_1000p
kind: EVENT
is_enabled: true
start_at: 2024-01-15 00:00:00
end_at: 2024-01-31 23:59:59
content: {"title": "첫 추적 시작하고 1000P 받기!", ...}
```

**`campaign_actions` 테이블**:
```
id: b2c3d4e5-f6a7-8901-bcde-f12345678901
campaign_id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
trigger: FIRST_TRACKING_CREATED
action_type: GRANT_POINTS
action: {"points": 1000}
```

**결과**: 이벤트가 DB에 저장되었지만, 아직 아무도 보상을 받지 않음

---

## Step 2: 사용자가 첫 추적 생성 (앱에서)

### 2.1 사용자 행동

**사용자 A (user_id: `user-123`)가 앱에서**:
1. 상품 상세 페이지 진입
2. "가격 추적 시작" 버튼 클릭

### 2.2 API 호출

```http
POST /api/v1/trackings
Content-Type: application/json
X-Device-UID: device-abc-123

{
  "pet_id": "pet-456",
  "product_id": "product-789"
}
```

### 2.3 백엔드 처리 (`TrackingService.create_tracking`)

**실행되는 코드**:
```python
# 1. 추적 생성
tracking = Tracking(
    id=UUID("tracking-001"),
    user_id=UUID("user-123"),
    pet_id=UUID("pet-456"),
    product_id=UUID("product-789"),
    status=TrackingStatus.ACTIVE
)
db.add(tracking)
await db.commit()

# 2. 첫 추적인지 확인
count_result = await db.execute(
    select(func.count(Tracking.id))
    .where(Tracking.user_id == UUID("user-123"))
)
tracking_count = count_result.scalar()  # 결과: 1 (첫 추적!)

if tracking_count == 1:
    # 첫 추적이므로 이벤트 트리거 발생!
    await MissionService.update_progress(
        db, 
        user_id=UUID("user-123"), 
        trigger=CampaignTrigger.FIRST_TRACKING_CREATED
    )
```

**중요**: 여기서 `FIRST_TRACKING_CREATED` 트리거가 발생합니다!

---

## Step 3: 이벤트 처리 (`MissionService.update_progress`)

### 3.1 활성 캠페인 조회

**실행되는 쿼리**:
```sql
SELECT campaigns.*, campaign_actions.*
FROM campaigns
JOIN campaign_actions ON campaigns.id = campaign_actions.campaign_id
WHERE 
    campaigns.kind = 'EVENT'
    AND campaigns.is_enabled = true
    AND campaign_actions.trigger = 'FIRST_TRACKING_CREATED'
    AND NOW() BETWEEN campaigns.start_at AND campaigns.end_at
ORDER BY campaigns.priority ASC
```

**조회 결과**:
```
campaign_id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
campaign_key: first_tracking_1000p
action_id: b2c3d4e5-f6a7-8901-bcde-f12345678901
trigger: FIRST_TRACKING_CREATED
action_type: GRANT_POINTS
action: {"points": 1000}
```

**발견된 캠페인**: `first_tracking_1000p` 이벤트 발견!

### 3.2 규칙 평가

**현재 코드**:
```python
if campaign.rules:
    # TODO: 규칙 평가 로직 구현
    pass  # 현재는 항상 통과
```

**결과**: 규칙 없음 → 통과 ✅

### 3.3 액션 실행

**코드 실행**:
```python
# 매칭되는 액션 찾기
matching_actions = [
    a for a in campaign.actions 
    if a.trigger == "FIRST_TRACKING_CREATED"
    and a.action_type == "GRANT_POINTS"  # 또는 "UPDATE_PROGRESS"
]

# 이 경우: action_type이 "GRANT_POINTS"이므로
# MissionService.update_progress()에서는 처리하지 않음
# (현재는 "UPDATE_PROGRESS"만 처리함)
```

**문제 발견**: 현재 `MissionService.update_progress()`는 `UPDATE_PROGRESS` 액션만 처리합니다!
`GRANT_POINTS` 액션은 별도 처리 로직이 필요합니다.

---

## Step 4: 보상 지급 처리 (현재 미구현 부분)

### 4.1 현재 코드의 문제점

**`MissionService.update_progress()`는**:
- `action_type == "UPDATE_PROGRESS"`만 처리
- `action_type == "GRANT_POINTS"`는 처리하지 않음

**필요한 처리**:
```python
if action.action_type == "GRANT_POINTS":
    # 중복 지급 방지 체크
    existing_reward = await db.execute(
        select(UserCampaignReward).where(
            UserCampaignReward.user_id == user_id,
            UserCampaignReward.campaign_id == campaign.id,
            UserCampaignReward.action_id == action.id
        )
    )
    
    if existing_reward.scalar_one_or_none():
        # 이미 지급됨 → 스킵
        continue
    
    # 포인트 지급
    points = action.action.get("points", 0)
    await PointService.grant_points(
        db=db,
        user_id=user_id,
        points=points,
        reason=f"campaign:{campaign.key}",
        ref_type="campaign_reward",
        ref_id=campaign.id
    )
    
    # 보상 기록
    reward = UserCampaignReward(
        user_id=user_id,
        campaign_id=campaign.id,
        action_id=action.id,
        status="GRANTED",
        granted_at=datetime.utcnow()
    )
    db.add(reward)
    await db.commit()
```

### 4.2 보상 지급 후 DB 상태

**`point_wallets` 테이블**:
```
user_id: user-123
balance: 1000  (0 → 1000으로 증가)
```

**`point_ledgers` 테이블**:
```
id: ledger-001
user_id: user-123
delta: +1000
reason: campaign:first_tracking_1000p
ref_type: campaign_reward
ref_id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
created_at: 2024-01-20 10:30:00
```

**`user_campaign_rewards` 테이블**:
```
id: reward-001
user_id: user-123
campaign_id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
action_id: b2c3d4e5-f6a7-8901-bcde-f12345678901
status: GRANTED
granted_at: 2024-01-20 10:30:00
```

---

## Step 5: 중복 지급 방지 (같은 사용자가 다시 시도)

### 5.1 사용자 A가 또 다른 추적 생성

**시나리오**: 사용자 A가 두 번째 추적을 생성하려고 시도

**코드 실행**:
```python
# 첫 추적인지 확인
count = await db.execute(
    select(func.count(Tracking.id))
    .where(Tracking.user_id == UUID("user-123"))
)
# 결과: 2 (이미 추적이 있음)

if count == 1:  # False → 실행 안 됨
    await MissionService.update_progress(...)
```

**결과**: `FIRST_TRACKING_CREATED` 트리거가 발생하지 않음 ✅

### 5.2 만약 트리거가 발생했다면?

**중복 지급 방지 체크**:
```python
existing_reward = await db.execute(
    select(UserCampaignReward).where(
        UserCampaignReward.user_id == UUID("user-123"),
        UserCampaignReward.campaign_id == UUID("a1b2c3d4-..."),
        UserCampaignReward.action_id == UUID("b2c3d4e5-...")
    )
)
# 결과: reward-001 발견됨

if existing_reward.scalar_one_or_none():
    # 이미 지급됨 → 스킵
    return  # 보상 지급 안 함
```

**결과**: 중복 지급 방지 ✅

---

## 전체 흐름 요약

```
[관리자 페이지]
    ↓
POST /api/v1/admin/campaigns
    ↓
CampaignService.create_campaign()
    ↓
DB 저장:
  - campaigns 테이블
  - campaign_actions 테이블
    ↓
[이벤트 활성화 완료]

                    ⬇️ (시간 경과)

[사용자 앱]
    ↓
"가격 추적 시작" 버튼 클릭
    ↓
POST /api/v1/trackings
    ↓
TrackingService.create_tracking()
    ↓
1. 추적 생성 (DB 저장)
2. 첫 추적인지 확인 (count == 1)
    ↓
MissionService.update_progress(
    trigger=FIRST_TRACKING_CREATED
)
    ↓
1. 활성 캠페인 조회
   (trigger = FIRST_TRACKING_CREATED)
    ↓
2. "first_tracking_1000p" 캠페인 발견
    ↓
3. 규칙 평가 (통과)
    ↓
4. 액션 실행
   - action_type: GRANT_POINTS
   - action: {"points": 1000}
    ↓
5. 중복 지급 방지 체크
   (UserCampaignReward 테이블 확인)
    ↓
6. 포인트 지급
   PointService.grant_points(1000)
    ↓
7. 보상 기록
   UserCampaignReward 저장
    ↓
[사용자 포인트 지갑: 1000P 추가됨]
```

---

## 현재 코드의 문제점

### 문제 1: GRANT_POINTS 액션 미처리

**현재 `MissionService.update_progress()`**:
```python
matching_actions = [
    a for a in campaign.actions 
    if a.trigger == trigger.value 
    and a.action_type == "UPDATE_PROGRESS"  # ← 여기가 문제!
]
```

**문제**: `GRANT_POINTS` 액션은 처리하지 않음!

**해결 방법**: `GRANT_POINTS` 액션도 처리하도록 수정 필요

### 문제 2: 트리거 호출 누락 가능성

**현재**: 각 서비스에서 개별적으로 호출
- `TrackingService`에서 호출 ✅
- `PetUpdateController`에서 호출? ⚠️
- `ClickService`에서 호출? ⚠️

**해결 방법**: 이벤트 버스 패턴 도입

---

## 실제 동작 확인 방법

### 1. 이벤트 생성 확인
```sql
SELECT * FROM campaigns WHERE key = 'first_tracking_1000p';
SELECT * FROM campaign_actions WHERE campaign_id = '...';
```

### 2. 사용자 행동 확인
```sql
SELECT * FROM trackings WHERE user_id = 'user-123';
```

### 3. 트리거 처리 확인
- 로그에서 `MissionService.update_progress()` 호출 확인
- 활성 캠페인 조회 결과 확인

### 4. 보상 지급 확인
```sql
SELECT * FROM user_campaign_rewards 
WHERE user_id = 'user-123' AND campaign_id = '...';

SELECT * FROM point_ledgers 
WHERE user_id = 'user-123' AND reason LIKE 'campaign:%';
```

---

## 요약

**이벤트 시스템 동작 원리**:

1. **관리자가 이벤트 생성** → DB에 저장 (Campaign + CampaignAction)
2. **사용자 행동 발생** → 해당 서비스에서 트리거 호출
3. **트리거 처리** → 활성 캠페인 조회 → 규칙 평가 → 액션 실행
4. **보상 지급** → 중복 체크 → 포인트 지급 → 기록 저장

**핵심 포인트**:
- 트리거는 **사용자 행동**에 의해 발생
- 트리거 발생 시 **자동으로** 활성 캠페인을 찾아서 처리
- 중복 지급은 **DB 레벨**에서 방지

**현재 미구현**:
- `GRANT_POINTS` 액션 처리 로직
- 일부 트리거 호출 누락 가능성
