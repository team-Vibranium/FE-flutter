import 'package:flutter/material.dart';

/// AngyCall 앱의 색상 시스템
/// AngyCall-Flutter-Design-Spec.md 기반
class AppColors {
  // Primary Colors - Material Color System
  static const MaterialColor primarySwatch = MaterialColor(
    0xFFE53E3E, // Red-500
    <int, Color>{
      50: Color(0xFFFEE5E5),
      100: Color(0xFFFCCCCC),
      200: Color(0xFFF99999),
      300: Color(0xFFF66666),
      400: Color(0xFFF23333),
      500: Color(0xFFE53E3E), // Primary
      600: Color(0xFFCC3535),
      700: Color(0xFFB22C2C),
      800: Color(0xFF992323),
      900: Color(0xFF801A1A),
    },
  );

  // Semantic Colors
  static const Color primaryColor = Color(0xFFE53E3E);      // Red
  static const Color secondaryColor = Color(0xFF48BB78);     // Green  
  static const Color tertiaryColor = Color(0xFF3182CE);      // Blue
  static const Color warningColor = Color(0xFFED8936);       // Orange
  static const Color errorColor = Color(0xFFE53E3E);         // Red
  static const Color successColor = Color(0xFF48BB78);       // Green
  static const Color infoColor = Color(0xFF3182CE);          // Blue

  // Light Theme Neutral Colors
  static const Color surfaceColor = Color(0xFFFFFBFE);       // Background
  static const Color onSurfaceColor = Color(0xFF1C1B1F);     // Text
  static const Color surfaceVariantColor = Color(0xFFE7E0EC); // Cards
  static const Color onSurfaceVariantColor = Color(0xFF49454F); // Secondary text
  static const Color outlineColor = Color(0xFF79747E);        // Borders
  static const Color outlineVariantColor = Color(0xFFCAC4D0); // Dividers

  // Dark Theme Colors
  static const Color darkSurfaceColor = Color(0xFF1C1B1F);
  static const Color darkOnSurfaceColor = Color(0xFFE6E1E5);
  static const Color darkSurfaceVariantColor = Color(0xFF49454F);
  static const Color darkOnSurfaceVariantColor = Color(0xFFCAC4D0);
  static const Color darkOutlineColor = Color(0xFF938F99);
  static const Color darkOutlineVariantColor = Color(0xFF49454F);

  // Enhanced Dark Theme Colors (Color-Guidelines.mdc 호환)
  static const Color enhancedDarkBackground = Color(0xFF000000);    // 완전한 검은색 배경
  static const Color enhancedDarkSurface = Color(0xFF1F2937);       // 카드, 패널 배경
  static const Color enhancedDarkSurfaceVariant = Color(0xFF374151); // 입력 필드, 비활성 버튼
  static const Color enhancedDarkOnSurface = Color(0xFFFFFFFF);     // 메인 텍스트
  static const Color enhancedDarkOnSurfaceVariant = Color(0xFF9CA3AF); // 보조 텍스트
  static const Color enhancedDarkOutline = Color(0xFF374151);       // 테두리
  static const Color enhancedDarkOutlineVariant = Color(0xFF6B7280); // 비활성 텍스트

  // Enhanced Primary Colors (Color-Guidelines.mdc)
  static const Color enhancedPrimary = Color(0xFFEF4444);           // Primary Red
  static const Color enhancedPrimaryHover = Color(0xFFDC2626);      // Primary Red Hover
  static const Color enhancedPrimaryActive = Color(0xFFB91C1C);     // Primary Red Active
  static const Color enhancedSuccess = Color(0xFF10B981);           // Success Green
  static const Color enhancedSuccessHover = Color(0xFF059669);      // Success Green Hover
  static const Color enhancedWarning = Color(0xFFF59E0B);           // Warning Amber
  static const Color enhancedInfo = Color(0xFF3B82F6);             // Info Blue
}
