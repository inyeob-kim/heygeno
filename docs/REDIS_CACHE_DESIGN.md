# Redis 중앙화 캐시 설계 문서

## 1. 개요

### 1.1 목적
- 추천 시스템의 응답 속도 개선 (PostgreSQL 조회 → Redis 조회)
- 데이터베이스 부하 감소
- 확장 가능한 캐시 아키텍처 구축
- 캐시 무효화 전략 명확화

### 1.2 현재 상태
- **현재**: PostgreSQL만 사용 (RecommendationRun, RecommendationItem 테이블)
- **문제점**: 
  - 매번 DB 조회로 인한 지연 시간
  - 복잡한 JOIN 쿼리로 인한 부하
  - 캐시 무효화가 명시적 삭제에만 의존

### 1.3 목표 아키텍처
```
요청 → Redis (L1 Cache) → PostgreSQL (L2 Cache) → 새로 계산
```

---

## 2. 캐시 계층 설계

### 2.1 2-Tier 캐시 구조

```
┌─────────────────────────────────────────┐
│         Client Request                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   L1 Cache: Redis (In-Memory)           │
│   - 빠른 조회 (1-5ms)                   │
│   - TTL 자동 관리                        │
│   - 메모리 기반                          │
└──────────────┬──────────────────────────┘
               │ Cache Miss
               ▼
┌─────────────────────────────────────────┐
│   L2 Cache: PostgreSQL (Persistent)     │
│   - 영구 저장                            │
│   - 히스토리 관리                        │
│   - 분석/디버깅 용도                     │
└──────────────┬──────────────────────────┘
               │ Not Found
               ▼
┌─────────────────────────────────────────┐
│   Compute: 새 추천 계산                  │
│   - RAG 실행                             │
│   - 스코링                               │
└─────────────────────────────────────────┘
```

### 2.2 캐시 읽기 전략 (Cache-Aside Pattern)

```
1. Redis에서 조회 시도
   ├─ Hit: 즉시 반환
   └─ Miss: PostgreSQL 조회
       ├─ Hit: Redis에 저장 후 반환
       └─ Miss: 새로 계산 → Redis + PostgreSQL 저장
```

---

## 3. 캐시 키 설계

### 3.1 키 네이밍 컨벤션

**패턴**: `{namespace}:{entity}:{identifier}:{version}`

- `namespace`: 애플리케이션 구분 (`petfood`)
- `entity`: 엔티티 타입 (`rec`, `pet`, `product`)
- `identifier`: 고유 식별자 (pet_id, product_id 등)
- `version`: 스키마 버전 (선택사항, `v1`)

### 3.2 추천 결과 캐시 키

#### 3.2.1 기본 추천 결과
```
Key: petfood:rec:result:{pet_id}
Type: String (JSON)
TTL: 7 days (604800 seconds)
Value: RecommendationResponse JSON
```

**예시**:
```
petfood:rec:result:12e923a5-e8f4-4835-afe3-2a06a8a9160c
```

#### 3.2.2 메타데이터 키 (캐시 존재 여부 확인용)
```
Key: petfood:rec:meta:{pet_id}
Type: Hash
TTL: 7 days
Fields:
  - run_id: UUID
  - created_at: ISO8601 timestamp
  - strategy: RecStrategy enum
  - item_count: int
```

**예시**:
```
petfood:rec:meta:12e923a5-e8f4-4835-afe3-2a06a8a9160c
  run_id: "a1b2c3d4-..."
  created_at: "2024-01-15T10:30:00Z"
  strategy: "RULE_V1"
  item_count: 10
```

#### 3.2.3 캐시 무효화 태그 (Tag-based invalidation)
```
Key: petfood:rec:tags:{pet_id}
Type: Set
TTL: 7 days
Members:
  - "pet:12e923a5-..." (펫 프로필 변경 시 무효화)
  - "products:updated" (상품 정보 변경 시 무효화)
```

### 3.3 펫 프로필 캐시 키

```
Key: petfood:pet:summary:{pet_id}
Type: String (JSON)
TTL: 1 hour (3600 seconds)
Value: PetSummaryResponse JSON
```

**무효화 전략**: 프로필 업데이트 시 즉시 삭제

### 3.4 상품 정보 캐시 키

```
Key: petfood:product:{product_id}
Type: String (JSON)
TTL: 24 hours (86400 seconds)
Value: ProductRead JSON
```

**무효화 전략**: 상품 정보 업데이트 시 삭제

---

