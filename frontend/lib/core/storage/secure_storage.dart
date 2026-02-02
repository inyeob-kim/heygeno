import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage 래퍼 클래스
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 값 읽기
  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      return null;
    }
  }

  /// 값 쓰기
  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      // 에러 처리
    }
  }

  /// 값 삭제
  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      // 에러 처리
    }
  }

  /// 모든 값 삭제
  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      // 에러 처리
    }
  }
}
