import 'package:flutter_test/flutter_test.dart';
import 'package:aningcall/core/services/api_service.dart';
import 'package:aningcall/core/models/api_models.dart';

void main() {
  group('API Service Tests', () {
    late ApiService apiService;

    setUpAll(() {
      // API 서비스 초기화
      apiService = ApiService();
      apiService.initialize();
    });

    test('API 서비스 초기화 테스트', () {
      expect(apiService.isInitialized, isTrue);
      expect(apiService.isAuthenticated, isFalse);
    });

    test('API 모델 생성 테스트', () {
      // User 모델 테스트
      final user = User(
        id: 1,
        email: 'test@example.com',
        nickname: '테스트유저',
        points: 100,
        selectedAvatar: 'avatar1',
        createdAt: DateTime.now(),
      );

      expect(user.id, equals(1));
      expect(user.email, equals('test@example.com'));
      expect(user.nickname, equals('테스트유저'));

      // JSON 직렬화 테스트
      final userJson = user.toJson();
      final userFromJson = User.fromJson(userJson);
      
      expect(userFromJson.id, equals(user.id));
      expect(userFromJson.email, equals(user.email));
      expect(userFromJson.nickname, equals(user.nickname));
    });

    test('LoginRequest 모델 테스트', () {
      final loginRequest = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      final json = loginRequest.toJson();
      expect(json['email'], equals('test@example.com'));
      expect(json['password'], equals('password123'));
    });

    test('RegisterRequest 모델 테스트', () {
      final registerRequest = RegisterRequest(
        email: 'test@example.com',
        password: 'password123',
        nickname: '테스트유저',
      );

      final json = registerRequest.toJson();
      expect(json['email'], equals('test@example.com'));
      expect(json['password'], equals('password123'));
      expect(json['nickname'], equals('테스트유저'));
    });

    test('ApiResponse 모델 테스트', () {
      // 성공 응답 테스트
      final successResponse = ApiResponse.success('test data', message: '성공');
      expect(successResponse.success, isTrue);
      expect(successResponse.data, equals('test data'));
      expect(successResponse.message, equals('성공'));
      expect(successResponse.error, isNull);

      // 에러 응답 테스트
      final errorResponse = ApiResponse.error('에러 발생', statusCode: 400);
      expect(errorResponse.success, isFalse);
      expect(errorResponse.data, isNull);
      expect(errorResponse.error, equals('에러 발생'));
      expect(errorResponse.statusCode, equals(400));
    });

    test('PointSummary 모델 테스트', () {
      final pointSummary = PointSummary(
        consumptionPoints: 800,
        gradePoints: 200,
        totalPoints: 1000,
        currentGrade: 'BRONZE',
        earnedToday: 50,
        spentToday: 20,
      );

      expect(pointSummary.totalPoints, equals(1000));
      expect(pointSummary.earnedToday, equals(50));
      expect(pointSummary.spentToday, equals(20));

      // JSON 직렬화 테스트
      final json = pointSummary.toJson();
      final fromJson = PointSummary.fromJson(json);
      
      expect(fromJson.totalPoints, equals(pointSummary.totalPoints));
      expect(fromJson.earnedToday, equals(pointSummary.earnedToday));
      expect(fromJson.spentToday, equals(pointSummary.spentToday));
    });

    test('CallLog 모델 테스트', () {
      final startTime = DateTime.now().subtract(const Duration(minutes: 5));
      final endTime = DateTime.now();

      final callLog = CallLog(
        id: 123,
        callStart: startTime,
        callEnd: endTime,
        result: 'SUCCESS',
        snoozeCount: 0,
        successful: true,
        createdAt: startTime,
        conversationData: 'AI와의 대화 내용',
      );

      expect(callLog.id, equals(123));
      expect(callLog.result, equals('SUCCESS'));
      expect(callLog.duration, greaterThan(0));
      expect(callLog.isSuccessful, isTrue);
      expect(callLog.transcript, equals('AI와의 대화 내용'));

      // JSON 직렬화 테스트
      final json = callLog.toJson();
      final fromJson = CallLog.fromJson(json);
      
      expect(fromJson.id, equals(callLog.id));
      expect(fromJson.result, equals(callLog.result));
      expect(fromJson.successful, equals(callLog.successful));
      expect(fromJson.isSuccessful, equals(callLog.isSuccessful));
    });

    test('MissionResult 모델 테스트', () {
      final missionResult = MissionResult(
        id: 123,
        callLogId: 456,
        missionType: 'MATH',
        success: true,
        score: 85,
      );

      expect(missionResult.id, equals(123));
      expect(missionResult.missionType, equals('MATH'));
      expect(missionResult.success, isTrue);
      expect(missionResult.score, equals(85));

      // JSON 직렬화 테스트
      final json = missionResult.toJson();
      final fromJson = MissionResult.fromJson(json);
      
      expect(fromJson.id, equals(missionResult.id));
      expect(fromJson.missionType, equals(missionResult.missionType));
      expect(fromJson.success, equals(missionResult.success));
      expect(fromJson.score, equals(missionResult.score));
    });

    test('StatisticsOverview 모델 테스트', () {
      final stats = StatisticsOverview(
        totalAlarms: 100,
        successAlarms: 85,
        missedAlarms: 15,
        successRate: 85.0,
        consecutiveDays: 7,
        averageWakeTime: '07:30',
        last30DaysSuccessRate: 85.0,
        monthlySuccessRate: 82.5,
        monthlyPoints: 1500,
        averageCallTime: 180.0,
        successfulWakeups: 85,
        totalCallTime: 18000,
        totalPoints: 1500,
        completedMissions: 75,
      );

      expect(stats.totalAlarms, equals(100));
      expect(stats.successfulWakeups, equals(85));
      expect(stats.successRate, equals(85.0));
      expect(stats.totalCallTime, equals(18000));
      expect(stats.averageCallTime, equals(180));
      expect(stats.totalPoints, equals(1500));
      expect(stats.completedMissions, equals(75));

      // JSON 직렬화 테스트
      final json = stats.toJson();
      final fromJson = StatisticsOverview.fromJson(json);
      
      expect(fromJson.totalAlarms, equals(stats.totalAlarms));
      expect(fromJson.successRate, equals(stats.successRate));
      expect(fromJson.totalPoints, equals(stats.totalPoints));
    });

    test('enum 값 테스트', () {
      // MissionType enum 테스트
      expect(MissionType.values.length, equals(5));
      expect(MissionType.MATH.name, equals('MATH'));
      expect(MissionType.MEMORY.name, equals('MEMORY'));
      expect(MissionType.PUZZLE.name, equals('PUZZLE'));
      expect(MissionType.QUIZ.name, equals('QUIZ'));

      // PointTransactionType enum 테스트
      expect(PointTransactionType.values.length, equals(2));
      expect(PointTransactionType.earned.name, equals('earned'));
      expect(PointTransactionType.spent.name, equals('spent'));
    });

    tearDownAll(() {
      // 리소스 정리
      apiService.dispose();
    });
  });
}