## 4. TTL (Time To Live) 전략

### 4.1 계층별 TTL

| 캐시 타입 | TTL | 이유 |
|---------|-----|------|
| 추천 결과 | 7일 | 현재와 동일한 유효기간 유지 |
| 추천 메타데이터 | 7일 | 추천 결과와 동일 |
| 펫 프로필 | 1시간 | 자주 변경되지 않지만 최신성 중요 |
| 상품 정보 | 24시간 | 상품 정보는 자주 변경되지 않음 |

### 4.2 TTL 연장 전략 (Refresh-Ahead)

**시나리오**: 캐시 만료 직전 자동 갱신

```
캐시 만료까지 남은 시간 < 1일인 경우
→ 백그라운드에서 새 추천 계산 시작
→ 계산 완료 시 캐시 업데이트
```

**구현**:
- Redis의 `EXPIRE` 이벤트 리스너 사용
- 또는 별도 스케줄러로 만료 임박 캐시 확인

---

## 5. 캐시 무효화 전략

### 5.1 무효화 트리거

#### 5.1.1 펫 프로필 업데이트
```
이벤트: PetUpdate API 호출
액션:
  1. petfood:rec:result:{pet_id} 삭제
  2. petfood:rec:meta:{pet_id} 삭제
  3. petfood:rec:tags:{pet_id} 삭제
  4. petfood:pet:summary:{pet_id} 삭제
  5. PostgreSQL의 RecommendationRun도 삭제 (히스토리 정리)
```

#### 5.1.2 상품 정보 업데이트
```
이벤트: ProductUpdate API 호출
액션:
  1. petfood:product:{product_id} 삭제
  2. 해당 상품을 포함한 모든 추천 결과 무효화
     → 태그 기반 검색: petfood:rec:tags:* 에서 "products:updated" 포함 확인
```

#### 5.1.3 수동 캐시 삭제
```
이벤트: DELETE /api/v1/products/recommendations/cache
액션:
  1. petfood:rec:result:{pet_id} 삭제
  2. petfood:rec:meta:{pet_id} 삭제
  3. petfood:rec:tags:{pet_id} 삭제
```

### 5.2 패턴 매칭 기반 일괄 삭제

**사용 케이스**: 특정 패턴의 모든 키 삭제

```python
# 예: 특정 펫의 모든 캐시 삭제
keys = await redis.keys("petfood:*:{pet_id}*")
if keys:
    await redis.delete(*keys)
```

**주의사항**: `KEYS` 명령은 프로덕션에서 비권장 (성능 이슈)
**대안**: `SCAN` 명령 사용 또는 태그 기반 관리

### 5.3 태그 기반 무효화 (고급)

**개념**: 관련된 캐시를 태그로 그룹화하여 일괄 무효화

```
1. 캐시 저장 시 태그 추가
   → petfood:rec:tags:{pet_id}에 태그 추가

2. 무효화 시 태그로 검색
   → 특정 태그를 가진 모든 키 찾기
   → 일괄 삭제
```

**예시**:
```python
# 캐시 저장
await redis.set(f"petfood:rec:result:{pet_id}", data, ex=604800)
await redis.sadd(f"petfood:rec:tags:{pet_id}", f"pet:{pet_id}")

# 무효화
tag_members = await redis.smembers(f"petfood:rec:tags:{pet_id}")
for tag in tag_members:
    # 태그와 관련된 모든 키 찾기 및 삭제
    ...
```

---

## 6. 데이터 구조 설계

### 6.1 추천 결과 저장 형식

#### Redis String (JSON)
```json
{
  "pet_id": "12e923a5-e8f4-4835-afe3-2a06a8a9160c",
  "items": [
    {
      "product": {...},
      "match_score": 95.5,
      "safety_score": 98.0,
      "fitness_score": 93.0,
      ...
    }
  ],
  "is_cached": true,
  "last_recommended_at": "2024-01-15T10:30:00Z"
}
```

**장점**:
- 직렬화/역직렬화 간단
- 전체 객체를 한 번에 저장/조회

**단점**:
- 부분 업데이트 불가능
- 큰 객체의 경우 메모리 사용량 증가

#### Redis Hash (대안)
```
Key: petfood:rec:result:{pet_id}
Fields:
  - data: JSON string (전체 추천 결과)
  - run_id: UUID
  - created_at: ISO8601 timestamp
  - version: "v1"
```

**장점**:
- 메타데이터와 데이터 분리
- 부분 필드 조회 가능

