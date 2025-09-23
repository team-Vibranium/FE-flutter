import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/dashboard_screen.dart';
import 'core/environment/environment.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';

void main() {
  // 개발 환경으로 설정 (실제 배포시에는 production으로 변경)
  EnvironmentConfig.setEnvironment(Environment.development);
  
  runApp(
    const ProviderScope(
      child: AningCallApp(),
    ),
  );
}

class AningCallApp extends ConsumerWidget {
  const AningCallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'AningCall',
      // 라이트 테마와 다크 테마 모두 지원
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Provider에서 관리하는 테마 모드 사용
      themeMode: themeMode,
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}