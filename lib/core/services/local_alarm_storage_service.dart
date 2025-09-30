import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_alarm.dart';

/// 로컬 알람 데이터 저장/관리 서비스
class LocalAlarmStorageService {
  static const String _alarmsKey = 'local_alarms';
  static const String _lastAlarmIdKey = 'last_alarm_id';
  
  static LocalAlarmStorageService? _instance;
  static LocalAlarmStorageService get instance => _instance ??= LocalAlarmStorageService._();
  
  LocalAlarmStorageService._();
  
  SharedPreferences? _prefs;
  
  /// SharedPreferences 초기화
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// 모든 알람 조회
  Future<List<LocalAlarm>> getAllAlarms() async {
    await initialize();

    final alarmsJson = _prefs!.getString(_alarmsKey);
    if (alarmsJson == null) {
      print('📖 저장된 알람 없음');
      return [];
    }

    try {
      print('📖 알람 데이터 로드 시작');
      print('📖 JSON 원본: ${alarmsJson.substring(0, alarmsJson.length > 200 ? 200 : alarmsJson.length)}...');

      final List<dynamic> alarmsList = jsonDecode(alarmsJson);
      final alarms = alarmsList
          .map((json) => LocalAlarm.fromJson(json))
          .toList();

      print('📖 로드된 알람 (${alarms.length}개):');
      for (final alarm in alarms) {
        print('  - ID: ${alarm.id}, type: ${alarm.type}, backendAlarmId: ${alarm.backendAlarmId}');
      }

      return alarms;
    } catch (e) {
      print('알람 데이터 로드 오류: $e');
      return [];
    }
  }
  
  /// 활성화된 알람만 조회
  Future<List<LocalAlarm>> getEnabledAlarms() async {
    final allAlarms = await getAllAlarms();
    return allAlarms.where((alarm) => alarm.isEnabled).toList();
  }
  
  /// ID로 알람 조회
  Future<LocalAlarm?> getAlarmById(int id) async {
    final allAlarms = await getAllAlarms();
    try {
      final alarm = allAlarms.firstWhere((alarm) => alarm.id == id);
      print('📖 알람 조회: id=$id, type=${alarm.type}, backendAlarmId=${alarm.backendAlarmId}');
      return alarm;
    } catch (e) {
      print('📖 알람 조회 실패: id=$id');
      return null;
    }
  }
  
  /// 알람 저장 (새로 추가 또는 업데이트)
  Future<bool> saveAlarm(LocalAlarm alarm) async {
    try {
      print('💾 알람 저장 시작:');
      print('  - alarm.id: ${alarm.id}');
      print('  - alarm.type: ${alarm.type}');
      print('  - alarm.backendAlarmId: ${alarm.backendAlarmId}');
      print('  - alarm.title: ${alarm.title}');

      final allAlarms = await getAllAlarms();
      final index = allAlarms.indexWhere((a) => a.id == alarm.id);

      if (index >= 0) {
        // 기존 알람 업데이트
        allAlarms[index] = alarm.copyWith(updatedAt: DateTime.now());
        print('  - 기존 알람 업데이트');
      } else {
        // 새 알람 추가
        allAlarms.add(alarm);
        print('  - 새 알람 추가');
      }

      return await _saveAllAlarms(allAlarms);
    } catch (e) {
      print('알람 저장 오류: $e');
      return false;
    }
  }
  
  /// 여러 알람 한번에 저장
  Future<bool> saveAlarms(List<LocalAlarm> alarms) async {
    try {
      return await _saveAllAlarms(alarms);
    } catch (e) {
      print('알람 목록 저장 오류: $e');
      return false;
    }
  }
  
  /// 알람 삭제
  Future<bool> deleteAlarm(int id) async {
    try {
      final allAlarms = await getAllAlarms();
      allAlarms.removeWhere((alarm) => alarm.id == id);
      return await _saveAllAlarms(allAlarms);
    } catch (e) {
      print('알람 삭제 오류: $e');
      return false;
    }
  }
  
  /// 알람 활성화/비활성화
  Future<bool> toggleAlarm(int id, bool isEnabled) async {
    try {
      final alarm = await getAlarmById(id);
      if (alarm == null) return false;
      
      final updatedAlarm = alarm.copyWith(
        isEnabled: isEnabled,
        updatedAt: DateTime.now(),
      );
      
      return await saveAlarm(updatedAlarm);
    } catch (e) {
      print('알람 토글 오류: $e');
      return false;
    }
  }
  
