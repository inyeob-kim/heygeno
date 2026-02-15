# 이벤트 시스템 설계 및 동작 흐름

## 1. 개요

이벤트 시스템은 **Campaign** 모델을 중심으로 동작하는 이벤트 기반 보상 시스템입니다.
관리자가 이벤트를 생성하면, 사용자의 특정 행동(트리거)이 발생했을 때 자동으로 보상이 지급됩니다.

---

## 2. 핵심 개념

### 2.1 Campaign (캠페인)
- **종류**: EVENT, NOTICE, AD, MISSION
- **노출 위치**: HOME_MODAL, HOME_BANNER, NOTICE_CENTER
- **템플릿**: image_top, no_image, product_spotlight
- **기간**: start_at ~ end_at
- **활성화**: is_enabled

### 2.2 CampaignRule (규칙)
- **목적**: 이벤트 노출/지급 대상 조건 설정
- **형식**: JSONB (유연한 조건 표현)
- **예시**: 특정 사용자 그룹, 특정 기간 등

### 2.3 CampaignAction (액션)
- **트리거**: 이벤트 발생 조건
  - `FIRST_TRACKING_CREATED`: 첫 추적 생성 시
  - `TRACKING_CREATED`: 추적 생성 시
  - `ALERT_CLICKED`: 알림 클릭 시
  - `PROFILE_UPDATED`: 프로필 업데이트 시
  - `ALERT_CREATED`: 알림 생성 시
  - `REFERRAL_CONFIRMED`: 추천인 확인 시

- **액션 타입**:
  - `GRANT_POINTS`: 포인트 지급
  - `SHOW_ONLY`: 노출만 (보상 없음)
  - `UPDATE_PROGRESS`: 미션 진행도 업데이트

- **액션 데이터**: JSONB (예: `{"points": 1000}`)

---

## 3. 관리자 페이지에서 이벤트 생성 시 흐름

### 3.1 이벤트 생성 API 호출

**엔드포인트**: `POST /api/v1/admin/campaigns`

**요청 예시**:
```json
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
    "image_url": "https://...",
    "reward_points": 1000
  },
  "rules": [
    {
      "condition": "user_has_no_trackings",
      "value": true
    }
  ],
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

### 3.2 백엔드 처리 과정

#### Step 1: Campaign 생성 (`CampaignService.create_campaign`)

```python
# 1. Campaign 테이블에 저장
campaign = Campaign(
    key="first_tracking_1000p",
    kind="EVENT",
    placement="HOME_MODAL",
    ...
)
db.add(campaign)
await db.flush()  # ID 생성

# 2. CampaignRule 테이블에 저장
for rule_data in data.rules:
    rule = CampaignRule(
        campaign_id=campaign.id,
        rule=rule_data.model_dump()  # JSONB로 저장
    )
    db.add(rule)

# 3. CampaignAction 테이블에 저장
for action_data in data.actions:
    action = CampaignAction(
        campaign_id=campaign.id,
        trigger="FIRST_TRACKING_CREATED",
        action_type="GRANT_POINTS",
        action={"points": 1000}  # JSONB로 저장
    )
    db.add(action)

await db.commit()
```

**결과**:
- `campaigns` 테이블에 이벤트 정보 저장
- `campaign_rules` 테이블에 규칙 저장
- `campaign_actions` 테이블에 트리거-액션 매핑 저장

---

## 4. 사용자 행동 발생 시 이벤트 처리 흐름

### 4.1 시나리오: 사용자가 첫 추적을 생성함

#### Step 1: 사용자 행동
```
사용자가 상품 추적 시작 버튼 클릭
→ POST /api/v1/trackings 호출
```

#### Step 2: TrackingService.create_tracking 실행

```python
# 추적 생성
tracking = Tracking(...)
db.add(tracking)
await db.commit()

