import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:async';
import '../models/call_log.dart';
import '../repositories/alarm_repository.dart';
import '../repositories/mock_alarm_repository.dart';
import '../environment/environment.dart';
import '../../main.dart' show navigateToAlarmScreen;

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
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      onDidReceiveLocalNotification: null, // iOS 10 이하 지원
    );
    
    // iOS 권한 요청
    await _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
      critical: true, // 중요 알림 (방해 금지 모드에서도 울림)
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );
  }
  
  void _onNotificationResponse(NotificationResponse response) {
    // 알림 클릭 시 알람 화면으로 이동하는 로직
    print('🔔 알림 클릭됨: ${response.payload}');
    _handleAlarmNotification(response);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // 백그라운드에서 알림이 왔을 때 자동으로 알람 화면으로 이동
    print('🔔 백그라운드 알림 수신: ${response.payload}');
    _handleAlarmNotificationStatic(response);
  }

  void _handleAlarmNotification(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      // main.dart의 글로벌 네비게이션 함수 호출
      navigateToAlarmScreen(response.payload!);
    } else {
      // payload가 없는 경우 기본 알람 화면으로 이동
      navigateToAlarmScreen('{"alarmType": "일반알람", "title": "알람"}');
    }
  }

  static void _handleAlarmNotificationStatic(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      // main.dart의 글로벌 네비게이션 함수 호출
      navigateToAlarmScreen(response.payload!);
    } else {
      // payload가 없는 경우 기본 알람 화면으로 이동
      navigateToAlarmScreen('{"alarmType": "일반알람", "title": "알람"}');
    }
  }

  Future<void> scheduleAlarm(DateTime scheduledTime, String title, String body, {int? customId, String? alarmType}) async {
    final callId = customId ?? _uuid.v4().hashCode;
    state = state.copyWith(currentCallId: callId);
    
    print('⏰ 알람 스케줄링 시작 - ID: $callId');
    print('📅 예정 시간: $scheduledTime');
    print('🏷️ 제목: $title');
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'aningcall_alarm',
      'AningCall 알람',
      channelDescription: 'AningCall 앱의 알람 채널',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true, // 전체 화면으로 알람 표시
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false, // 자동으로 사라지지 않도록
      ongoing: true, // 지속적인 알림으로 설정
      showProgress: false,
    );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.critical, // 중요 알림으로 변경 (자동으로 화면에 표시)
      threadIdentifier: 'alarm-thread',
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // 알람 정보를 payload로 전달
    final payload = '{"alarmId": $callId, "alarmType": "${alarmType ?? "일반알람"}", "title": "$title"}';

    await _notificationsPlugin.zonedSchedule(
      callId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    
    print('✅ 알림 스케줄링 완료 - ID: $callId, 시간: $scheduledTime, 제목: $title');
    print('🕒 현재 시간과의 차이: ${scheduledTime.difference(DateTime.now()).inSeconds}초 후');
    
    // 스케줄된 알림 목록 확인 (디버깅용)
    final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
    print('📋 대기 중인 알림 개수: ${pendingNotifications.length}');
    
    // 모든 알람에 대해 백그라운드 알림 처리 강화
    final secondsUntilAlarm = scheduledTime.difference(DateTime.now()).inSeconds;
    
    // 즉시 알림인 경우 (60초 이내) 카운트다운 표시
    if (secondsUntilAlarm <= 60) {
      print('⚡ 즉시 알림 설정됨! ${secondsUntilAlarm}초 후 울립니다.');
      
      // 카운트다운 타이머 추가
      Timer.periodic(const Duration(seconds: 1), (timer) {
        final remaining = secondsUntilAlarm - timer.tick;
        if (remaining > 0) {
          print('⏰ 알람까지 ${remaining}초 남음');
        } else {
          timer.cancel();
          print('🔔 알람 시간 도달! 자동으로 알람 화면으로 이동합니다.');
          print('🚀 네비게이션 시도 중...');
          final payload = '{"alarmId": $callId, "alarmType": "${alarmType ?? "일반알람"}", "title": "$title"}';
          
          try {
            navigateToAlarmScreen(payload);
            print('✅ 네비게이션 성공!');
          } catch (e) {
            print('❌ 네비게이션 실패: $e');
          }
        }
      });
    } else {
      // 장기 알람의 경우에도 정확한 시간에 체크하는 타이머 설정
      print('⏰ 장기 알람 설정됨! ${secondsUntilAlarm}초 후 울립니다.');
      
      // 정확한 시간에 알람 체크하는 타이머
      Timer(Duration(seconds: secondsUntilAlarm), () {
        print('🔔 장기 알람 시간 도달! 자동으로 알람 화면으로 이동합니다.');
        print('🚀 네비게이션 시도 중...');
        final payload = '{"alarmId": $callId, "alarmType": "${alarmType ?? "일반알람"}", "title": "$title"}';
        
        try {
          navigateToAlarmScreen(payload);
          print('✅ 네비게이션 성공!');
        } catch (e) {
          print('❌ 네비게이션 실패: $e');
        }
      });
    }
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