import 'package:uuid/uuid.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/storage_keys.dart';

/// Device UID 생성 및 관리 서비스
class DeviceUidService {
  static const _uuid = Uuid();

  /// Device UID 가져오기 (없으면 생성)
  static Future<String> getOrCreateDeviceUid() async {
    // 기존 UID 확인
    final existingUid = await SecureStorage.read(StorageKeys.deviceUid);
    if (existingUid != null && existingUid.isNotEmpty) {
      return existingUid;
    }

    // 새 UID 생성
    final newUid = _uuid.v4();
    await SecureStorage.write(StorageKeys.deviceUid, newUid);
    return newUid;
  }

  /// Device UID 가져오기 (생성하지 않음)
  static Future<String?> getDeviceUid() async {
    return await SecureStorage.read(StorageKeys.deviceUid);
  }
}
