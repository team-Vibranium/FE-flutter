import '../models/alarm.dart';

class MockAlarmRepository {
  final List<Alarm> _alarms = [
    Alarm(
      id: 1,
      time: '07:00',
      days: ['월', '화', '수', '목', '금'],
      type: AlarmType.normal,
      isEnabled: true,
      tag: '운동',
      successRate: 85,
    ),
    Alarm(
      id: 2,
      time: '08:30',
      days: ['토', '일'],
      type: AlarmType.call,
      isEnabled: false,
      tag: '회의',
      successRate: 60,
    ),
    Alarm(
      id: 3,
      time: '06:45',
      days: ['월', '수', '금'],
      type: AlarmType.normal,
      isEnabled: true,
      tag: '독서',
      successRate: 90,
    ),
  ];

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