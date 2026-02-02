import 'package:flutter/material.dart';

/// 앱 Shadow 정의 (DESIGN_GUIDE.md 기반)
class AppShadows {
  // 기본 카드 그림자: 0 10px 30px rgba(15, 23, 42, 0.08)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x140F172A), // rgba(15, 23, 42, 0.08)
      blurRadius: 30,
      offset: Offset(0, 10),
      spreadRadius: 0,
    ),
  ];
  
  // 버튼 그림자: 0 10px 22px rgba(37, 99, 235, 0.18)
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x2E2563EB), // rgba(37, 99, 235, 0.18)
      blurRadius: 22,
      offset: Offset(0, 10),
      spreadRadius: 0,
    ),
  ];
  
  // AI 마크 그림자: 0 10px 22px rgba(124, 58, 237, 0.18)
  static const List<BoxShadow> aiMark = [
    BoxShadow(
      color: Color(0x2E7C3AED), // rgba(124, 58, 237, 0.18)
      blurRadius: 22,
      offset: Offset(0, 10),
      spreadRadius: 0,
    ),
  ];
  
  // 모달 그림자: 0 18px 60px rgba(15, 23, 42, 0.25)
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x400F172A), // rgba(15, 23, 42, 0.25)
      blurRadius: 60,
      offset: Offset(0, 18),
      spreadRadius: 0,
    ),
  ];
  
  // 작은 그림자 (호환성)
  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x0A0F172A), // rgba(15, 23, 42, 0.04)
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  // 중간 그림자 (호환성)
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x140F172A), // rgba(15, 23, 42, 0.08)
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  // 큰 그림자 (호환성)
  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x1A0F172A), // rgba(15, 23, 42, 0.1)
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
}
