import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';

/// Device UID 생성 및 관리 서비스 (단일 진실 소스)
/// 
/// 모든 device_uid 접근은 이 서비스를 통해서만 수행해야 합니다.
/// 직접 SecureStorage.read/write('device_uid')를 호출하지 마세요.
class DeviceUidService {
  static const _uuid = Uuid();

  /// Device UID 가져오기 (없으면 생성)
  /// 
  /// 내부 동작:
  /// 1) secureStorage.read('device_uid')
  /// 2) 없으면 UUID v4 생성
  /// 3) secureStorage.write('device_uid', uid)
  /// 4) return uid
  static Future<String> getOrCreate() async {
    // 기존 UID 확인
    final existingUid = await SecureStorage.read(StorageKeys.deviceUid);
    if (existingUid != null && existingUid.isNotEmpty) {
      return existingUid;
    }

    // 새 UID 생성
    final newUid = _uuid.v4();
    await SecureStorage.write(StorageKeys.deviceUid, newUid);
    print('[DeviceUidService] 새 UID 생성: ${newUid.substring(0, 8)}...');
    return newUid;
  }

  /// Device UID 가져오기 (생성하지 않음)
  static Future<String?> get() async {
    return await SecureStorage.read(StorageKeys.deviceUid);
  }

  /// Device UID 삭제 (디버그 빌드에서만 노출)
  /// 
  /// 주의: 디버그 빌드에서만 사용 가능합니다.
  static Future<void> reset() async {
    if (!kDebugMode) {
      throw StateError('reset()은 디버그 빌드에서만 사용 가능합니다.');
    }
    await SecureStorage.delete(StorageKeys.deviceUid);
    print('[DeviceUidService] UID 삭제 완료');
  }
}
