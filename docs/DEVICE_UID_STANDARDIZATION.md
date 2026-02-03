# Device UID 기반 인증 시스템 표준화 문서

## 📋 변경 파일 리스트

### 프론트엔드
1. `frontend/lib/core/services/device_uid_service.dart` (신규)
2. `frontend/lib/core/network/device_uid_interceptor.dart` (신규)
3. `frontend/lib/core/network/api_client.dart` (수정)
4. `frontend/lib/domain/services/pet_service.dart` (수정)
5. `frontend/lib/features/onboarding/presentation/controllers/onboarding_controller.dart` (수정)
6. `frontend/lib/features/home/presentation/screens/home_screen.dart` (수정)
7. `frontend/lib/core/widgets/debug_panel.dart` (신규)
8. `frontend/lib/app/router/app_router.dart` (이미 구현됨)

### 백엔드
1. `backend/app/api/deps.py` (수정)
2. `backend/app/api/v1/pets.py` (수정)

---

## 🔧 핵심 코드

### 1) DeviceUidService (단일 진실 소스)

```dart
// frontend/lib/core/services/device_uid_service.dart
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';

class DeviceUidService {
  static const _uuid = Uuid();

  /// Device UID 가져오기 (없으면 생성)
  static Future<String> getOrCreate() async {
    final existingUid = await SecureStorage.read(StorageKeys.deviceUid);
    if (existingUid != null && existingUid.isNotEmpty) {
      return existingUid;
    }

    final newUid = _uuid.v4();
    await SecureStorage.write(StorageKeys.deviceUid, newUid);
    print('[DeviceUidService] 새 UID 생성: ${newUid.substring(0, 8)}...');
    return newUid;
  }

  /// Device UID 가져오기 (생성하지 않음)
  static Future<String?> get() async {
    return await SecureStorage.read(StorageKeys.deviceUid);
  }

  /// Device UID 삭제 (디버그 빌드에서만)
  static Future<void> reset() async {
    if (!kDebugMode) {
      throw StateError('reset()은 디버그 빌드에서만 사용 가능합니다.');
    }
    await SecureStorage.delete(StorageKeys.deviceUid);
    print('[DeviceUidService] UID 삭제 완료');
  }
}
```

### 2) API Client Header 주입 코드

```dart
// frontend/lib/core/network/device_uid_interceptor.dart
import 'package:dio/dio.dart';
import '../services/device_uid_service.dart';

class DeviceUidInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final deviceUid = await DeviceUidService.getOrCreate();
      options.headers['X-Device-UID'] = deviceUid;
      print('[DeviceUidInterceptor] X-Device-UID 헤더 추가: ${deviceUid.substring(0, 8)}...');
    } catch (e) {
      print('[DeviceUidInterceptor] Device UID 가져오기 실패: $e');
    }
    super.onRequest(options, handler);
  }
}

// frontend/lib/core/network/api_client.dart
// Interceptors 추가 (순서 중요: DeviceUidInterceptor가 먼저)
_dio.interceptors.add(DeviceUidInterceptor());
_dio.interceptors.add(LoggingInterceptor());
```

### 3) DebugPanel 위젯

