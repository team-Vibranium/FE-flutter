import 'package:dio/dio.dart';
import '../models/call_log.dart';
import '../models/alarm.dart';
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

  // 알람 CRUD 기능들
  Future<List<Alarm>> getAllAlarms() async {
    try {
      final response = await _dio.get('${EnvironmentConfig.baseUrl}/alarms');
      final List<dynamic> alarmsList = response.data['data'];
      return alarmsList.map((json) => Alarm.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to get alarms: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<Alarm?> getAlarm(int id) async {
    try {
      final response = await _dio.get('${EnvironmentConfig.baseUrl}/alarms/$id');
      return Alarm.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to get alarm: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<Alarm> createAlarm(Alarm alarm) async {
    try {
      final response = await _dio.post(
        '${EnvironmentConfig.baseUrl}/alarms',
        data: alarm.toJson(),
      );
      return Alarm.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception('Failed to create alarm: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<Alarm> updateAlarm(Alarm alarm) async {
    try {
      final response = await _dio.put(
        '${EnvironmentConfig.baseUrl}/alarms/${alarm.id}',
        data: alarm.toJson(),
      );
      return Alarm.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception('Failed to update alarm: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<void> deleteAlarm(int id) async {
    try {
      await _dio.delete('${EnvironmentConfig.baseUrl}/alarms/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete alarm: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<void> toggleAlarm(int id, bool isEnabled) async {
    try {
      await _dio.patch(
        '${EnvironmentConfig.baseUrl}/alarms/$id',
        data: {'isEnabled': isEnabled},
      );
    } on DioException catch (e) {
      throw Exception('Failed to toggle alarm: ${e.response?.data['message'] ?? e.message}');
    }
  }
}