# 첫 추적인지 확인
count = await db.execute(
    select(func.count(Tracking.id))
    .where(Tracking.user_id == user_id)
)
if count == 1:
    # 첫 추적 → 이벤트 트리거
    await MissionService.update_progress(
        db, user_id, CampaignTrigger.FIRST_TRACKING_CREATED
    )
```

#### Step 3: MissionService.update_progress 실행

```python
# 1. 해당 트리거를 가진 활성 캠페인 조회
campaigns = await db.execute(
    select(Campaign)
    .join(CampaignAction)
    .where(
        Campaign.kind == CampaignKind.MISSION,  # 또는 EVENT
        Campaign.is_enabled == True,
        CampaignAction.trigger == "FIRST_TRACKING_CREATED",
        now() BETWEEN start_at AND end_at
    )
)

# 2. 각 캠페인에 대해:
for campaign in campaigns:
    # 규칙 평가 (현재는 간단히 통과)
    if campaign.rules:
        # TODO: 규칙 평가 로직
    
    # 매칭되는 액션 찾기
    matching_actions = [
        a for a in campaign.actions 
        if a.trigger == "FIRST_TRACKING_CREATED"
    ]
    
    # 3. 액션 실행
    for action in matching_actions:
        if action.action_type == "GRANT_POINTS":
            # 포인트 지급
            points = action.action.get("points", 0)
            await PointService.grant_points(
                user_id=user_id,
                points=points,
                reason=f"campaign:{campaign.key}"
            )
            
            # 보상 기록 (중복 지급 방지)
            reward = UserCampaignReward(
                user_id=user_id,
                campaign_id=campaign.id,
                action_id=action.id,
                status="GRANTED"
            )
            db.add(reward)
```

#### Step 4: 중복 지급 방지

**체크 포인트**:
1. `UserCampaignReward` 테이블에서 이미 지급 기록 확인
   ```sql
   SELECT * FROM user_campaign_rewards
   WHERE user_id = ? AND campaign_id = ? AND action_id = ?
   ```
2. 있으면 스킵, 없으면 지급

**Unique Constraint**:
```python
UniqueConstraint('user_id', 'campaign_id', 'action_id')
```
→ DB 레벨에서도 중복 방지

---

## 5. 이벤트 노출 로직

### 5.1 홈 화면에서 이벤트 조회

**엔드포인트**: `GET /api/v1/campaigns/active` (추정)

**조회 조건**:
```python
campaigns = await db.execute(
    select(Campaign)
    .where(
        Campaign.is_enabled == True,
        Campaign.placement == "HOME_MODAL",  # 또는 HOME_BANNER
        now() BETWEEN start_at AND end_at,
        # 규칙 평가 통과
    )
    .order_by(Campaign.priority.asc())
)
```

### 5.2 중복 노출 방지

**UserCampaignImpression 테이블**:
- 사용자가 이미 본 이벤트 기록
- `suppress_until`: 일정 기간 동안 노출 숨김

**로직**:
```python
# 이미 본 이벤트인지 확인
impression = await db.execute(
    select(UserCampaignImpression)
    .where(
        UserCampaignImpression.user_id == user_id,
        UserCampaignImpression.campaign_id == campaign_id
    )
)

if impression:
    if impression.suppress_until > now():
        # 아직 숨김 기간 → 노출하지 않음
        continue
    else:
        # 노출 카운트 증가
        impression.seen_count += 1
        impression.last_seen_at = now()
else:
    # 첫 노출 기록
    impression = UserCampaignImpression(
        user_id=user_id,
        campaign_id=campaign_id,
        first_seen_at=now()
    )
    db.add(impression)
