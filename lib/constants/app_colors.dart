import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 상수
class AppColors {
  // 메인 브랜드 색상
  static const primary = Color(0xFFA295D5);        // 메인 보라색
  static const primaryDark = Color(0xFF847DC4);    // 진한 보라색
  static const primaryBackground = Color(0xFFF3F1FA); // 보라 배경
  static const primaryBorder = Color(0xFFD4CDEB);  // 보라 테두리

  // 텍스트 색상
  static const textPrimary = Color(0xFF1F2937);    // 기본 텍스트 (진한)
  static const textSecondary = Color(0xFF374151);  // 보조 텍스트
  static const textTertiary = Color(0xFF6B7280);   // 3차 텍스트 (연한)
  static const textHint = Color(0xFF9CA3AF);       // 힌트/플레이스홀더
  static const textMuted = Color(0xFF6E6475);      // 비활성 텍스트

  // 테두리/구분선 색상
  static const border = Color(0xFFE5E7EB);         // 기본 테두리
  static const borderLight = Color(0xFFD1D5DB);    // 연한 테두리
  static const divider = Color(0xFF3F4146);        // 구분선

  // 배경 색상
  static const backgroundLight = Color(0xFFF9FAFB); // 연한 배경
  static const backgroundGrey = Color(0xFFF3F4F6);  // 회색 배경
  static const iconBackground = Color(0xFFC1BBC3);  // 아이콘 배경

  // 상태 색상 - 성공 (녹색)
  static const success = Color(0xFF2D9C61);        // 성공 텍스트
  static const successLight = Color(0xFF78D2A8);   // 성공 연한
  static const successBackground = Color(0xFFFAFFFB); // 성공 배경

  // 상태 색상 - 경고/하락 (빨강/핑크)
  static const error = Color(0xFFEF4444);          // 에러/삭제
  static const warning = Color(0xFFE75D7D);        // 경고/하락
  static const warningLight = Color(0xFFF06B8A);   // 경고 연한
  static const warningBackground = Color(0xFFFFF9FA); // 경고 배경
}