```dart
// frontend/lib/core/widgets/debug_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/device_uid_service.dart';
import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../app/router/route_paths.dart';

class DebugPanel extends ConsumerStatefulWidget {
  const DebugPanel({super.key});

  @override
  ConsumerState<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends ConsumerState<DebugPanel> {
  String? _deviceUid;
  String? _userId;
  bool? _onboardingCompleted;
  String? _primaryPetId;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    if (!kDebugMode) return;

    final deviceUid = await DeviceUidService.get();
    final onboardingCompleted = await SecureStorage.read(StorageKeys.onboardingCompleted);
    final primaryPetId = await SecureStorage.read(StorageKeys.primaryPetId);
    
    final homeState = ref.read(homeControllerProvider);
    final userId = homeState.petSummary?.petId; // TODO: 실제 userId는 서버 응답에서 가져와야 함

    setState(() {
      _deviceUid = deviceUid;
      _userId = userId;
      _onboardingCompleted = onboardingCompleted == 'true';
      _primaryPetId = primaryPetId;
    });
  }

  Future<void> _resetUid() async {
    if (!kDebugMode) return;
    
    await DeviceUidService.reset();
    await _loadDebugInfo();
    
    if (mounted) {
      context.go(RoutePaths.onboarding);
    }
  }

  Future<void> _resetOnboarding() async {
    if (!kDebugMode) return;
    
    await SecureStorage.delete(StorageKeys.onboardingCompleted);
    await SecureStorage.delete(StorageKeys.draftNickname);
    await SecureStorage.delete(StorageKeys.draftPetProfile);
    await SecureStorage.delete(StorageKeys.primaryPetId);
    await SecureStorage.delete(StorageKeys.primaryPetSummary);
    
    await _loadDebugInfo();
    
    if (mounted) {
      context.go(RoutePaths.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 Debug Panel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildDebugRow('UID', _deviceUid?.substring(0, 8) ?? 'N/A'),
          _buildDebugRow('UserID', _userId ?? 'N/A'),
          _buildDebugRow('Onboarding', _onboardingCompleted?.toString() ?? 'N/A'),
          _buildDebugRow('PetID', _primaryPetId?.substring(0, 8) ?? 'N/A'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _resetUid,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Reset UID',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _resetOnboarding,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Reset Onboarding',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 9, color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 9, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🛣️ 라우팅 가드 코드 스니펫

```dart
// frontend/lib/app/router/app_router.dart
GoRouter(
  initialLocation: RoutePaths.onboarding,
  redirect: (context, state) async {
    final onboardingRepo = OnboardingRepositoryImpl();
    final isCompleted = await onboardingRepo.isOnboardingCompleted();
    final location = state.uri.path;

    // A) 온보딩 미완료 → 온보딩으로 리다이렉트
    if (!isCompleted) {
      if (location != RoutePaths.onboarding) {
        return RoutePaths.onboarding;
      }
      return null; // 이미 온보딩 화면이면 그대로
    }

    // B) 온보딩 완료 → 온보딩 화면 접근 시 홈으로 리다이렉트
    if (isCompleted && location == RoutePaths.onboarding) {
      return RoutePaths.home;
    }

    return null; // 리다이렉트 불필요
  },
  // ... routes
)
```

---

## 🧪 iOS/Android 로컬 테스트 시나리오 체크리스트

| 시나리오 | 단계 | 기대 동작 | DB 변화 (users row count) |
|---------|------|----------|---------------------------|
| **1) iOS Simulator 첫 실행** | 1. 앱 설치 후 실행 | UID 생성 (SecureStorage) | - |
| | 2. 온보딩 완료 | `POST /v1/onboarding/complete` 호출 | users: 0 → 1 |
| | 3. 홈 화면 진입 | `GET /v1/pets/primary` 호출 (X-Device-UID 헤더) | 변화 없음 |
| **2) 앱 종료/재실행** | 1. 앱 완전 종료 | - | - |
| | 2. 앱 재실행 | 동일한 UID 사용 (SecureStorage에서 읽음) | 변화 없음 |
| | 3. 홈 화면 진입 | `GET /v1/pets/primary` 호출 (동일한 X-Device-UID) | 변화 없음 |
| **3) Reset UID 후 재실행** | 1. 디버그 패널에서 "Reset UID" 클릭 | UID 삭제 | 변화 없음 |
| | 2. 앱 재실행 | 새 UID 생성 | 변화 없음 |
| | 3. 온보딩 완료 | `POST /v1/onboarding/complete` 호출 (새 UID) | users: 1 → 2 |
| **4) 앱 업데이트 (빌드만 변경)** | 1. 앱 업데이트 설치 | - | - |
| | 2. 앱 실행 | 동일한 UID 유지 (SecureStorage 유지) | 변화 없음 |
| | 3. 홈 화면 진입 | `GET /v1/pets/primary` 호출 (동일한 X-Device-UID) | 변화 없음 |
| **5) 앱 삭제 후 재설치** | 1. 앱 완전 삭제 | SecureStorage 삭제됨 | 변화 없음 |
| | 2. 앱 재설치 후 실행 | 새 UID 생성 | 변화 없음 |
| | 3. 온보딩 완료 | `POST /v1/onboarding/complete` 호출 (새 UID) | users: 2 → 3 |

---

## 📝 백엔드 API 수정 사항

### `/v1/pets/primary` 엔드포인트 변경

**이전:**
```python
@router.get("/primary", response_model=PetSummaryResponse)
async def get_primary_pet(
    device_uid: str = Query(..., description="Device UID"),
    db: AsyncSession = Depends(get_db)
):
```

**이후:**
```python
@router.get("/primary", response_model=PetSummaryResponse)
async def get_primary_pet(
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db)
):
    if not device_uid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Device-UID header is required"
        )
