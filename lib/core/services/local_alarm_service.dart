import 'package:uuid/uuid.dart';
import '../models/local_alarm.dart';
import 'local_alarm_storage_service.dart';
import 'local_alarm_notification_service.dart';

/// 로컬 알람 통합 관리 서비스
class LocalAlarmService {
  static LocalAlarmService? _instance;
  static LocalAlarmService get instance => _instance ??= LocalAlarmService._();
  
  LocalAlarmService._();
  
  final LocalAlarmStorageService _storageService = LocalAlarmStorageService.instance;
  final LocalAlarmNotificationService _notificationService = LocalAlarmNotificationService.instance;
  final Uuid _uuid = const Uuid();
  
  bool _isInitialized = false;
  
  /// 서비스 초기화
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // 저장소 서비스 초기화
      await _storageService.initialize();
      
      // 알림 서비스 초기화
      final notificationResult = await _notificationService.initialize();
      if (!notificationResult) {
        return false;
      }
      
      // 알림 채널 생성
      await _notificationService.createNotificationChannel();
      
      // 기존 알람들 재스케줄링
      await _notificationService.rescheduleAllAlarms();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 새 알람 생성
  Future<LocalAlarm?> createAlarm({
    required String title,
    required int hour,
    required int minute,
    List<int> repeatDays = const [],
    String? soundPath,
    bool vibrate = true,
    bool snoozeEnabled = true,
    int snoozeInterval = 5,
    String? label,
    bool isEnabled = true,
    String? type,
    int? backendAlarmId, // 백엔드 알람 ID 추가
  }) async {
    try {
      final now = DateTime.now();
      final alarm = LocalAlarm(
        id: DateTime.now().millisecondsSinceEpoch % 1000000,
        title: title,
        hour: hour,
        minute: minute,
        isEnabled: isEnabled,
        repeatDays: repeatDays,
        soundPath: soundPath,
        vibrate: vibrate,
        snoozeEnabled: snoozeEnabled,
        snoozeInterval: snoozeInterval,
        createdAt: now,
        updatedAt: now,
        label: label,
        type: type,
        backendAlarmId: backendAlarmId,
      );

      
      // 저장소에 저장
      final saveResult = await _storageService.saveAlarm(alarm);
      if (!saveResult) {
        return null;
      }
      
      // 알림 스케줄링
      if (isEnabled) {
        final scheduleResult = await _notificationService.scheduleAlarm(alarm);
        if (!scheduleResult) {
          // 저장은 되었지만 스케줄링 실패 시에도 알람 객체 반환
        }
      }
      
      return alarm;
    } catch (e) {
      return null;
    }
  }
  
