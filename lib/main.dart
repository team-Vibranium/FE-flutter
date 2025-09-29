import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alarm_ring_screen.dart';
import 'screens/login_screen.dart';
import 'core/environment/environment.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/local_alarm_service.dart';
import 'core/services/morning_call_alarm_service.dart';
import 'dart:convert';

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
      print(' 기본값으로 네비게이션 완료');
    } else {
      print('navigatorKey.currentState가 null입니다 (기본값)');
    }
  }
}

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경변수 파일 로드
  try {
    await dotenv.load(fileName: ".env");
    print('.env 파일이 로드되었습니다.');
  } catch (e) {
    print('.env 파일을 찾을 수 없습니다. 기본값을 사용합니다: $e');
  }
  
  // 개발 환경으로 설정 (실제 배포시에는 production으로 변경)
  EnvironmentConfig.setEnvironment(Environment.development);
  
  // API 서비스 초기화
  ApiService().initialize();
  print('API 서비스가 초기화되었습니다.');
  print('현재 설정된 Base URL: ${EnvironmentConfig.baseUrl}');
  print('현재 환경: ${EnvironmentConfig.current}');
  print('.env BASE_URL: ${dotenv.env['BASE_URL']}');
  
  // 로컬 알람 서비스 초기화
  final alarmInitResult = await LocalAlarmService.initializeOnAppStart();
  if (alarmInitResult) {
    print('⏰ 로컬 알람 서비스가 초기화되었습니다.');
  } else {
    print('⚠️ 로컬 알람 서비스 초기화에 실패했습니다.');
  }
  
  // 모닝콜 알람 서비스 초기화 (API 키는 환경변수에서)
  final gptApiKey = dotenv.env['GPT_API_KEY'] ?? '';
  if (gptApiKey.isNotEmpty) {
    try {
      await MorningCallAlarmService().initialize(
        gptApiKey: gptApiKey,
        userName: '예훈', // 기본 사용자 이름
      );
      print('🌅 모닝콜 서비스 초기화 완료');
    } catch (e) {
      print('❌ 모닝콜 서비스 초기화 실패: $e');
    }
  } else {
    print('⚠️ GPT API 키가 설정되지 않았습니다. 모닝콜 기능을 사용할 수 없습니다.');
  }
  
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
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      // 라우트 설정
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
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

/// 인증 상태에 따라 적절한 화면을 보여주는 래퍼 위젯
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    print('🔄 AuthWrapper 상태 확인:');
    print('  - isLoading: ${authState.isLoading}');
    print('  - isAuthenticated: ${authState.isAuthenticated}');
    print('  - user: ${authState.user?.email ?? 'null'}');
    print('  - token: ${authState.token != null ? '토큰 있음' : '토큰 없음'}');
    print('  - error: ${authState.error ?? '없음'}');

    // 로딩 중일 때 스플래시 화면
    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.alarm,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                'AningCall',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI와 함께하는 스마트 알람',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // 인증된 사용자는 대시보드로
    if (authState.isAuthenticated) {
      print('🏠 AuthWrapper: 대시보드 화면을 렌더링합니다');
      return const DashboardScreen();
    }

    // 인증되지 않은 사용자는 로그인 화면으로
    print('🔐 AuthWrapper: 로그인 화면을 렌더링합니다');
    return const LoginScreen();
  }
}