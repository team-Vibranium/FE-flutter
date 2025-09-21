import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/call_log.dart';
import '../repositories/alarm_repository.dart';
import '../repositories/mock_alarm_repository.dart';
import '../environment/environment.dart';

final alarmRepositoryProvider = Provider<dynamic>((ref) {
  if (EnvironmentConfig.isDevelopment) {
    return MockAlarmRepository();
  } else {
    return AlarmRepository(dio: Dio());
  }
});

final alarmStateProvider = StateNotifierProvider<AlarmNotifier, AlarmState>((ref) {
  return AlarmNotifier(ref.read(alarmRepositoryProvider));
});

class AlarmState {
  final List<CallLog> callLogs;
  final bool isLoading;
  final String? error;
  final int? currentCallId;

  const AlarmState({
    this.callLogs = const [],
    this.isLoading = false,
    this.error,
    this.currentCallId,
  });

  AlarmState copyWith({
    List<CallLog>? callLogs,
    bool? isLoading,
    String? error,
    int? currentCallId,
  }) {
    return AlarmState(
      callLogs: callLogs ?? this.callLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentCallId: currentCallId ?? this.currentCallId,
    );
  }
}

class AlarmNotifier extends StateNotifier<AlarmState> {
  final dynamic _alarmRepository;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final Uuid _uuid = const Uuid();

  AlarmNotifier(this._alarmRepository) : super(const AlarmState()) {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // timezone 초기화
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleAlarm(DateTime scheduledTime, String title, String body) async {
    final callId = _uuid.v4().hashCode;
    state = state.copyWith(currentCallId: callId);
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'aningcall_alarm',
      'AningCall 알람',
      channelDescription: 'AningCall 앱의 알람 채널',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.zonedSchedule(
      callId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAlarm(int notificationId) async {
    await _notificationsPlugin.cancel(notificationId);
  }

  Future<void> cancelAllAlarms() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> submitAlarmResult({
    required int userId,
    required String result,
    required int snoozeCount,
  }) async {
    if (state.currentCallId == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _alarmRepository.submitAlarmResult(
        userId: userId,
        callId: state.currentCallId!,
        result: result,
        snoozeCount: snoozeCount,
      );
      
      if (response['success']) {
        // 성공적으로 제출됨
        state = state.copyWith(
          isLoading: false,
          currentCallId: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? '알람 결과 제출에 실패했습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadCallLogs(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _alarmRepository.getCallLogs(token);
      
      if (response['success'] && response['data'] != null) {
        state = state.copyWith(
          callLogs: response['data'],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? '호출 로그를 불러오는데 실패했습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}