import '../models/alarm.dart';

class MockAlarmRepository {
  final List<Alarm> _alarms = []; // 기본 알람 제거

  Future<List<Alarm>> getAllAlarms() async {
    await Future.delayed(const Duration(milliseconds: 500)); // 네트워크 지연 시뮬레이션
    return List.from(_alarms);
  }

  Future<Alarm?> getAlarm(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _alarms.firstWhere((alarm) => alarm.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Alarm> createAlarm(Alarm alarm) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newId = _alarms.isNotEmpty
        ? _alarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1
        : 1;

    final newAlarm = alarm.copyWith(id: newId);
    _alarms.add(newAlarm);
    return newAlarm;
  }

  Future<Alarm> updateAlarm(Alarm alarm) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      return alarm;
    }
    throw Exception('Alarm not found');
  }

  Future<void> deleteAlarm(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _alarms.removeWhere((alarm) => alarm.id == id);
  }

  Future<void> toggleAlarm(int id, bool isEnabled) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index != -1) {
      _alarms[index] = _alarms[index].copyWith(isEnabled: isEnabled);
    }
  }
}