import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_styles.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_elevation.dart';

/// AngyCall 앱의 테마 설정
/// AngyCall-Flutter-Design-Spec.md와 Color-Guidelines.mdc 통합
class AppTheme {
  
  /// 라이트 테마 (디자인 명세서 기반)
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      tertiary: AppColors.tertiaryColor,
      error: AppColors.errorColor,
      surface: AppColors.surfaceColor,
      onSurface: AppColors.onSurfaceColor,
      surfaceVariant: AppColors.surfaceVariantColor,
      onSurfaceVariant: AppColors.onSurfaceVariantColor,
      outline: AppColors.outlineColor,
      outlineVariant: AppColors.outlineVariantColor,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.surfaceColor,
      foregroundColor: AppColors.onSurfaceColor,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
        ),
        elevation: AppElevation.level1,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: AppElevation.level1,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
      ),
      color: AppColors.surfaceColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: const BorderSide(color: AppColors.outlineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: const BorderSide(color: AppColors.outlineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
    ),
  );

  /// 다크 테마 (Color-Guidelines.mdc 기반)
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      // Primary Colors
      primary: AppColors.enhancedPrimary,           // Primary Red
      onPrimary: Colors.white,
      primaryContainer: AppColors.enhancedPrimaryHover,
      onPrimaryContainer: Colors.white,
      
      // Secondary Colors (Success)
      secondary: AppColors.enhancedSuccess,         // Success Green
      onSecondary: Colors.white,
      secondaryContainer: AppColors.enhancedSuccessHover,
      onSecondaryContainer: Colors.white,
      
      // Tertiary Colors (Warning/Info)
      tertiary: AppColors.enhancedWarning,          // Warning Amber
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.enhancedInfo,    // Info Blue
      onTertiaryContainer: Colors.white,
      
      // Background Colors
      background: AppColors.enhancedDarkBackground,  // 완전한 검은색 배경
      onBackground: AppColors.enhancedDarkOnSurface, // 메인 텍스트
      
      // Surface Colors
      surface: AppColors.enhancedDarkSurface,        // 카드, 패널 배경
      onSurface: AppColors.enhancedDarkOnSurface,    // 메인 텍스트
      surfaceVariant: AppColors.enhancedDarkSurfaceVariant, // 입력 필드, 비활성 버튼
      onSurfaceVariant: AppColors.enhancedDarkOnSurfaceVariant, // 보조 텍스트
      
      // Error Colors
      error: AppColors.enhancedPrimary,              // 오류, 실패 상태
      onError: Colors.white,
      
      // Outline Colors
      outline: AppColors.enhancedDarkOutline,        // 테두리, 구분선
      outlineVariant: AppColors.enhancedDarkOutlineVariant, // 비활성 텍스트
    ),
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.enhancedDarkBackground,
      foregroundColor: AppColors.enhancedDarkOnSurface,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.enhancedPrimary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.enhancedDarkSurfaceVariant,
        disabledForegroundColor: AppColors.enhancedDarkOutlineVariant,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
        ),
        elevation: AppElevation.level1,
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.hovered)) {
            return AppColors.enhancedPrimaryHover;
          }
          if (states.contains(MaterialState.pressed)) {
            return AppColors.enhancedPrimaryActive;
          }
          return null;
        }),
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.enhancedDarkSurface,
      shadowColor: Colors.black54,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.level1,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: BorderSide(
          color: AppColors.enhancedDarkOutline,
          width: 1,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.white;
        }
        return AppColors.enhancedDarkOnSurfaceVariant;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.enhancedPrimary;
        }
        return AppColors.enhancedDarkSurfaceVariant;
      }),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.enhancedDarkSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: AppColors.enhancedDarkOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: AppColors.enhancedDarkOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: AppColors.enhancedPrimary, width: 2),
      ),
      labelStyle: TextStyle(color: AppColors.enhancedDarkOnSurfaceVariant),
      hintStyle: TextStyle(color: AppColors.enhancedDarkOnSurfaceVariant),
    ),
  );
}
