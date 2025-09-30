import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alarm_ring_screen.dart';
import 'screens/avatar_customize_screen.dart';
import 'screens/stats_screen.dart';
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

  try {
    final data = jsonDecode(payload);
    final alarmType = data['alarmType'] ?? '일반알람';
    final title = data['title'] ?? '알람';
    final alarmId = data['alarmId'];


    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed(
        '/alarm_ring',
        arguments: {
          'alarmType': alarmType,
          'alarmTime': '지금',
          'title': title,
          'alarmId': alarmId,  // 백엔드 ID가 이미 올바르게 전달됨
          // alarm 객체는 AlarmRingScreen에서 필요하면 백엔드 API로 조회
        },
      );
    } else {
    }
  } catch (e) {
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
    } else {
    }
  }
}

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // timezone 데이터 초기화
  tz.initializeTimeZones();
  
  // 한국 시간대 설정
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  } catch (e) {
  }
  
  // 환경변수 파일 로드
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
  }
  
  // 프로덕션 환경으로 설정
  EnvironmentConfig.setEnvironment(Environment.development); // Mock Repository 사용
  
  // API 서비스 초기화
  await ApiService().initialize();
  
  // 필요한 권한 요청
  await _requestPermissions();
  
  // 로컬 알람 서비스 초기화
  await LocalAlarmService.initializeOnAppStart();
  
  // 모닝콜 알람 서비스 초기화
  final String gptApiKey = dotenv.env['OPENAI_API_KEY'] ?? dotenv.env['GPT_API_KEY'] ?? '';
  if (gptApiKey.isNotEmpty) {
    try {
      await MorningCallAlarmService().initialize(
        gptApiKey: gptApiKey,
        userName: '사용자',
      );
    } catch (e) {
      // 에러 발생시 무시하고 계속 진행
    }
  }
  
  runApp(
    const ProviderScope(
      child: AningCallApp(),
    ),
  );
}

// 필요한 권한 요청 함수
Future<void> _requestPermissions() async {
  // 알림 권한
  await Permission.notification.request();
  
  // 정확한 알람 권한 (Android 12+)
  await Permission.scheduleExactAlarm.request();
  
  // 오디오 녹음 권한
  await Permission.microphone.request();
  
  // 시스템 오버레이 권한 (전체화면 알람용)
  if (await Permission.systemAlertWindow.isDenied) {
    await Permission.systemAlertWindow.request();
  }
  
  // 부팅 완료 수신 권한
  await Permission.ignoreBatteryOptimizations.request();
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
        '/avatar_customize': (context) => const AvatarCustomizeScreen(initialPoints: 0, initialAvatar: ''),
        '/stats': (context) => const StatsScreen(),
        '/alarm_ring': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return AlarmRingScreen(
            alarmType: args?['alarmType'] ?? '일반알람',
            alarmTime: args?['alarmTime'] ?? '지금',
            alarm: args?['alarm'],
            alarmId: args?['alarmId'], // 알람 ID 전달
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
      return const DashboardScreen();
    }

    // 인증되지 않은 사용자는 로그인 화면으로
    return const LoginScreen();
  }
}
