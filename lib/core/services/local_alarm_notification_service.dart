import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/local_alarm.dart';
import 'local_alarm_storage_service.dart';

/// 로컬 알람 알림 스케줄링 서비스
class LocalAlarmNotificationService {
  static LocalAlarmNotificationService? _instance;
  static LocalAlarmNotificationService get instance => 
      _instance ??= LocalAlarmNotificationService._();
  
  LocalAlarmNotificationService._();
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  /// 서비스 초기화
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // 타임존 초기화
      tz.initializeTimeZones();
      
      // Android 설정
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS 설정
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: null,
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      final result = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      
      if (result == true) {
        _isInitialized = true;
        await _requestPermissions();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('알림 서비스 초기화 오류: $e');
      return false;
    }
  }
  
  /// 권한 요청
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      
      // Android 13+ 알림 권한
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        
        // 정확한 알람 권한 (Android 12+)
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestExactAlarmsPermission();
      }
      
      return status == PermissionStatus.granted;
    }
    
    if (Platform.isIOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      return result == true;
    }
    
    return true;
  }
  
  /// 알람 스케줄링
  Future<bool> scheduleAlarm(LocalAlarm alarm) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // 기존 알람 취소
      await cancelAlarm(alarm.id);
      
      if (!alarm.isEnabled) return true;
      
      final nextAlarmTime = alarm.nextAlarmTime;
      if (nextAlarmTime == null) return false;
      
      // 알림 세부 설정
      final androidDetails = AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        channelDescription: 'Channel for alarm notifications',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: alarm.vibrate,
        vibrationPattern: alarm.vibrate ? Int64List.fromList([0, 1000, 500, 1000]) : null,
        sound: alarm.soundPath != null 
            ? RawResourceAndroidNotificationSound(alarm.soundPath!)
            : null,
        actions: alarm.snoozeEnabled ? [
          const AndroidNotificationAction(
            'snooze',
            'Snooze',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'dismiss',
            'Dismiss',
            cancelNotification: true,
          ),
        ] : [
          const AndroidNotificationAction(
            'dismiss',
            'Dismiss',
            cancelNotification: true,
          ),
        ],
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // payload에 alarmType 포함
      final payload = '{"alarmId": "${alarm.id}", "alarmType": "${alarm.type ?? "일반알람"}", "title": "${alarm.title}"}';
      
      // 알림 스케줄링
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        alarm.id,
        alarm.title,
        alarm.label ?? '알람이 울렸습니다',
        tz.TZDateTime.from(nextAlarmTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      // 반복 알람인 경우 다음 스케줄도 예약
      if (alarm.repeatDays.isNotEmpty) {
        await _scheduleRepeatingAlarm(alarm);
      }
      
      debugPrint('알람 스케줄링 완료: ${alarm.title} at ${nextAlarmTime}');
      return true;
    } catch (e) {
      debugPrint('알람 스케줄링 오류: $e');
      return false;
    }
  }
  
  /// 반복 알람 스케줄링
  Future<void> _scheduleRepeatingAlarm(LocalAlarm alarm) async {
    // 다음 7일간의 알람 시간 계산하여 각각 스케줄링
    final now = DateTime.now();
    
    for (int i = 1; i <= 7; i++) {
      final checkDate = DateTime(now.year, now.month, now.day + i, alarm.hour, alarm.minute);
      final weekday = checkDate.weekday % 7;
      
      if (alarm.repeatDays.contains(weekday)) {
        final notificationId = alarm.id + i * 1000;
        
        final androidDetails = AndroidNotificationDetails(
          'alarm_channel',
          'Alarm Notifications',
          channelDescription: 'Channel for alarm notifications',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          enableVibration: alarm.vibrate,
          vibrationPattern: alarm.vibrate ? Int64List.fromList([0, 1000, 500, 1000]) : null,
        );
        
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        );
        
        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );
        
        // payload에 alarmType 포함
        final payload = '{"alarmId": "${alarm.id}", "alarmType": "${alarm.type ?? "일반알람"}", "title": "${alarm.title}"}';
        
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          alarm.title,
          alarm.label ?? '알람이 울렸습니다',
          tz.TZDateTime.from(checkDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      }
    }
  }
  
  /// 알람 취소
  Future<bool> cancelAlarm(int alarmId) async {
    try {
      final notificationId = alarmId;
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      
      // 반복 알람의 경우 추가 스케줄도 취소
      for (int i = 1; i <= 7; i++) {
        await _flutterLocalNotificationsPlugin.cancel(notificationId + i * 1000);
      }
      
      debugPrint('알람 취소 완료: $alarmId');
      return true;
    } catch (e) {
      debugPrint('알람 취소 오류: $e');
      return false;
    }
  }
  
  /// 모든 알람 취소
  Future<bool> cancelAllAlarms() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('모든 알람 취소 완료');
      return true;
    } catch (e) {
      debugPrint('모든 알람 취소 오류: $e');
      return false;
    }
  }
  
  /// 저장된 모든 알람 다시 스케줄링
  Future<bool> rescheduleAllAlarms() async {
    try {
      final storageService = LocalAlarmStorageService.instance;
      final enabledAlarms = await storageService.getEnabledAlarms();
      
      // 기존 알람 모두 취소
      await cancelAllAlarms();
      
      // 활성화된 알람들 다시 스케줄링
      for (final alarm in enabledAlarms) {
        await scheduleAlarm(alarm);
      }
      
      debugPrint('모든 알람 재스케줄링 완료: ${enabledAlarms.length}개');
      return true;
    } catch (e) {
      debugPrint('알람 재스케줄링 오류: $e');
      return false;
    }
  }
  
  /// 스누즈 기능
  Future<bool> snoozeAlarm(int alarmId, int snoozeMinutes) async {
    try {
      final storageService = LocalAlarmStorageService.instance;
      final alarm = await storageService.getAlarmById(alarmId);
      
      if (alarm == null) return false;
      
      // 현재 알람 취소
      await cancelAlarm(alarmId);
      
      // 스누즈 시간 후 다시 알람 설정
      final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
      
      final androidDetails = AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        channelDescription: 'Channel for alarm notifications',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: alarm.vibrate,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // payload에 alarmType 포함
      final payload = '{"alarmId": "$alarmId", "alarmType": "${alarm.type ?? "일반알람"}", "title": "${alarm.title}"}';
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        alarmId + 10000, // 스누즈용 ID
        '${alarm.title} (스누즈)',
        alarm.label ?? '알람이 울렸습니다',
        tz.TZDateTime.from(snoozeTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      // 원래 알람 다시 스케줄링 (반복 알람인 경우)
      if (alarm.repeatDays.isNotEmpty) {
        await scheduleAlarm(alarm);
      }
      
      debugPrint('스누즈 설정 완료: ${alarm.title} - ${snoozeMinutes}분 후');
      return true;
    } catch (e) {
      debugPrint('스누즈 설정 오류: $e');
      return false;
    }
  }
  
  /// 예약된 알림 목록 조회 (디버깅용)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
  
  /// 알림 응답 처리
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('알림 응답 수신: ${response.actionId}, payload: $payload');
    
    if (response.actionId == 'snooze' && payload != null) {
      // 스누즈 처리
      final payloadData = jsonDecode(payload);
      final alarmId = payloadData['alarmId'] as int;
      snoozeAlarm(alarmId, 5); // 5분 스누즈
    } else if (response.actionId == 'dismiss' && payload != null) {
      // 알람 해제 처리
      final payloadData = jsonDecode(payload);
      final alarmId = payloadData['alarmId'] as int;
      cancelAlarm(alarmId);
    } else if (payload != null) {
      // 알람 탭 처리 - 알람 화면으로 이동
      _handleAlarmTap(payload);
    }
  }
  
  /// 알람 탭 처리
  void _handleAlarmTap(String alarmId) {
    // 알람 화면으로 이동하는 로직
    // 이 부분은 앱의 네비게이션 구조에 맞게 구현
    debugPrint('알람 탭됨: $alarmId');
    
    // 예시: 글로벌 네비게이터를 통한 화면 이동
    // navigatorKey.currentState?.pushNamed('/alarm_ring', arguments: alarmId);
  }
  
  /// 알림 채널 생성 (Android)
  Future<void> createNotificationChannel() async {
    if (Platform.isAndroid) {
      const androidNotificationChannel = AndroidNotificationChannel(
        'alarm_channel',
        'Alarm Notifications',
        description: 'Channel for alarm notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidNotificationChannel);
    }
  }
}
