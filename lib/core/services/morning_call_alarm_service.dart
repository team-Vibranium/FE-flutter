import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'gpt_realtime_service.dart';

/// 모닝콜 전용 알람 서비스
/// GPT Realtime API와 연동하여 양방향 음성 대화 모닝콜 제공
class MorningCallAlarmService {
  static final MorningCallAlarmService _instance = MorningCallAlarmService._internal();
  factory MorningCallAlarmService() => _instance;
  MorningCallAlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final GPTRealtimeService _gptService = GPTRealtimeService();
  
  bool _isInitialized = false;
  String? _gptApiKey;
  String _userName = '예훈'; // 기본 사용자 이름

  /// 서비스 초기화
  Future<void> initialize({
    required String gptApiKey,
    String? userName,
  }) async {
    if (_isInitialized) return;

    _gptApiKey = gptApiKey;
    if (userName != null) _userName = userName;

    // 알림 권한 요청
    await _requestNotificationPermissions();
    
    // 로컬 알림 초기화
    await _initializeNotifications();
    
    // GPT 서비스 초기화 (API 키가 있는 경우에만)
    if (gptApiKey.isNotEmpty) {
      try {
        await _gptService.initialize(gptApiKey);
        // GPT 서비스 콜백 설정
        _setupGPTCallbacks();
        print('🤖 GPT 서비스 초기화 완료');
      } catch (e) {
        print('⚠️ GPT 서비스 초기화 실패: $e (기본 알람 기능은 사용 가능)');
      }
    } else {
      print('⚠️ GPT API 키가 없습니다. 기본 알람 기능만 사용 가능합니다.');
    }
    
    _isInitialized = true;
    print('🌅 모닝콜 알람 서비스 초기화 완료');
  }

