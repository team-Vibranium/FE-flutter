import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm.dart';

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
  DashboardNotifier() : super(const DashboardState()) {
    _loadInitialData();
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

  void addAlarm(Alarm alarm) {
    final updatedAlarms = [...state.alarms, alarm];
    state = state.copyWith(alarms: updatedAlarms);
  }

  void updateAlarm(Alarm updatedAlarm) {
    final updatedAlarms = state.alarms.map((alarm) {
      return alarm.id == updatedAlarm.id ? updatedAlarm : alarm;
    }).toList();
    state = state.copyWith(alarms: updatedAlarms);
  }

  void toggleAlarm(int alarmId) {
    final updatedAlarms = state.alarms.map((alarm) {
      if (alarm.id == alarmId) {
        return alarm.copyWith(isEnabled: !alarm.isEnabled);
      }
      return alarm;
    }).toList();
    state = state.copyWith(alarms: updatedAlarms);
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
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
