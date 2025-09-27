import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alarm_ring_screen.dart';
import 'core/environment/environment.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/alarm_provider.dart';
import 'dart:convert';
import 'dart:async';

// 글로벌 Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 알림 클릭 시 알람 화면으로 이동하는 함수
void navigateToAlarmScreen(String payload) {
  print('🔔 navigateToAlarmScreen 호출됨');
  print('📦 payload: $payload');
  
  try {
    final data = jsonDecode(payload);
    final alarmType = data['alarmType'] ?? '일반알람';
    final title = data['title'] ?? '알람';
    final alarmId = data['alarmId'];
    
    print('🔔 알림 데이터 파싱 성공 - 알람 화면으로 이동: $alarmType');
    print('🗝️ navigatorKey.currentState: ${navigatorKey.currentState}');
    
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed(
        '/alarm_ring',
        arguments: {
          'alarmType': alarmType,
          'alarmTime': '지금',
          'title': title,
          'alarmId': alarmId,
        },
      );
      print('✅ 네비게이션 pushNamed 호출 완료');
    } else {
      print('❌ navigatorKey.currentState가 null입니다');
    }
  } catch (e) {
    print('❌ 알림 데이터 파싱 실패: $e');
    // 기본값으로 알람 화면 표시
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed(
        '/alarm_ring',
        arguments: {
          'alarmType': '일반알람',
          'alarmTime': '지금',
          'title': '알람',
        },
      );
      print('✅ 기본값으로 네비게이션 완료');
    } else {
      print('❌ navigatorKey.currentState가 null입니다 (기본값)');
    }
  }
}

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경변수 파일 로드
  await dotenv.load(fileName: ".env");
  
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
      // 글로벌 Navigator Key 설정
      navigatorKey: navigatorKey,
      // 라이트 테마와 다크 테마 모두 지원
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Provider에서 관리하는 테마 모드 사용
      themeMode: themeMode,
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
      // 라우트 설정
      routes: {
        '/alarm_ring': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return AlarmRingScreen(
            alarmType: args?['alarmType'] ?? '일반알람',
            alarmTime: args?['alarmTime'] ?? '지금',
            alarm: args?['alarm'],
          );
        },
      },
    );
  }
}