```

---

## 6. 트리거별 처리 위치

### 6.1 FIRST_TRACKING_CREATED
**처리 위치**: `TrackingService.create_tracking()`
```python
# 첫 추적인지 확인 후
await MissionService.update_progress(
    db, user_id, CampaignTrigger.FIRST_TRACKING_CREATED
)
```

### 6.2 TRACKING_CREATED
**처리 위치**: `TrackingService.create_tracking()`
```python
# 모든 추적 생성 시
await MissionService.update_progress(
    db, user_id, CampaignTrigger.TRACKING_CREATED
)
```

### 6.3 PROFILE_UPDATED
**처리 위치**: `PetUpdateController.updatePet()` (프론트엔드) 또는 `PetService.update_pet()` (백엔드)
```python
# 프로필 업데이트 성공 후
await MissionService.update_progress(
    db, user_id, CampaignTrigger.PROFILE_UPDATED
)
```

### 6.4 ALERT_CLICKED
**처리 위치**: `ClickService.create_click()` 또는 알림 클릭 API
```python
# 알림 클릭 시
await MissionService.update_progress(
    db, user_id, CampaignTrigger.ALERT_CLICKED
)
```

---

## 7. 전체 흐름도

```
┌─────────────────────────────────────────┐
│   관리자 페이지에서 이벤트 생성          │
│   POST /api/v1/admin/campaigns         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   CampaignService.create_campaign()     │
│   1. Campaign 저장                      │
│   2. CampaignRule 저장                  │
│   3. CampaignAction 저장                │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   이벤트 활성화 (DB에 저장됨)            │
│   - is_enabled = true                   │
│   - start_at ~ end_at 기간              │
└─────────────────────────────────────────┘

                    ⬇️ (시간 경과)

┌─────────────────────────────────────────┐
│   사용자 행동 발생                      │
│   예: 첫 추적 생성                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   TrackingService.create_tracking()     │
│   → 첫 추적 확인                        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   MissionService.update_progress()      │
│   1. 활성 캠페인 조회                   │
│      (trigger = FIRST_TRACKING_CREATED) │
│   2. 규칙 평가                          │
│   3. 액션 실행                          │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   액션 타입별 처리                       │
│   - GRANT_POINTS: 포인트 지급           │
│   - UPDATE_PROGRESS: 진행도 업데이트     │
│   - SHOW_ONLY: 노출만                   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   중복 지급 방지 체크                    │
│   UserCampaignReward 테이블 확인        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   보상 지급 및 기록                      │
│   - PointService.grant_points()         │
│   - UserCampaignReward 저장             │
└─────────────────────────────────────────┘
```

---

## 8. 데이터 모델 관계도

```
Campaign (이벤트)
├── CampaignRule (규칙) - 1:N
├── CampaignAction (액션) - 1:N
│   └── UserCampaignReward (보상 기록) - 1:N
├── UserCampaignImpression (노출 기록) - 1:N
└── UserMissionProgress (미션 진행도) - 1:N
```

---

## 9. 현재 구현 상태

### 9.1 구현된 부분
✅ Campaign 생성/수정/조회 API
✅ CampaignAction 트리거-액션 매핑
✅ 중복 지급 방지 (UserCampaignReward)
✅ 미션 진행도 추적 (UserMissionProgress)
✅ 트리거 처리 (FIRST_TRACKING_CREATED, TRACKING_CREATED)

### 9.2 미구현/부분 구현된 부분
⚠️ CampaignRule 평가 로직 (현재는 항상 통과)
⚠️ PROFILE_UPDATED 트리거 처리 (프로필 업데이트 시 호출 필요)
⚠️ ALERT_CLICKED 트리거 처리 (알림 클릭 시 호출 필요)
⚠️ 이벤트 노출 API (홈 화면에서 조회하는 API)
⚠️ UserCampaignImpression 관리 (중복 노출 방지)

---

## 10. 예시 시나리오

### 시나리오: "첫 추적 시작하고 1000P 받기" 이벤트

**1. 관리자가 이벤트 생성**
```
POST /api/v1/admin/campaigns
{
  "key": "first_tracking_1000p",
  "kind": "EVENT",
  "actions": [{
    "trigger": "FIRST_TRACKING_CREATED",
    "action_type": "GRANT_POINTS",
    "action": {"points": 1000}
  }]
}
```

**2. 사용자가 첫 추적 생성**
```
POST /api/v1/trackings
→ TrackingService.create_tracking() 실행
→ 첫 추적 확인 (count == 1)
→ MissionService.update_progress(..., FIRST_TRACKING_CREATED) 호출
```

**3. 이벤트 처리**
```
MissionService.update_progress():
  1. trigger="FIRST_TRACKING_CREATED"인 활성 캠페인 조회
  2. "first_tracking_1000p" 캠페인 발견
  3. 규칙 평가 (현재는 통과)
  4. 액션 실행: GRANT_POINTS
  5. PointService.grant_points(user_id, 1000) 호출
  6. UserCampaignReward 기록 (중복 방지)