  /// 모든 알람 삭제
  Future<bool> clearAllAlarms() async {
    try {
      await initialize();
      await _prefs!.remove(_alarmsKey);
      await _prefs!.remove(_lastAlarmIdKey);
      return true;
    } catch (e) {
      print('모든 알람 삭제 오류: $e');
      return false;
    }
  }
  
  /// 다음 알람 시간 조회
  Future<DateTime?> getNextAlarmTime() async {
    final enabledAlarms = await getEnabledAlarms();
    if (enabledAlarms.isEmpty) return null;
    
    DateTime? nextTime;
    
    for (final alarm in enabledAlarms) {
      final alarmNextTime = alarm.nextAlarmTime;
      if (alarmNextTime != null) {
        if (nextTime == null || alarmNextTime.isBefore(nextTime)) {
          nextTime = alarmNextTime;
        }
      }
    }
    
    return nextTime;
  }
  
  /// 고유 알람 ID 생성
  Future<String> generateAlarmId() async {
    await initialize();
    
    final lastId = _prefs!.getInt(_lastAlarmIdKey) ?? 0;
    final newId = lastId + 1;
    await _prefs!.setInt(_lastAlarmIdKey, newId);
    
    return 'alarm_$newId';
  }
  
  /// 시간대별 알람 개수 조회 (통계용)
  Future<Map<int, int>> getAlarmCountByHour() async {
    final allAlarms = await getAllAlarms();
    final Map<int, int> hourCount = {};
    
    for (final alarm in allAlarms) {
      if (alarm.isEnabled) {
        hourCount[alarm.hour] = (hourCount[alarm.hour] ?? 0) + 1;
      }
    }
    
    return hourCount;
  }
  
  /// 요일별 알람 개수 조회 (통계용)
  Future<Map<int, int>> getAlarmCountByWeekday() async {
    final allAlarms = await getAllAlarms();
    final Map<int, int> dayCount = {};
    
    for (final alarm in allAlarms) {
      if (alarm.isEnabled) {
        if (alarm.repeatDays.isEmpty) {
          // 한번만 울리는 알람은 모든 요일에 카운트
          for (int i = 0; i < 7; i++) {
            dayCount[i] = (dayCount[i] ?? 0) + 1;
          }
        } else {
          // 반복 알람은 해당 요일에만 카운트
          for (final day in alarm.repeatDays) {
            dayCount[day] = (dayCount[day] ?? 0) + 1;
          }
        }
      }
    }
    
    return dayCount;
  }
  
  /// 내부 메서드: 모든 알람을 SharedPreferences에 저장
  Future<bool> _saveAllAlarms(List<LocalAlarm> alarms) async {
    try {
      await initialize();

      print('💾 전체 알람 저장 시작 (${alarms.length}개):');
      for (final alarm in alarms) {
        print('  - ID: ${alarm.id}, type: ${alarm.type}, backendAlarmId: ${alarm.backendAlarmId}');
      }

      final alarmsJson = jsonEncode(alarms.map((alarm) => alarm.toJson()).toList());
      print('💾 JSON 저장: ${alarmsJson.substring(0, alarmsJson.length > 200 ? 200 : alarmsJson.length)}...');
      await _prefs!.setString(_alarmsKey, alarmsJson);

      print('✅ 알람 저장 완료');
      return true;
    } catch (e) {
      print('알람 저장 내부 오류: $e');
      return false;
    }
  }
  
  /// 백업 데이터 내보내기
  Future<String?> exportAlarmsData() async {
    try {
      final allAlarms = await getAllAlarms();
      return jsonEncode({
        'version': '1.0',
        'export_date': DateTime.now().toIso8601String(),
        'alarms': allAlarms.map((alarm) => alarm.toJson()).toList(),
      });
    } catch (e) {
      print('알람 데이터 내보내기 오류: $e');
      return null;
    }
  }
  
  /// 백업 데이터 가져오기
  Future<bool> importAlarmsData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final alarmsList = data['alarms'] as List<dynamic>;
      
      final alarms = alarmsList
          .map((json) => LocalAlarm.fromJson(json))
          .toList();
      
      return await saveAlarms(alarms);
    } catch (e) {
      print('알람 데이터 가져오기 오류: $e');
      return false;
    }
  }
}
