import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

/// 알람 로컬 저장 서비스
/// SharedPreferences를 사용하여 알람 데이터를 로컬에 저장/조회
class AlarmStorageService {
  static const String _alarmsKey = 'alarms';
  static const String _nextIdKey = 'next_alarm_id';
  
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// 서비스 초기화
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    print('📱 AlarmStorageService 초기화 완료');
  }

  /// 초기화 여부 확인
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('AlarmStorageService가 초기화되지 않았습니다. init()을 먼저 호출하세요.');
    }
  }

  /// 모든 알람 조회
  Future<List<Alarm>> getAllAlarms() async {
    _ensureInitialized();
    
    final alarmsJson = _prefs.getString(_alarmsKey);
    if (alarmsJson == null || alarmsJson.isEmpty) {
      print('📱 로컬 저장된 알람이 없습니다.');
      return [];
    }

    try {
      final List<dynamic> alarmsList = jsonDecode(alarmsJson);
      final alarms = alarmsList
          .map((json) => Alarm.fromJson(json))
          .toList();
      
      print('📱 로컬에서 ${alarms.length}개의 알람을 불러왔습니다.');
      return alarms;
    } catch (e) {
      print('❌ 알람 데이터 파싱 오류: $e');
      return [];
    }
  }

  /// 알람 저장 (전체 리스트 저장)
  Future<void> saveAlarms(List<Alarm> alarms) async {
    _ensureInitialized();
    
    try {
      final alarmsJson = jsonEncode(alarms.map((alarm) => alarm.toJson()).toList());
      await _prefs.setString(_alarmsKey, alarmsJson);
      print('📱 ${alarms.length}개의 알람을 로컬에 저장했습니다.');
    } catch (e) {
      print('❌ 알람 저장 오류: $e');
      rethrow;
    }
  }

  /// 새 알람 추가
  Future<Alarm> addAlarm({
    required String time,
    required List<String> days,
    required AlarmType type,
    required String tag,
    bool isEnabled = true,
  }) async {
    _ensureInitialized();
    
    // 새 ID 생성
    final newId = await _getNextId();
    
    // 새 알람 생성
    final newAlarm = Alarm(
      id: newId,
      time: time,
      days: days,
      type: type,
      isEnabled: isEnabled,
      tag: tag,
      successRate: 0, // 초기 성공률은 0%
    );

    // 기존 알람 목록에 추가
    final alarms = await getAllAlarms();
    alarms.add(newAlarm);
    await saveAlarms(alarms);

    print('📱 새 알람 추가: ${newAlarm.tag} (${newAlarm.time})');
    return newAlarm;
  }

  /// 알람 수정
  Future<void> updateAlarm(Alarm updatedAlarm) async {
    _ensureInitialized();
    
    final alarms = await getAllAlarms();
    final index = alarms.indexWhere((alarm) => alarm.id == updatedAlarm.id);
    
    if (index != -1) {
      alarms[index] = updatedAlarm;
      await saveAlarms(alarms);
      print('📱 알람 수정: ${updatedAlarm.tag} (ID: ${updatedAlarm.id})');
    } else {
      throw Exception('수정할 알람을 찾을 수 없습니다. (ID: ${updatedAlarm.id})');
    }
  }

  /// 알람 삭제
  Future<void> deleteAlarm(int alarmId) async {
    _ensureInitialized();
    
    final alarms = await getAllAlarms();
    final initialLength = alarms.length;
    alarms.removeWhere((alarm) => alarm.id == alarmId);
    
    if (alarms.length < initialLength) {
      await saveAlarms(alarms);
      print('📱 알람 삭제: ID $alarmId');
    } else {
      throw Exception('삭제할 알람을 찾을 수 없습니다. (ID: $alarmId)');
    }
  }

  /// 알람 활성화/비활성화
  Future<void> toggleAlarm(int alarmId, bool isEnabled) async {
    _ensureInitialized();
    
    final alarms = await getAllAlarms();
    final index = alarms.indexWhere((alarm) => alarm.id == alarmId);
    
    if (index != -1) {
      final updatedAlarm = alarms[index].copyWith(isEnabled: isEnabled);
      alarms[index] = updatedAlarm;
      await saveAlarms(alarms);
      print('📱 알람 ${isEnabled ? '활성화' : '비활성화'}: ${updatedAlarm.tag} (ID: $alarmId)');
    } else {
      throw Exception('알람을 찾을 수 없습니다. (ID: $alarmId)');
    }
  }

  /// 알람 성공률 업데이트
  Future<void> updateSuccessRate(int alarmId, int successRate) async {
    _ensureInitialized();
    
    final alarms = await getAllAlarms();
    final index = alarms.indexWhere((alarm) => alarm.id == alarmId);
    
    if (index != -1) {
      final updatedAlarm = alarms[index].copyWith(successRate: successRate);
      alarms[index] = updatedAlarm;
      await saveAlarms(alarms);
      print('📱 알람 성공률 업데이트: ${updatedAlarm.tag} -> $successRate%');
    } else {
      throw Exception('알람을 찾을 수 없습니다. (ID: $alarmId)');
    }
  }

  /// 특정 ID의 알람 조회
  Future<Alarm?> getAlarmById(int alarmId) async {
    _ensureInitialized();
    
    final alarms = await getAllAlarms();
    try {
      return alarms.firstWhere((alarm) => alarm.id == alarmId);
    } catch (e) {
      return null;
    }
  }

  /// 활성화된 알람만 조회
  Future<List<Alarm>> getActiveAlarms() async {
    final alarms = await getAllAlarms();
    return alarms.where((alarm) => alarm.isEnabled).toList();
  }

  /// 모든 알람 데이터 삭제 (초기화)
  Future<void> clearAllAlarms() async {
    _ensureInitialized();
    
    await _prefs.remove(_alarmsKey);
    await _prefs.remove(_nextIdKey);
    print('📱 모든 알람 데이터가 삭제되었습니다.');
  }

  /// 다음 알람 ID 생성
  Future<int> _getNextId() async {
    final currentId = _prefs.getInt(_nextIdKey) ?? 1;
    await _prefs.setInt(_nextIdKey, currentId + 1);
    return currentId;
  }

  /// 저장된 알람 개수 조회
  Future<int> getAlarmCount() async {
    final alarms = await getAllAlarms();
    return alarms.length;
  }

  /// 알람 타입별 개수 조회
  Future<Map<AlarmType, int>> getAlarmCountByType() async {
    final alarms = await getAllAlarms();
    final counts = <AlarmType, int>{
      AlarmType.normal: 0,
      AlarmType.call: 0,
    };

    for (final alarm in alarms) {
      counts[alarm.type] = (counts[alarm.type] ?? 0) + 1;
    }

    return counts;
  }
}