```

**4. 결과**
- 사용자 포인트 지갑에 1000P 추가
- `user_campaign_rewards` 테이블에 기록
- 동일 사용자가 다시 추적 생성해도 중복 지급 안 됨

---

## 11. 트리거 확장성 문제 및 개선 방안

### 11.1 현재 시스템의 문제점

#### 문제 1: Enum 기반 트리거의 한계
현재 `CampaignTrigger`는 Enum으로 정의되어 있어:
- 새로운 트리거 추가 시 코드 수정 필요
- 배포 없이는 새로운 트리거 사용 불가
- 확장성이 제한적

**현재 구조**:
```python
class CampaignTrigger(str, enum.Enum):
    FIRST_TRACKING_CREATED = "FIRST_TRACKING_CREATED"
    TRACKING_CREATED = "TRACKING_CREATED"
    PROFILE_UPDATED = "PROFILE_UPDATED"
    # ... 새로운 트리거 추가 시 여기 수정 필요
```

**예상되는 추가 트리거들**:
- `PRODUCT_CLICKED`: 상품 클릭 시
- `RECOMMENDATION_REQUESTED`: 추천 요청 시
- `REVIEW_CREATED`: 리뷰 작성 시
- `SHARE_COMPLETED`: 공유 완료 시
- `LOGIN_DAILY`: 일일 로그인 시
- `LOGIN_STREAK_7`: 7일 연속 로그인 시
- `PRODUCT_PURCHASED`: 상품 구매 시
- `SEARCH_PERFORMED`: 검색 수행 시
- `FILTER_APPLIED`: 필터 적용 시
- `COMPARISON_VIEWED`: 비교 화면 조회 시
- 등등... 무수히 많을 수 있음

#### 문제 2: 분산된 트리거 호출
각 서비스에서 개별적으로 호출:
```python
# TrackingService에서
await MissionService.update_progress(..., FIRST_TRACKING_CREATED)

# PetUpdateController에서
await MissionService.update_progress(..., PROFILE_UPDATED)

# ClickService에서
await MissionService.update_progress(..., ALERT_CLICKED)
```

**문제점**:
- 새로운 트리거 추가 시 여러 서비스 수정 필요
- 트리거 호출 누락 가능성
- 코드 중복

### 11.2 개선 방안: 이벤트 버스 패턴

#### 방안 1: 중앙화된 이벤트 버스

**구조**:
```
이벤트 발생
    ↓
EventBus.emit(event_type, payload)
    ↓
등록된 핸들러들이 자동으로 처리
    ↓
CampaignHandler가 트리거 처리
```

**구현 예시**:
```python
# core/event_bus.py
class EventBus:
    _handlers: Dict[str, List[Callable]] = {}
    
    @classmethod
    def subscribe(cls, event_type: str, handler: Callable):
        if event_type not in cls._handlers:
            cls._handlers[event_type] = []
        cls._handlers[event_type].append(handler)
    
    @classmethod
    async def emit(cls, event_type: str, payload: Dict[str, Any]):
        handlers = cls._handlers.get(event_type, [])
        for handler in handlers:
            await handler(payload)

