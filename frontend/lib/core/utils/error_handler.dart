/// 에러 처리 유틸리티 - 단일 책임: Exception을 Failure로 변환
import '../error/failures.dart';
import '../error/exceptions.dart';

/// Exception을 Failure로 변환하는 공통 함수
/// 사용자 친화적인 메시지로 변환
Failure handleException(Exception exception) {
  if (exception is ServerException) {
    // 서버 에러 메시지가 이미 사용자 친화적이면 그대로 사용
    final message = exception.message;
    if (message.isNotEmpty && !message.contains('Exception') && !message.contains('Error')) {
      return ServerFailure(message);
    }
    return ServerFailure('A server error occurred. Please try again later.');
  } else if (exception is NetworkException) {
    return NetworkFailure('Please check your internet connection.');
  } else if (exception is CacheException) {
    return CacheFailure('Failed to load data. Please try again.');
  } else {
    return ServerFailure('An unknown error occurred. Please try again later.');
  }
}