  /// 알림 권한 요청
  Future<void> _requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    if (status != PermissionStatus.granted) {
      throw Exception('알림 권한이 필요합니다');
    }
  }

  /// 로컬 알림 초기화
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null) {
      try {
        final alarmData = jsonDecode(payload) as Map<String, dynamic>;
        final alarmTitle = alarmData['title'] as String;
        
        print('🔔 모닝콜 알람 트리거: $alarmTitle');
        
        // 모닝콜 시작
        await startMorningCall(alarmTitle: alarmTitle);
        
      } catch (e) {
        print('❌ 알림 처리 오류: $e');
      }
    }
  }

  /// GPT 서비스 콜백 설정
  void _setupGPTCallbacks() {
    _gptService.onMessageReceived = (message) {
      print('🤖 GPT 메시지: $message');
      // UI 업데이트나 로깅 등
    };

    _gptService.onError = (error) {
      print('❌ GPT 오류: $error');
      // 오류 처리 로직
    };

    _gptService.onCallStarted = () {
      print('📞 모닝콜 시작됨');
      // UI 상태 업데이트
    };

    _gptService.onCallEnded = () {
      print('📞 모닝콜 종료됨');
      // UI 상태 업데이트
    };

    _gptService.onRemoteStream = (stream) {
      print('🔊 GPT 음성 스트림 수신');
      // 오디오 스트림 처리
    };
  }

  /// 모닝콜 알람 예약
  Future<int> scheduleMorningCallAlarm({
    required String title,
    required DateTime scheduledTime,
    List<int>? repeatDays, // 1=월요일, 7=일요일
    String? description,
  }) async {
    if (!_isInitialized) {
      throw Exception('서비스가 초기화되지 않았습니다');
    }

    final alarmId = DateTime.now().millisecondsSinceEpoch;
    
    // 알람 데이터 저장
    await _saveAlarmData(alarmId, {
      'id': alarmId,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'repeatDays': repeatDays,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // 로컬 알림 예약
    await _scheduleNotification(
      alarmId,
      title,
      description ?? '모닝콜 알람이 울렸습니다',
      scheduledTime,
      repeatDays,
    );

    print('⏰ 모닝콜 알람 예약됨: $title at ${scheduledTime.toString()}');
    return alarmId;
  }

  /// 로컬 알림 예약
  Future<void> _scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    List<int>? repeatDays,
  ) async {
    final payload = jsonEncode({
      'id': id,
      'title': title,
      'type': 'morning_call',
    });

    if (repeatDays != null && repeatDays.isNotEmpty) {
      // 반복 알람
      for (final day in repeatDays) {
        await _notifications.zonedSchedule(
          id + day, // 각 요일별로 고유 ID
          title,
          body,
          _nextInstanceOfWeekday(scheduledTime, day),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'morning_call_channel',
              '모닝콜 알람',
              channelDescription: 'GPT와 함께하는 모닝콜 알람',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              enableVibration: true,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('alarm_sound'),
            ),
            iOS: DarwinNotificationDetails(
              sound: 'alarm_sound.wav',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: payload,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } else {
      // 일회성 알람
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'morning_call_channel',
            '모닝콜 알람',
            channelDescription: 'GPT와 함께하는 모닝콜 알람',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alarm_sound'),
          ),
          iOS: DarwinNotificationDetails(
            sound: 'alarm_sound.wav',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// 다음 요일 계산
  tz.TZDateTime _nextInstanceOfWeekday(DateTime scheduledTime, int weekday) {
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// 알람 데이터 저장
  Future<void> _saveAlarmData(int alarmId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmKey = 'morning_call_alarm_$alarmId';
    await prefs.setString(alarmKey, jsonEncode(data));
  }

  /// 알람 데이터 로드
  Future<Map<String, dynamic>?> _loadAlarmData(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmKey = 'morning_call_alarm_$alarmId';
    final dataString = prefs.getString(alarmKey);
    
    if (dataString != null) {
      return jsonDecode(dataString) as Map<String, dynamic>;
    }
    return null;
  }

  /// 모든 알람 조회
  Future<List<Map<String, dynamic>>> getAllAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('morning_call_alarm_'));
    
    final alarms = <Map<String, dynamic>>[];
    for (final key in keys) {
      final dataString = prefs.getString(key);
      if (dataString != null) {
        alarms.add(jsonDecode(dataString) as Map<String, dynamic>);
      }
    }
    
    // 시간순 정렬
    alarms.sort((a, b) {
      final timeA = DateTime.parse(a['scheduledTime'] as String);
      final timeB = DateTime.parse(b['scheduledTime'] as String);
      return timeA.compareTo(timeB);
    });
    
    return alarms;
  }

  /// 알람 삭제
  Future<void> deleteAlarm(int alarmId) async {
    // 로컬 알림 취소
    await _notifications.cancel(alarmId);
    
    // 반복 알람인 경우 모든 요일 취소
    for (int day = 1; day <= 7; day++) {
      await _notifications.cancel(alarmId + day);
    }
    
    // 저장된 데이터 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('morning_call_alarm_$alarmId');
    
    print('🗑️ 모닝콜 알람 삭제됨: $alarmId');
  }

  /// 모닝콜 시작 (수동 또는 알람 트리거)
  Future<void> startMorningCall({
    required String alarmTitle,
    String? customUserName,
  }) async {
    if (!_isInitialized) {
      throw Exception('서비스가 초기화되지 않았습니다');
    }

    final userName = customUserName ?? _userName;
    
    try {
      print('🌅 모닝콜 시작: $alarmTitle for $userName');
      
      await _gptService.startMorningCall(
        alarmTitle: alarmTitle,
        userName: userName,
      );
      
    } catch (e) {
      print('❌ 모닝콜 시작 실패: $e');
      rethrow;
    }
  }

  /// 모닝콜 종료
  Future<void> endMorningCall() async {
    await _gptService.endMorningCall();
  }

  /// 현재 모닝콜 상태
  bool get isMorningCallActive => _gptService.isCallActive;

  /// GPT 연결 상태
  bool get isGPTConnected => _gptService.isConnected;

  /// 사용자 이름 설정
  void setUserName(String userName) {
    _userName = userName;
  }

  /// 사용자 이름 조회
  String get userName => _userName;

  /// 테스트용 즉시 모닝콜
  Future<void> testMorningCall({String? testTitle}) async {
    final title = testTitle ?? '테스트 모닝콜';
    await startMorningCall(alarmTitle: title);
  }

  /// 초기화 상태 확인
  bool get isInitialized => _isInitialized;

  /// 서비스 정리
  void dispose() {
    _gptService.dispose();
    _isInitialized = false;
  }
}