```

### `get_device_uid` Dependency 추가

```python
# backend/app/api/deps.py
async def get_device_uid(
    x_device_uid: Optional[str] = Header(None, alias="X-Device-UID"),
) -> Optional[str]:
    """X-Device-UID 헤더에서 device_uid 추출"""
    return x_device_uid
```

---

## ✅ 구현 체크리스트

### 프론트엔드
- [x] DeviceUidService를 `core/services/`로 이동 및 표준화
- [x] 모든 device_uid 접근을 DeviceUidService로 통일
- [x] DeviceUidInterceptor 생성 및 API Client에 추가
- [x] 모든 API 요청에 X-Device-UID 헤더 자동 첨부
- [x] 홈 화면 진입 시 getPrimaryPetSummary 자동 호출 (이미 구현됨)
- [x] GoRouter 가드 구현 (이미 구현됨)
- [x] 디버그 패널 추가 (홈 화면 하단)
- [x] Reset UID 기능 (디버그 빌드만)
- [x] Reset Onboarding 기능 (디버그 빌드만)

### 백엔드
- [x] `get_device_uid` dependency 생성
- [x] `/v1/pets/primary` 엔드포인트를 헤더 기반으로 변경
- [ ] CORS 설정 (Web 개발용, 선택사항)

---

## 🔍 테스트 방법

### iOS Simulator
```bash
# 1. 앱 실행
flutter run -d iPhone

# 2. 디버그 패널 확인
# - 홈 화면 하단에 디버그 패널 표시
# - UID 앞 8자리 확인

# 3. Reset UID 테스트
# - "Reset UID" 버튼 클릭
# - 앱이 온보딩으로 이동
# - 새 UID 생성 확인
```

### Android Emulator
```bash
# 1. 앱 실행
flutter run -d emulator-5554

# 2. 동일한 테스트 수행
```

---

## 🚨 주의사항

1. **Device UID는 절대 직접 접근하지 마세요**
   - ❌ `SecureStorage.read(StorageKeys.deviceUid)` 직접 호출 금지
   - ✅ `DeviceUidService.getOrCreate()` 사용

2. **API 요청 시 Device UID 수동 전달 금지**
   - ❌ `queryParameters: {'device_uid': deviceUid}` 직접 전달 금지
   - ✅ `DeviceUidInterceptor`가 자동으로 헤더에 추가

3. **디버그 패널은 디버그 빌드에서만 표시**
   - Release 빌드에서는 자동으로 숨겨짐

4. **Web 개발 시 CORS 설정 필요 (선택사항)**
   - 백엔드에서 `X-Device-UID` 헤더를 허용하도록 CORS 설정
   - 하지만 최종 목표는 iOS/Android이므로 Web은 개발용

---

## 📊 데이터 흐름

```
앱 시작
  ↓
DeviceUidService.getOrCreate()
  ↓
SecureStorage에서 device_uid 읽기
  ↓ (없으면)
UUID v4 생성 → SecureStorage에 저장
  ↓
API 요청 시
  ↓
DeviceUidInterceptor.onRequest()
  ↓
X-Device-UID 헤더 자동 추가
  ↓
백엔드 API
  ↓
get_device_uid dependency
  ↓
헤더에서 device_uid 추출
  ↓
비즈니스 로직 처리
```

---

## 🎯 다음 단계

1. iOS Simulator에서 테스트
2. Android Emulator에서 테스트
3. 실제 기기에서 테스트
4. 앱 삭제/재설치 시나리오 테스트
5. 백엔드 로그에서 X-Device-UID 헤더 확인
