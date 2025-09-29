import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../repositories/alarm_repository.dart';
import '../repositories/mock_alarm_repository.dart';
import '../models/alarm.dart';
import '../environment/environment.dart';

// Dio Provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.baseUrl = EnvironmentConfig.baseUrl;
  dio.options.connectTimeout = Duration(seconds: EnvironmentConfig.timeout);
  dio.options.receiveTimeout = Duration(seconds: EnvironmentConfig.timeout);

  // Request/Response 로깅 (Development 환경에서만)
  if (EnvironmentConfig.isDevelopment) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => print('[DIO] $object'),
    ));
  }

  return dio;
});

// Repository Interface 통일을 위한 Abstract Class
abstract class AlarmRepositoryInterface {
  Future<List<Alarm>> getAllAlarms();
  Future<Alarm?> getAlarm(int id);
  Future<Alarm> createAlarm(Alarm alarm);
  Future<Alarm> updateAlarm(Alarm alarm);
  Future<void> deleteAlarm(int id);
  Future<void> toggleAlarm(int id, bool isEnabled);
}

// Mock Repository Wrapper
class MockAlarmRepositoryWrapper implements AlarmRepositoryInterface {
  final MockAlarmRepository _mockRepository = MockAlarmRepository();

  @override
  Future<List<Alarm>> getAllAlarms() => _mockRepository.getAllAlarms();

  @override
  Future<Alarm?> getAlarm(int id) => _mockRepository.getAlarm(id);

  @override
  Future<Alarm> createAlarm(Alarm alarm) => _mockRepository.createAlarm(alarm);

  @override
  Future<Alarm> updateAlarm(Alarm alarm) => _mockRepository.updateAlarm(alarm);

  @override
  Future<void> deleteAlarm(int id) => _mockRepository.deleteAlarm(id);

  @override
  Future<void> toggleAlarm(int id, bool isEnabled) =>
      _mockRepository.toggleAlarm(id, isEnabled);
}

// Real Repository Wrapper
class AlarmRepositoryWrapper implements AlarmRepositoryInterface {
  final AlarmRepository _alarmRepository;

  AlarmRepositoryWrapper(this._alarmRepository);

  @override
  Future<List<Alarm>> getAllAlarms() => _alarmRepository.getAllAlarms();

  @override
  Future<Alarm?> getAlarm(int id) => _alarmRepository.getAlarm(id);

  @override
  Future<Alarm> createAlarm(Alarm alarm) => _alarmRepository.createAlarm(alarm);

  @override
  Future<Alarm> updateAlarm(Alarm alarm) => _alarmRepository.updateAlarm(alarm);

  @override
  Future<void> deleteAlarm(int id) => _alarmRepository.deleteAlarm(id);

  @override
  Future<void> toggleAlarm(int id, bool isEnabled) =>
      _alarmRepository.toggleAlarm(id, isEnabled);
}

// AlarmRepository Provider (환경에 따라 자동 선택)
final alarmRepositoryProvider = Provider<AlarmRepositoryInterface>((ref) {
  if (EnvironmentConfig.isDevelopment) {
    // Development: Mock Repository 사용
    return MockAlarmRepositoryWrapper();
  } else {
    // Production: Real API Repository 사용
    final dio = ref.read(dioProvider);
    return AlarmRepositoryWrapper(AlarmRepository(dio: dio));
  }
});