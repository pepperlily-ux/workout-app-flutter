import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 앱 전체에서 사용하는 텍스트 스타일
class AppTypography {
  // ============ 제목 (Heading) ============

  /// 스플래시/메인 제목 - 28px, Bold
  static const heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// 숫자 강조 (날짜 등) - 24px, Regular
  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// 섹션 제목 - 18px, SemiBold
  static const heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ============ 본문 (Body) ============

  /// 기본 본문 - 16px, Medium
  static const body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// 보조 본문 - 14px, Medium
  static const body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// 일반 본문 - 14px, Regular
  static const body3 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // ============ 캡션/작은 텍스트 ============

  /// 캡션 - 12px, Medium
  static const caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );

  /// 캡션 (연한) - 12px, Regular
  static const caption2 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  /// 아주 작은 텍스트 - 11px
  static const tiny = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  // ============ 버튼 ============

  /// 기본 버튼 텍스트 - 14px, Medium
  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// 큰 버튼 텍스트 - 16px, Medium
  static const buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  // ============ 입력 필드 ============

  /// 입력 텍스트 - 14px, Regular
  static const input = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// 힌트 텍스트 - 14px, Regular
  static const hint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  // ============ 키보드 ============

  /// 키보드 숫자 - 22px
  static const keyboardNumber = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// 키보드 버튼 - 18px
  static const keyboardButton = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );
}