**단점**:
- 구현 복잡도 증가

**결정**: **String (JSON)** 방식 채택 (단순성 우선)

### 6.2 압축 전략

**목적**: 메모리 사용량 최적화

**방법**:
1. JSON 압축 (gzip)
2. MessagePack 사용 (JSON 대비 20-30% 작음)

**구현**:
```python
import gzip
import json

# 저장
compressed = gzip.compress(json.dumps(data).encode())
await redis.set(key, compressed, ex=ttl)

# 조회
compressed = await redis.get(key)
data = json.loads(gzip.decompress(compressed).decode())
```

**트레이드오프**:
- CPU 사용량 증가 vs 메모리 사용량 감소
- 추천 결과 크기에 따라 결정

**초기 구현**: 압축 없이 시작, 필요 시 추가

---

## 7. 성능 최적화

### 7.1 파이프라인 사용

**목적**: 여러 Redis 명령을 한 번에 실행

```python
pipe = redis.pipeline()
pipe.get(f"petfood:rec:result:{pet_id}")
pipe.get(f"petfood:rec:meta:{pet_id}")
pipe.get(f"petfood:pet:summary:{pet_id}")
results = await pipe.execute()
```

**효과**: 네트워크 왕복 시간 감소

### 7.2 배치 조회

**시나리오**: 여러 펫의 추천 결과를 한 번에 조회

```python
keys = [f"petfood:rec:result:{pid}" for pid in pet_ids]
values = await redis.mget(keys)
```

### 7.3 연결 풀링

**설정**:
```python
redis_pool = redis.ConnectionPool.from_url(
    settings.REDIS_URL,
    max_connections=50,
    decode_responses=True
)
```

---

## 8. 장애 대응 (Fallback Strategy)

### 8.1 Redis 장애 시나리오

#### 시나리오 1: Redis 연결 실패
```
1. Redis 연결 시도
2. 실패 시 PostgreSQL로 fallback
3. 로그 기록 및 모니터링 알림
```

#### 시나리오 2: Redis 타임아웃
```
1. Redis 조회 시도 (타임아웃: 100ms)
2. 타임아웃 발생 시 PostgreSQL로 fallback
3. 결과를 Redis에 저장하지 않음 (장애 중이므로)
```

#### 시나리오 3: Redis 메모리 부족
```
1. Redis SET 실패 (OOM 에러)
2. PostgreSQL에만 저장
3. 기존 캐시는 유지 (LRU로 자동 삭제됨)
```

### 8.2 Circuit Breaker 패턴

**목적**: 반복적인 실패 시 Redis 호출 차단

```python
class RedisCircuitBreaker:
    def __init__(self):
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
    
    async def execute(self, func):
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > 60:
                self.state = "HALF_OPEN"
            else:
                raise RedisUnavailableException()
        
        try:
            result = await func()
            if self.state == "HALF_OPEN":
                self.state = "CLOSED"
                self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            if self.failure_count >= 5:
                self.state = "OPEN"
            raise
```

### 8.3 Graceful Degradation

**전략**: Redis가 없어도 서비스는 정상 동작

```
Redis 사용 불가:
  → PostgreSQL만 사용 (현재와 동일)
  → 성능 저하 있지만 기능은 정상
```

---

## 9. 모니터링 및 메트릭

### 9.1 주요 메트릭

| 메트릭 | 설명 | 목표 |
|--------|------|------|
| Cache Hit Rate | Redis Hit / Total Requests | > 80% |
| Cache Miss Rate | Redis Miss / Total Requests | < 20% |
| Average Response Time (Redis) | Redis 조회 평균 시간 | < 5ms |
| Average Response Time (PostgreSQL) | PostgreSQL 조회 평균 시간 | < 50ms |
| Cache Eviction Rate | LRU로 인한 캐시 삭제율 | < 1% |
| Redis Memory Usage | Redis 메모리 사용량 | < 80% |

### 9.2 로깅 전략

```python
logger.info(f"[Cache] Redis Hit: key={key}, duration={duration}ms")
logger.info(f"[Cache] Redis Miss: key={key}, fallback=PostgreSQL")
logger.warning(f"[Cache] Redis Error: {error}, fallback=PostgreSQL")
```

### 9.3 알림 설정

- Redis 연결 실패 시 즉시 알림
- Cache Hit Rate < 70% 지속 시 알림
- Redis 메모리 사용량 > 90% 시 알림

---

## 10. 구현 단계

