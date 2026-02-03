import 'package:dio/dio.dart';
import '../services/device_uid_service.dart';

/// Device UID를 모든 API 요청에 자동으로 첨부하는 Interceptor
/// 
/// 모든 요청에 `X-Device-UID` 헤더를 자동으로 추가합니다.
class DeviceUidInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Device UID 가져오기 (없으면 생성)
      final deviceUid = await DeviceUidService.getOrCreate();
      
      // X-Device-UID 헤더 추가
      options.headers['X-Device-UID'] = deviceUid;
      
      print('[DeviceUidInterceptor] X-Device-UID 헤더 추가: ${deviceUid.substring(0, 8)}...');
    } catch (e) {
      print('[DeviceUidInterceptor] Device UID 가져오기 실패: $e');
      // UID를 가져오지 못해도 요청은 진행 (서버에서 처리)
    }
    
    super.onRequest(options, handler);
  }
}