  /// 알람 수정
  Future<bool> updateAlarm(LocalAlarm updatedAlarm) async {
    try {
      // 저장소 업데이트
      final saveResult = await _storageService.saveAlarm(updatedAlarm);
      if (!saveResult) return false;
      
      // 알림 재스케줄링
      await _notificationService.cancelAlarm(updatedAlarm.id);
      if (updatedAlarm.isEnabled) {
        await _notificationService.scheduleAlarm(updatedAlarm);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 알람 삭제
  Future<bool> deleteAlarm(int alarmId) async {
    try {
      // 알림 취소
      await _notificationService.cancelAlarm(alarmId);
      
      // 저장소에서 삭제
      final deleteResult = await _storageService.deleteAlarm(alarmId);
      if (!deleteResult) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 알람 활성화/비활성화
  Future<bool> toggleAlarm(int alarmId, bool isEnabled) async {
    try {
      // 저장소 업데이트
      final toggleResult = await _storageService.toggleAlarm(alarmId, isEnabled);
      if (!toggleResult) return false;
      
      // 알림 스케줄링 업데이트
      await _notificationService.cancelAlarm(alarmId);
      
      if (isEnabled) {
        final alarm = await _storageService.getAlarmById(alarmId);
        if (alarm != null) {
          await _notificationService.scheduleAlarm(alarm);
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 모든 알람 조회
  Future<List<LocalAlarm>> getAllAlarms() async {
    return await _storageService.getAllAlarms();
  }
  
  /// 활성화된 알람만 조회
  Future<List<LocalAlarm>> getEnabledAlarms() async {
    return await _storageService.getEnabledAlarms();
  }
  
  /// ID로 알람 조회
  Future<LocalAlarm?> getAlarmById(int id) async {
    return await _storageService.getAlarmById(id);
  }
  
  /// 다음 알람 시간 조회
  Future<DateTime?> getNextAlarmTime() async {
    return await _storageService.getNextAlarmTime();
  }
  
  /// 스누즈 기능
  Future<bool> snoozeAlarm(int alarmId, {int? customMinutes}) async {
    try {
      final alarm = await _storageService.getAlarmById(alarmId);
      if (alarm == null) return false;
      
      final snoozeMinutes = customMinutes ?? alarm.snoozeInterval;
      final result = await _notificationService.snoozeAlarm(alarmId, snoozeMinutes);
      
      if (result) {
      }
      
      return result;
    } catch (e) {
      return false;
    }
  }
  
  /// 모든 알람 삭제
  Future<bool> clearAllAlarms() async {
    try {
      // 모든 알림 취소
      await _notificationService.cancelAllAlarms();
      
      // 저장소 비우기
      final clearResult = await _storageService.clearAllAlarms();
      
      if (clearResult) {
      }
      
      return clearResult;
    } catch (e) {
      // Debug: 모든 알람 삭제 오류: $e
      return false;
    }
  }
  
  /// 알람 통계 조회
  Future<Map<String, dynamic>> getAlarmStatistics() async {
    try {
      final allAlarms = await getAllAlarms();
      final enabledAlarms = await getEnabledAlarms();
      final nextAlarmTime = await getNextAlarmTime();
      final hourCount = await _storageService.getAlarmCountByHour();
      final dayCount = await _storageService.getAlarmCountByWeekday();
      
      return {
        'totalAlarms': allAlarms.length,
        'enabledAlarms': enabledAlarms.length,
        'disabledAlarms': allAlarms.length - enabledAlarms.length,
        'nextAlarmTime': nextAlarmTime?.toIso8601String(),
        'alarmsByHour': hourCount,
        'alarmsByWeekday': dayCount,
        'hasActiveAlarms': enabledAlarms.isNotEmpty,
      };
    } catch (e) {
      // Debug: 알람 통계 조회 오류: $e
      return {};
    }
  }
  
  /// 알람 데이터 백업
  Future<String?> exportAlarms() async {
    return await _storageService.exportAlarmsData();
  }
  
  /// 알람 데이터 복원
  Future<bool> importAlarms(String jsonData) async {
    try {
      // 기존 알람 모두 삭제
      await clearAllAlarms();
      
      // 새 데이터 가져오기
      final importResult = await _storageService.importAlarmsData(jsonData);
      if (!importResult) return false;
      
      // 모든 알람 재스케줄링
      await _notificationService.rescheduleAllAlarms();
      
      // Debug: 알람 데이터 복원 완료
      return true;
    } catch (e) {
      // Debug: 알람 데이터 복원 오류: $e
      return false;
    }
  }
  
  /// 시스템 재시작 후 알람 복구
  Future<bool> restoreAlarmsAfterReboot() async {
    try {
      // Debug: 시스템 재시작 후 알람 복구 시작
      
      // 모든 활성화된 알람 재스케줄링
      final result = await _notificationService.rescheduleAllAlarms();
      
      if (result) {
        // Debug: 알람 복구 완료
      } else {
        // Debug: 알람 복구 실패
      }
      
      return result;
    } catch (e) {
      // Debug: 알람 복구 오류: $e
      return false;
    }
  }
  
  /// 디버깅용 - 예약된 알림 목록 조회
  Future<List<dynamic>> getScheduledNotifications() async {
    final notifications = await _notificationService.getPendingNotifications();
    return notifications.map((n) => {
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'payload': n.payload,
    }).toList();
  }
  
  /// 앱 시작 시 호출할 초기화 메서드
  static Future<bool> initializeOnAppStart() async {
    try {
      final service = LocalAlarmService.instance;
      final result = await service.initialize();
      
      if (result) {
        // 앱이 재시작된 경우 알람 복구
        await service.restoreAlarmsAfterReboot();
      }
      
      return result;
    } catch (e) {
      // Debug: 앱 시작 시 알람 서비스 초기화 오류: $e
      return false;
    }
  }
}
