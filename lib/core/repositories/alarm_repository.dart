import 'package:dio/dio.dart';
import '../models/call_log.dart';
import '../environment/environment.dart';

class AlarmRepository {
  final Dio _dio;

  AlarmRepository({required Dio dio}) : _dio = dio;

  Future<Map<String, dynamic>> submitAlarmResult({
    required int userId,
    required int callId,
    required String result,
    required int snoozeCount,
  }) async {
    try {
      final response = await _dio.post(
        '${EnvironmentConfig.baseUrl}/alarms/result',
        data: {
          'userId': userId,
          'callId': callId,
          'result': result,
          'snoozeCount': snoozeCount,
        },
      );

      return {
        'success': true,
        'data': response.data['pointsAwarded'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'code': e.response?.data['code'],
        'message': e.response?.data['message'],
      };
    }
  }

  Future<Map<String, dynamic>> getCallLogs(String token) async {
    try {
      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/alarms/logs',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final List<dynamic> logs = response.data['data'];
      final callLogs = logs.map((json) => CallLog.fromJson(json)).toList();

      return {
        'success': true,
        'data': callLogs,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'code': e.response?.data['code'],
        'message': e.response?.data['message'],
      };
    }
  }
}