import '../models/call_log.dart';

class MockAlarmRepository {
  Future<Map<String, dynamic>> submitAlarmResult({
    required int userId,
    required int callId,
    required String result,
    required int snoozeCount,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock 포인트 계산
    int pointsAwarded = 0;
    if (result == 'SUCCESS') {
      pointsAwarded = 10;
    } else if (result == 'FAIL_SNOOZE') {
      pointsAwarded = 0;
    } else {
      pointsAwarded = 0;
    }

    return {
      'success': true,
      'data': pointsAwarded,
    };
  }

  Future<Map<String, dynamic>> getCallLogs(String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock 호출 로그 데이터
    final mockLogs = [
      CallLog(
        id: 1,
        userId: 1,
        callStart: DateTime.now().subtract(const Duration(hours: 2)),
        callEnd: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
        result: CallResult.success,
        snoozeCount: 0,
      ),
      CallLog(
        id: 2,
        userId: 1,
        callStart: DateTime.now().subtract(const Duration(days: 1)),
        callEnd: DateTime.now().subtract(const Duration(days: 1)).add(const Duration(minutes: 5)),
        result: CallResult.failSnooze,
        snoozeCount: 3,
      ),
    ];

    return {
      'success': true,
      'data': mockLogs,
    };
  }
}