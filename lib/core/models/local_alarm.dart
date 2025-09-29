import 'package:json_annotation/json_annotation.dart';

part 'local_alarm.g.dart';

/// 로컬 알람 데이터 모델
@JsonSerializable()
class LocalAlarm {
  /// 알람 고유 ID
  final String id;
  
  /// 알람 제목
  final String title;
  
  /// 알람 시간 (시)
  final int hour;
  
  /// 알람 시간 (분)
  final int minute;
  
  /// 활성화 여부
  final bool isEnabled;
  
  /// 반복 요일 (0: 일요일, 1: 월요일, ..., 6: 토요일)
  /// 빈 리스트면 한번만 울림
  final List<int> repeatDays;
  
  /// 알람 사운드 경로/이름
  final String? soundPath;
  
  /// 진동 여부
  final bool vibrate;
  
  /// 스누즈 활성화 여부
  final bool snoozeEnabled;
  
  /// 스누즈 간격 (분)
  final int snoozeInterval;
  
  /// 알람 생성 시간
  final DateTime createdAt;
  
  /// 알람 수정 시간
  final DateTime updatedAt;
  
  /// 알람 라벨/메모
  final String? label;
  
  /// 알람 타입 ('normal', 'morning_call', 'mission' 등)
  final String? type;

  const LocalAlarm({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.repeatDays = const [],
    this.soundPath,
    this.vibrate = true,
    this.snoozeEnabled = true,
    this.snoozeInterval = 5,
    required this.createdAt,
    required this.updatedAt,
    this.label,
    this.type = 'normal',
  });

  /// JSON에서 객체 생성
  factory LocalAlarm.fromJson(Map<String, dynamic> json) => 
      _$LocalAlarmFromJson(json);

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$LocalAlarmToJson(this);

  /// 알람 시간을 문자열로 반환 (HH:MM 형식)
  String get timeString {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  /// 12시간 형식으로 시간 반환
  String get time12HourFormat {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  /// 반복 요일을 문자열로 반환
  String get repeatDaysString {
    if (repeatDays.isEmpty) return '한번만';
    
    const dayNames = ['일', '월', '화', '수', '목', '금', '토'];
    if (repeatDays.length == 7) return '매일';
    if (repeatDays.length == 5 && 
        repeatDays.contains(1) && repeatDays.contains(2) && 
        repeatDays.contains(3) && repeatDays.contains(4) && 
        repeatDays.contains(5)) {
      return '평일';
    }
    if (repeatDays.length == 2 && 
        repeatDays.contains(0) && repeatDays.contains(6)) {
      return '주말';
    }
    
    final sortedDays = List<int>.from(repeatDays)..sort();
    return sortedDays.map((day) => dayNames[day]).join(', ');
  }

  /// 다음 알람 시간 계산
  DateTime? get nextAlarmTime {
    if (!isEnabled) return null;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    
    // 반복 없음 (한번만)
    if (repeatDays.isEmpty) {
      if (today.isAfter(now)) {
        return today;
      } else {
        return today.add(const Duration(days: 1));
      }
    }
    
    // 반복 있음
    for (int i = 0; i < 7; i++) {
      final checkDate = today.add(Duration(days: i));
      final weekday = checkDate.weekday % 7; // DateTime.weekday: 1(월) ~ 7(일)을 0(일) ~ 6(토)로 변환
      
      if (repeatDays.contains(weekday)) {
        if (i == 0 && checkDate.isAfter(now)) {
          return checkDate;
        } else if (i > 0) {
          return checkDate;
        }
      }
    }
    
    return null;
  }

  /// 알람 복사 (일부 필드 수정)
  LocalAlarm copyWith({
    String? id,
    String? title,
    int? hour,
    int? minute,
    bool? isEnabled,
    List<int>? repeatDays,
    String? soundPath,
    bool? vibrate,
    bool? snoozeEnabled,
    int? snoozeInterval,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? label,
    String? type,
  }) {
    return LocalAlarm(
      id: id ?? this.id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      soundPath: soundPath ?? this.soundPath,
      vibrate: vibrate ?? this.vibrate,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeInterval: snoozeInterval ?? this.snoozeInterval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      label: label ?? this.label,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'LocalAlarm(id: $id, title: $title, time: $timeString, enabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalAlarm && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
