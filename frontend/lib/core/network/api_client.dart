import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/env.dart';
import 'interceptors.dart';
import 'device_uid_interceptor.dart';

// Conditional import for Platform (not available on web)
import 'dart:io' if (dart.library.html) 'platform_stub.dart' as io;

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio) {
    // iOS/Android 실제 디바이스에서는 localhost 대신 Mac의 IP 사용
    final baseUrl = _getBaseUrl();
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.followRedirects = false; // 리다이렉션 비활성화 (수동 처리)
    _dio.options.maxRedirects = 0;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // 디버깅: 사용 중인 baseUrl 출력
    print('[ApiClient] Base URL: $baseUrl');
    if (!kIsWeb) {
      print('[ApiClient] Platform: ${io.Platform.isIOS ? "iOS" : io.Platform.isAndroid ? "Android" : "Other"}');
    } else {
      print('[ApiClient] Platform: Web');
    }
    print('[ApiClient] Env.baseUrl: ${Env.baseUrl}');
    print('[ApiClient] Env.deviceBaseUrl: ${Env.deviceBaseUrl}');

    // Interceptors (순서 중요: DeviceUidInterceptor가 먼저)
    _dio.interceptors.add(DeviceUidInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
  }

  /// 플랫폼에 따라 적절한 baseUrl 반환
  String _getBaseUrl() {
    // 웹 플랫폼인 경우 baseUrl 사용
    if (kIsWeb) {
      return Env.baseUrl;
    }
    
    // iOS/Android 플랫폼인 경우 deviceBaseUrl 사용
    // deviceBaseUrl은 .env 파일에서 설정 가능
    if (io.Platform.isIOS || io.Platform.isAndroid) {
      return Env.deviceBaseUrl;
    }
    
    // 데스크톱은 baseUrl 사용
    return Env.baseUrl;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      // trailing slash 제거하여 리다이렉션 방지
      final cleanPath = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
      
      // 리다이렉션을 수동으로 처리하기 위해 먼저 시도
      try {
        return await _dio.get<T>(
          cleanPath,
          queryParameters: queryParameters,
          options: options,
        );
      } on DioException catch (e) {
        // 307 리다이렉션인 경우 trailing slash 추가하여 재시도
        if (e.response?.statusCode == 307 || e.response?.statusCode == 308) {
          final redirectPath = '$cleanPath/';
          return await _dio.get<T>(
            redirectPath,
            queryParameters: queryParameters,
            options: options,
          );
        }
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      // trailing slash 제거하여 리다이렉션 방지
      final cleanPath = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
      
      // 리다이렉션을 수동으로 처리하기 위해 먼저 시도
      try {
        return await _dio.post<T>(
          cleanPath,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      } on DioException catch (e) {
        // 307 리다이렉션인 경우 trailing slash 추가하여 재시도
        if (e.response?.statusCode == 307 || e.response?.statusCode == 308) {
          final redirectPath = '$cleanPath/';
          return await _dio.post<T>(
            redirectPath,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
        }
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }
}

// Riverpod Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio();
  return ApiClient(dio);
});