# 서비스 시작 시 핸들러 등록
EventBus.subscribe("tracking.created", CampaignHandler.handle_tracking_created)
EventBus.subscribe("profile.updated", CampaignHandler.handle_profile_updated)
EventBus.subscribe("product.clicked", CampaignHandler.handle_product_clicked)
# ... 새로운 트리거는 여기만 추가하면 됨
```

**사용 예시**:
```python
# TrackingService에서
tracking = Tracking(...)
db.add(tracking)
await db.commit()

# 이벤트 발생 (트리거 타입을 신경 쓸 필요 없음)
await EventBus.emit("tracking.created", {
    "user_id": user_id,
    "tracking_id": tracking.id,
    "is_first": is_first_tracking
})

# CampaignHandler가 자동으로 처리
# - FIRST_TRACKING_CREATED 트리거 처리
# - TRACKING_CREATED 트리거 처리
```

#### 방안 2: 동적 트리거 지원 (String 기반)

**현재**: Enum으로 고정
```python
trigger: CampaignTrigger  # Enum
```

**개선**: String으로 변경
```python
trigger: str  # "FIRST_TRACKING_CREATED", "CUSTOM_TRIGGER_XYZ" 등 자유롭게
```

**장점**:
- 관리자가 새로운 트리거를 DB에 직접 추가 가능
- 코드 수정 없이 트리거 확장 가능
- Enum 업데이트 및 배포 불필요

**주의사항**:
- 트리거 이름 규칙 필요 (네이밍 컨벤션)
- 오타 방지 (검증 로직)

#### 방안 3: 트리거 매핑 테이블

**새 테이블**: `trigger_mappings`
```
event_type (실제 이벤트) → campaign_trigger (캠페인 트리거)
"tracking.created" → ["TRACKING_CREATED", "FIRST_TRACKING_CREATED"]
"profile.updated" → ["PROFILE_UPDATED"]
"product.clicked" → ["PRODUCT_CLICKED"]
```

**장점**:
- 이벤트와 트리거 분리
- 하나의 이벤트가 여러 트리거를 발생시킬 수 있음
- 관리자가 매핑 관리 가능

### 11.3 권장 개선 방안

**단계적 접근**:

**Phase 1: 이벤트 버스 도입**
1. `EventBus` 클래스 구현
2. 기존 트리거 호출을 이벤트 버스로 전환
3. CampaignHandler 구현

**Phase 2: 동적 트리거 지원**
1. `CampaignTrigger` Enum → String으로 변경
2. 트리거 검증 로직 추가
3. 관리자 페이지에서 트리거 입력 가능하도록

**Phase 3: 트리거 매핑 테이블 (선택사항)**
1. `trigger_mappings` 테이블 생성
2. 이벤트 → 트리거 매핑 관리
3. 관리자 페이지에서 매핑 관리 UI

### 11.4 CampaignRule 평가 로직 구현
현재는 규칙이 있어도 항상 통과합니다. 실제 조건 평가가 필요합니다.

**예시 규칙**:
```json
{
  "condition": "user_has_no_trackings",
  "value": true
}
```

**구현 방향**:
- JSON Rule Engine 사용 (예: json-logic)
- 또는 간단한 조건문으로 평가

### 11.5 이벤트 노출 API
홈 화면에서 활성 이벤트를 조회하는 API가 필요합니다.

**제안**:
```
GET /api/v1/campaigns/active?placement=HOME_MODAL&user_id=...
```

---

## 12. 결론

현재 이벤트 시스템은 다음과 같이 동작합니다:

1. **관리자가 이벤트 생성** → DB에 저장
2. **사용자 행동 발생** → 해당 서비스에서 트리거 호출
3. **MissionService가 처리** → 활성 캠페인 조회 → 규칙 평가 → 액션 실행
4. **보상 지급** → 중복 방지 체크 후 지급

**장점**:
- 유연한 트리거-액션 시스템
- 중복 지급 방지
- 규칙 기반 조건 설정 가능

**개선 필요**:
- 규칙 평가 로직 구현
- 트리거 처리 통합
- 이벤트 노출 API 구현
