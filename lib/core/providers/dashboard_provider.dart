import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm.dart';
import 'alarm_provider.dart';

// Dashboard 상태 관리
class DashboardState {
  final int currentIndex;
  final List<Alarm> alarms;
  final int alarmTypeFilter;
  final int userPoints;
  final String selectedAvatar;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.currentIndex = 0,
    this.alarms = const [],
    this.alarmTypeFilter = 0,
    this.userPoints = 1250,
    this.selectedAvatar = 'default',
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    int? currentIndex,
    List<Alarm>? alarms,
    int? alarmTypeFilter,
    int? userPoints,
    String? selectedAvatar,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      currentIndex: currentIndex ?? this.currentIndex,
      alarms: alarms ?? this.alarms,
      alarmTypeFilter: alarmTypeFilter ?? this.alarmTypeFilter,
      userPoints: userPoints ?? this.userPoints,
      selectedAvatar: selectedAvatar ?? this.selectedAvatar,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;
  
  DashboardNotifier(this._ref) : super(const DashboardState()) {
    _loadInitialData();
    
    // 초기화 완료 후 알람 스케줄링 실행
    Future.microtask(() async {
      final alarms = state.alarms;
      for (final alarm in alarms) {
        if (alarm.isEnabled) {
          await _scheduleAlarmNotifications(alarm);
        }
      }
    });
  }

  void _loadInitialData() {
    // 더미 알람 데이터 로드
    final mockAlarms = [
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

    state = state.copyWith(alarms: mockAlarms);
  }

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void setAlarmTypeFilter(int filter) {
    state = state.copyWith(alarmTypeFilter: filter);
  }

  Future<void> addAlarm(Alarm alarm) async {
    final updatedAlarms = [...state.alarms, alarm];
    state = state.copyWith(alarms: updatedAlarms);
    
    // 실제 시스템 알림 스케줄링
    if (alarm.isEnabled) {
      await _scheduleAlarmNotifications(alarm);
    }
  }

  Future<void> updateAlarm(Alarm updatedAlarm) async {
    // 기존 알람의 알림 취소
    final oldAlarm = state.alarms.firstWhere((alarm) => alarm.id == updatedAlarm.id);
    await _cancelAlarmNotifications(oldAlarm);
    
    final updatedAlarms = state.alarms.map((alarm) {
      return alarm.id == updatedAlarm.id ? updatedAlarm : alarm;
    }).toList();
    state = state.copyWith(alarms: updatedAlarms);
    
    // 새 알람 스케줄링
    if (updatedAlarm.isEnabled) {
      await _scheduleAlarmNotifications(updatedAlarm);
    }
  }

  Future<void> toggleAlarm(int alarmId) async {
    final alarm = state.alarms.firstWhere((alarm) => alarm.id == alarmId);
    final updatedAlarm = alarm.copyWith(isEnabled: !alarm.isEnabled);
    
    final updatedAlarms = state.alarms.map((alarm) {
      if (alarm.id == alarmId) {
        return updatedAlarm;
      }
      return alarm;
    }).toList();
    state = state.copyWith(alarms: updatedAlarms);
    
    // 알람 상태에 따라 스케줄링/취소
    if (updatedAlarm.isEnabled) {
      await _scheduleAlarmNotifications(updatedAlarm);
    } else {
      await _cancelAlarmNotifications(updatedAlarm);
    }
  }

  void updateUserProfile({int? points, String? avatar}) {
    state = state.copyWith(
      userPoints: points ?? state.userPoints,
      selectedAvatar: avatar ?? state.selectedAvatar,
    );
  }

  List<Alarm> getFilteredAndSortedAlarms() {
    List<Alarm> filteredAlarms = List.from(state.alarms);
    
    // 알람 타입 필터링
    if (state.alarmTypeFilter == 1) {
      filteredAlarms = state.alarms.where((alarm) => alarm.type == AlarmType.normal).toList();
    } else if (state.alarmTypeFilter == 2) {
      filteredAlarms = state.alarms.where((alarm) => alarm.type == AlarmType.call).toList();
    }
    
    // 활성화된 알람을 먼저, 그 다음 비활성화된 알람 순으로 정렬
    filteredAlarms.sort((a, b) {
      if (a.isEnabled == b.isEnabled) return 0;
      return a.isEnabled ? -1 : 1;
    });
    
    return filteredAlarms;
  }
  
  // 알람 스케줄링 헬퍼 메서드들
  Future<void> _scheduleAlarmNotifications(Alarm alarm) async {
    final alarmNotifier = _ref.read(alarmStateProvider.notifier);
    
    // 요일별로 알람 스케줄링
    final now = DateTime.now();
    final weekdays = {
      '월': DateTime.monday,
      '화': DateTime.tuesday,
      '수': DateTime.wednesday,
      '목': DateTime.thursday,
      '금': DateTime.friday,
      '토': DateTime.saturday,
      '일': DateTime.sunday,
    };
    
    for (final day in alarm.days) {
      final weekday = weekdays[day];
      if (weekday == null) continue;
      
      // 알람 시간 파싱
      final timeParts = alarm.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // 다음 알람 시간 계산
      DateTime scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // 해당 요일로 조정
      final daysUntilTarget = (weekday - now.weekday + 7) % 7;
      scheduledTime = scheduledTime.add(Duration(days: daysUntilTarget));
      
      // 만약 오늘이고 시간이 지났다면 다음 주로
      if (daysUntilTarget == 0 && scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 7));
      }
      
      // 디버깅: 현재 시간과 예정 시간 출력
      print('현재 시간: $now');
      print('예정 시간: $scheduledTime (${alarm.tag} - $day)');
      
      // 고유한 알림 ID 생성 (작은 범위의 ID 사용)
      final notificationId = (alarm.id % 1000) * 10 + weekday;
      
      try {
        await alarmNotifier.scheduleAlarm(
          scheduledTime,
          '${alarm.tag} 알람',
          '${alarm.time} ${alarm.typeDisplayName}',
          customId: notificationId,
          alarmType: alarm.typeDisplayName,
        );
        print('알람 스케줄링 완료: ${alarm.tag} - $day ${alarm.time}');
      } catch (e) {
        print('알람 스케줄링 실패: $e');
      }
    }
  }
  
  Future<void> _cancelAlarmNotifications(Alarm alarm) async {
    final alarmNotifier = _ref.read(alarmStateProvider.notifier);
    
    final weekdays = {
      '월': DateTime.monday,
      '화': DateTime.tuesday,
      '수': DateTime.wednesday,
      '목': DateTime.thursday,
      '금': DateTime.friday,
      '토': DateTime.saturday,
      '일': DateTime.sunday,
    };
    
    // 각 요일별 알림 취소
    for (final day in alarm.days) {
      final weekday = weekdays[day];
      if (weekday == null) continue;
      
      final notificationId = alarm.id * 10 + weekday;
      try {
        await alarmNotifier.cancelAlarm(notificationId);
        print('알람 취소 완료: ${alarm.tag} - $day');
      } catch (e) {
        print('알람 취소 실패: $e');
      }
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});
