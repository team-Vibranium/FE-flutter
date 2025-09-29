# 로컬 알람 기능 사용 가이드

## 📱 개요

Flutter + Dart로 구현된 완전한 로컬 알람 시스템입니다. 서버 통신 없이 기기 내에서만 동작하며, 앱을 껐다 켜도 알람이 유지됩니다.

## 🏗️ 구조

### 1. 데이터 모델
- **LocalAlarm** (`lib/core/models/local_alarm.dart`)
  - 알람의 모든 속성을 정의
  - JSON 직렬화/역직렬화 지원
  - 다음 알람 시간 자동 계산

### 2. 저장소 서비스
- **LocalAlarmStorageService** (`lib/core/services/local_alarm_storage_service.dart`)
  - SharedPreferences를 사용한 로컬 데이터 저장
  - CRUD 연산 및 통계 기능 제공
  - 백업/복원 기능

### 3. 알림 스케줄링 서비스
- **LocalAlarmNotificationService** (`lib/core/services/local_alarm_notification_service.dart`)
  - flutter_local_notifications 사용
  - OS 네이티브 알림 스케줄러 활용
  - 스누즈 기능 지원

### 4. 통합 관리 서비스
- **LocalAlarmService** (`lib/core/services/local_alarm_service.dart`)
  - 모든 알람 관련 기능을 통합
  - 앱 시작 시 자동 초기화
  - 시스템 재시작 후 알람 복구

### 5. UI 화면
- **LocalAlarmListScreen** (`lib/screens/local_alarm_list_screen.dart`)
  - 알람 목록 표시 및 관리
- **LocalAlarmAddScreen** (`lib/screens/local_alarm_add_screen.dart`)
  - 알람 추가/편집 화면

## 🚀 사용 방법

### 1. 기본 설정

앱 시작 시 `main.dart`에서 자동으로 초기화됩니다:

```dart
// main.dart에서 자동 호출됨
final alarmInitResult = await LocalAlarmService.initializeOnAppStart();
```

### 2. 새 알람 생성

```dart
final alarmService = LocalAlarmService.instance;

final newAlarm = await alarmService.createAlarm(
  title: '아침 알람',
  hour: 7,
  minute: 30,
  repeatDays: [1, 2, 3, 4, 5], // 월-금 반복
  vibrate: true,
  snoozeEnabled: true,
  snoozeInterval: 5,
  label: '출근 준비',
);
```

### 3. 알람 목록 조회

```dart
// 모든 알람
final allAlarms = await alarmService.getAllAlarms();

// 활성화된 알람만
final enabledAlarms = await alarmService.getEnabledAlarms();

// 특정 알람
final alarm = await alarmService.getAlarmById('alarm_id');
```

### 4. 알람 수정

```dart
final updatedAlarm = existingAlarm.copyWith(
  title: '새 제목',
  hour: 8,
  minute: 0,
);

await alarmService.updateAlarm(updatedAlarm);
```

### 5. 알람 삭제

```dart
await alarmService.deleteAlarm('alarm_id');
```

### 6. 알람 활성화/비활성화

```dart
await alarmService.toggleAlarm('alarm_id', true); // 활성화
await alarmService.toggleAlarm('alarm_id', false); // 비활성화
```

## 📊 주요 기능

### ✅ 완전한 로컬 저장
- SharedPreferences를 사용하여 기기 내 저장
- 앱 삭제 전까지 데이터 유지
- JSON 형태로 직렬화하여 안정적 저장

### ⏰ OS 네이티브 알림
- Android: `AndroidScheduleMode.exactAllowWhileIdle` 사용
- iOS: `InterruptionLevel.critical` 사용
- 앱이 꺼져있어도 정확한 시간에 알림

### 🔄 반복 알람 지원
- 요일별 반복 설정 가능
- 한번만 울리는 알람도 지원
- 자동으로 다음 알람 시간 계산

### 😴 스누즈 기능
- 사용자 정의 스누즈 간격 (1-30분)
- 알림에서 직접 스누즈 버튼 제공
- 원래 알람은 그대로 유지

### 🔧 고급 기능
- 진동 설정
- 커스텀 사운드 (준비됨)
- 알람 라벨/메모
- 통계 정보 제공
- 백업/복원 기능

## 🔧 설정 및 권한

### Android 권한 (자동 요청됨)
- `android.permission.SCHEDULE_EXACT_ALARM`
- `android.permission.USE_EXACT_ALARM`
- `android.permission.POST_NOTIFICATIONS`
- `android.permission.VIBRATE`

### iOS 권한 (자동 요청됨)
- 알림 권한
- 배지 권한
- 사운드 권한

## 🐛 문제 해결

### 1. 알람이 울리지 않을 때
```dart
// 예약된 알림 확인
final notifications = await alarmService.getScheduledNotifications();
print('예약된 알림: $notifications');

// 알람 재스케줄링
await alarmService.restoreAlarmsAfterReboot();
```

### 2. 권한 문제
```dart
// 알림 서비스 재초기화
final notificationService = LocalAlarmNotificationService.instance;
await notificationService.initialize();
```

### 3. 데이터 손실
```dart
// 백업 생성
final backupData = await alarmService.exportAlarms();
// 안전한 곳에 저장

// 복원
await alarmService.importAlarms(backupData);
```

## 📈 통계 정보

```dart
final stats = await alarmService.getAlarmStatistics();
print('총 알람 수: ${stats['totalAlarms']}');
print('활성 알람 수: ${stats['enabledAlarms']}');
print('다음 알람: ${stats['nextAlarmTime']}');
```

## 🔄 시스템 재시작 대응

앱은 시작 시 자동으로 모든 활성 알람을 재스케줄링합니다:

```dart
// main.dart에서 자동 실행됨
await LocalAlarmService.initializeOnAppStart();
```

## 🎯 사용 팁

1. **반복 알람**: 매일 같은 시간에 울리는 알람은 `repeatDays: [0,1,2,3,4,5,6]`
2. **평일 알람**: `repeatDays: [1,2,3,4,5]`
3. **주말 알람**: `repeatDays: [0,6]`
4. **한번만**: `repeatDays: []` (빈 리스트)

## 🔒 보안 및 개인정보

- 모든 데이터는 기기 내에서만 저장
- 네트워크 통신 없음
- 사용자 동의 하에만 알림 권한 사용

## 📱 UI 접근

대시보드 하단의 "알람" 탭을 클릭하면 로컬 알람 관리 화면으로 이동합니다.

---

이 로컬 알람 시스템은 완전히 독립적으로 작동하며, 서버 의존성 없이 안정적인 알람 기능을 제공합니다.