### Phase 1: 기본 캐시 레이어 추가 (1주)
- [ ] Redis 연결 및 기본 유틸리티 구현
- [ ] 추천 결과 캐시 저장/조회 구현
- [ ] PostgreSQL fallback 구현
- [ ] 기본 테스트 작성

### Phase 2: 캐시 무효화 구현 (3일)
- [ ] 펫 프로필 업데이트 시 캐시 삭제
- [ ] 수동 캐시 삭제 API 연동
- [ ] 태그 기반 무효화 (선택사항)

### Phase 3: 최적화 및 모니터링 (3일)
- [ ] 파이프라인 사용
- [ ] 메트릭 수집
- [ ] 로깅 개선

### Phase 4: 확장 (선택사항)
- [ ] 펫 프로필 캐시 추가
- [ ] 상품 정보 캐시 추가
- [ ] 압축 기능 추가

---

## 11. 코드 구조 제안

### 11.1 디렉토리 구조

```
backend/app/
├── core/
│   ├── redis.py (기존, 확장)
│   └── cache.py (새로 추가)
│       ├── cache_service.py
│       ├── cache_keys.py
│       └── cache_strategies.py
├── services/
│   └── product_service.py (캐시 로직 통합)
```

### 11.2 주요 클래스

```python
# cache_service.py
class CacheService:
    async def get_recommendation(self, pet_id: UUID) -> Optional[RecommendationResponse]
    async def set_recommendation(self, pet_id: UUID, data: RecommendationResponse, ttl: int)
    async def invalidate_recommendation(self, pet_id: UUID)
    async def invalidate_by_pattern(self, pattern: str)

# cache_keys.py
class CacheKeys:
    @staticmethod
    def recommendation_result(pet_id: UUID) -> str
    @staticmethod
    def recommendation_meta(pet_id: UUID) -> str
    @staticmethod
    def pet_summary(pet_id: UUID) -> str
```

---

## 12. 예상 효과

### 12.1 성능 개선

| 지표 | 현재 (PostgreSQL만) | 개선 후 (Redis + PostgreSQL) | 개선율 |
|------|-------------------|---------------------------|--------|
| 추천 조회 시간 (캐시 Hit) | 50-100ms | 1-5ms | **90-95% 감소** |
| 추천 조회 시간 (캐시 Miss) | 50-100ms | 50-100ms + 1-5ms (Redis 저장) | 동일 |
| DB 부하 | 높음 | 낮음 (캐시 Hit 시) | **80% 감소** |

### 12.2 비용 절감

- 데이터베이스 쿼리 감소 → DB 서버 부하 감소
- 응답 시간 단축 → 사용자 경험 개선
- 확장성 향상 → 트래픽 증가에 대응 가능

---

## 13. 리스크 및 대응 방안

### 13.1 리스크

1. **Redis 메모리 부족**
   - 대응: LRU eviction 정책 사용, 메모리 모니터링

2. **캐시 일관성 문제**
   - 대응: 무효화 전략 명확화, 태그 기반 관리

3. **Redis 장애 시 성능 저하**
   - 대응: Circuit Breaker 패턴, PostgreSQL fallback

4. **캐시 스탬피드 (Thundering Herd)**
   - 대응: 분산 락 사용, 백그라운드 갱신

### 13.2 분산 락 (Cache Stampede 방지)

**시나리오**: 캐시 만료 시 여러 요청이 동시에 새로 계산 시작

**해결**:
```python
async def get_recommendation_with_lock(pet_id: UUID):
    # 1. 캐시 확인
    cached = await redis.get(key)
    if cached:
        return cached
    
    # 2. 락 획득 시도
    lock_key = f"{key}:lock"
    lock_acquired = await redis.set(lock_key, "1", ex=30, nx=True)
    
    if lock_acquired:
        # 락 획득 성공 → 새로 계산
        result = await compute_recommendation(pet_id)
        await redis.set(key, result, ex=604800)
        await redis.delete(lock_key)
        return result
    else:
        # 락 획득 실패 → 짧은 대기 후 재시도
        await asyncio.sleep(0.1)
        return await redis.get(key) or await get_from_postgresql(pet_id)
```

---

## 14. 결론

Redis를 활용한 중앙화 캐시 시스템을 구축하면:
- **성능**: 응답 시간 90% 이상 개선
- **확장성**: 트래픽 증가에 대응 가능
- **안정성**: PostgreSQL fallback으로 장애 대응

단계적 구현을 통해 리스크를 최소화하면서 점진적으로 개선할 수 있습니다.
