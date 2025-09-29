// API 서비스 사용 예제
// 각 API 서비스의 사용법을 보여주는 예제 코드

import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/api_models.dart';

class ApiServiceExample {
  final ApiService _apiService = ApiService();

  /// API 서비스 초기화 예제
  Future<void> initializeExample() async {
    // API 서비스 초기화
    _apiService.initialize();
    debugPrint('API 서비스가 초기화되었습니다.');
  }

  /// 회원가입 예제
  Future<void> registerExample() async {
    try {
      final request = RegisterRequest(
        email: 'user@example.com',
        password: 'password123',
        nickname: '테스트유저',
      );

      final response = await _apiService.auth.register(request);
      
      if (response.success && response.data != null) {
        debugPrint('회원가입 성공: ${response.data!.accessToken}');
        
        // 토큰 저장
        _apiService.setAuthToken(
          response.data!.accessToken,
          response.data!.refreshToken,
        );
      } else {
        debugPrint('회원가입 실패: ${response.error}');
      }
    } catch (e) {
      debugPrint('회원가입 오류: $e');
    }
  }

  /// 로그인 예제
  Future<void> loginExample() async {
    try {
      final request = LoginRequest(
        email: 'user@example.com',
        password: 'password123',
      );

      final response = await _apiService.auth.login(request);
      
      if (response.success && response.data != null) {
        debugPrint('로그인 성공');
        // 토큰은 자동으로 저장됨
      } else {
        debugPrint('로그인 실패: ${response.error}');
      }
    } catch (e) {
      debugPrint('로그인 오류: $e');
    }
  }

  /// 사용자 정보 조회 예제
  Future<void> getUserInfoExample() async {
    try {
      final response = await _apiService.user.getMyInfo();
      
      if (response.success && response.data != null) {
        final user = response.data!;
        debugPrint('사용자 정보: ${user.nickname} (${user.email})');
      } else {
        debugPrint('사용자 정보 조회 실패: ${response.error}');
      }
    } catch (e) {
      debugPrint('사용자 정보 조회 오류: $e');
    }
  }

  /// 통화 기록 생성 예제
  Future<void> createCallLogExample() async {
    try {
      final response = await _apiService.callLog.createCallLog(
        alarmTitle: '아침 7시 알람',
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
        duration: 300, // 5분
        isSuccessful: true,
        transcript: 'AI와의 대화 내용입니다.',
        metadata: {
          'alarmId': 'alarm_123',
          'aiModel': 'gpt-4',
        },
      );
      
      if (response.success && response.data != null) {
        debugPrint('통화 기록 생성 성공: ${response.data!.id}');
      } else {
        debugPrint('통화 기록 생성 실패: ${response.error}');
      }
    } catch (e) {
      debugPrint('통화 기록 생성 오류: $e');
    }
  }

  /// 포인트 현황 조회 예제
  Future<void> getPointSummaryExample() async {
    try {
      final response = await _apiService.points.getPointSummary();
      
      if (response.success && response.data != null) {
        final summary = response.data!;
        debugPrint('총 포인트: ${summary.totalPoints}');
        debugPrint('오늘 획득: ${summary.earnedToday}');
        debugPrint('오늘 사용: ${summary.spentToday}');
      } else {
        debugPrint('포인트 현황 조회 실패: ${response.error}');
      }
    } catch (e) {
      debugPrint('포인트 현황 조회 오류: $e');
    }
  }

  /// 미션 결과 저장 예제
  Future<void> saveMissionResultExample() async {
    try {
      final response = await _apiService.mission.saveMathMissionResult(
        alarmId: 'alarm_123',
        isCompleted: true,
        score: 85,
        problems: [
          {'question': '2 + 3 = ?', 'answer': 5, 'userAnswer': 5, 'correct': true},
          {'question': '7 * 8 = ?', 'answer': 56, 'userAnswer': 56, 'correct': true},
        ],
        correctAnswers: 2,
        totalProblems: 2,
        timeSpent: 45, // 45초
      );
      
      if (response.success && response.data != null) {
        debugPrint('미션 결과 저장 성공: ${response.data!.id}');
      } else {
        debugPrint('미션 결과 저장 실패: ${response.error}');
      }
    } catch (e) {
      debugPrint('미션 결과 저장 오류: $e');
    }
  }

  /// 통계 조회 예제
  Future<void> getStatisticsExample() async {
    try {
      final response = await _apiService.statistics.getOverview();
      
      if (response.success && response.data != null) {
        final stats = response.data!;
        debugPrint('총 알람 수: ${stats.totalAlarms}');
        debugPrint('성공률: ${stats.successRate}%');
        debugPrint('평균 통화 시간: ${stats.averageCallTime}초');
      } else {
        debugPrint('통계 조회 실패: ${response.error}');
      }
    } catch (e) {
      debugPrint('통계 조회 오류: $e');
    }
  }

  /// 대시보드 데이터 조회 예제
  Future<void> getDashboardDataExample() async {
    try {
      final data = await _apiService.getDashboardData();
      
      debugPrint('대시보드 데이터 로드 완료:');
      debugPrint('- 사용자: ${data['user']}');
      debugPrint('- 포인트: ${data['pointSummary']}');
      debugPrint('- 전체 통계: ${data['overview']}');
      debugPrint('- 오늘 통계: ${data['todayStats']}');
      debugPrint('- 최근 통화: ${data['recentCallLogs']}');
      debugPrint('- 최근 미션: ${data['recentMissions']}');
    } catch (e) {
      debugPrint('대시보드 데이터 로드 오류: $e');
    }
  }

  /// 알람 완료 처리 예제
  Future<void> completeAlarmSessionExample() async {
    try {
      final result = await _apiService.completeAlarmSession(
        alarmId: 'alarm_123',
        alarmTitle: '아침 7시 알람',
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
        isSuccessful: true,
        transcript: 'AI와의 대화가 완료되었습니다.',
        missionResults: {
          'math': {
            'isCompleted': true,
            'score': 90,
            'problems': [
              {'question': '5 + 7', 'answer': 12, 'correct': true},
            ],
            'correctAnswers': 1,
            'totalProblems': 1,
            'timeSpent': 30,
          },
        },
      );
      
      debugPrint('알람 세션 완료 처리 성공:');
      debugPrint('- 통화 기록: ${result['callLog']}');
      debugPrint('- 획득 포인트: ${result['totalPointsEarned']}');
      debugPrint('- 미션 결과: ${result['missionResults']}');
    } catch (e) {
      debugPrint('알람 세션 완료 처리 오류: $e');
    }
  }

  /// 전체 사용 예제 실행
  Future<void> runAllExamples() async {
    debugPrint('=== API 서비스 사용 예제 시작 ===');
    
    // 1. 초기화
    await initializeExample();
    
    // 2. 회원가입 (실제 환경에서는 한 번만)
    // await registerExample();
    
    // 3. 로그인
    await loginExample();
    
    if (_apiService.isAuthenticated) {
      // 4. 사용자 정보 조회
      await getUserInfoExample();
      
      // 5. 통화 기록 생성
      await createCallLogExample();
      
      // 6. 포인트 현황 조회
      await getPointSummaryExample();
      
      // 7. 미션 결과 저장
      await saveMissionResultExample();
      
      // 8. 통계 조회
      await getStatisticsExample();
      
      // 9. 대시보드 데이터 조회
      await getDashboardDataExample();
      
      // 10. 알람 완료 처리
      await completeAlarmSessionExample();
    }
    
    debugPrint('=== API 서비스 사용 예제 완료 ===');
  }

  /// 리소스 정리
  void dispose() {
    _apiService.dispose();
  }
}
