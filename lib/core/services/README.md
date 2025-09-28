# API 서비스 가이드

노션 API 스펙에 맞춰 구현된 Flutter API 서비스 사용 가이드입니다.

## 📁 파일 구조

```
lib/core/
├── models/
│   └── api_models.dart          # API 응답/요청 모델들
├── services/
│   ├── base_api_service.dart    # 기본 HTTP 클라이언트 및 에러 처리
│   ├── auth_api_service.dart    # 인증 관련 API
│   ├── user_api_service.dart    # 사용자 관리 API
│   ├── call_log_api_service.dart # 통화 기록 API
│   ├── points_api_service.dart  # 포인트 시스템 API
│   ├── mission_api_service.dart # 미션 결과 API
│   ├── statistics_api_service.dart # 통계 API
│   ├── api_service.dart         # 통합 API 서비스
│   ├── api_service_example.dart # 사용 예제
│   └── README.md               # 이 파일
└── environment/
    └── environment.dart         # 환경 설정
```

## 🚀 시작하기

### 1. 초기화

```dart
import 'package:your_app/core/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // API 서비스 초기화
  ApiService().initialize();
  
  runApp(MyApp());
}
```

### 2. 기본 사용법

```dart
final ApiService apiService = ApiService();

// 인증 후 사용
if (apiService.isAuthenticated) {
  // API 호출
}
```

## 🔐 인증 (Authentication)

### 회원가입

```dart
final request = RegisterRequest(
  email: 'user@example.com',
  password: 'password123',
  nickname: '사용자닉네임',
);

final response = await apiService.auth.register(request);
if (response.success) {
  print('회원가입 성공: ${response.data!.accessToken}');
}
```

### 로그인

```dart
final request = LoginRequest(
  email: 'user@example.com',
  password: 'password123',
);

final response = await apiService.auth.login(request);
if (response.success) {
  print('로그인 성공');
  // 토큰은 자동으로 저장됨
}
```

### 로그아웃

```dart
await apiService.auth.logout();
```

## 👤 사용자 관리 (User Management)

### 내 정보 조회

```dart
final response = await apiService.user.getMyInfo();
if (response.success) {
  final user = response.data!;
  print('사용자: ${user.nickname} (${user.email})');
}
```

### 닉네임 변경

```dart
final request = NicknameChangeRequest(nickname: '새로운닉네임');
final response = await apiService.user.changeNickname(request);
```

### 비밀번호 변경

```dart
final request = PasswordChangeRequest(
  currentPassword: '현재비밀번호',
  newPassword: '새로운비밀번호',
);
final response = await apiService.user.changePassword(request);
```

## 📞 통화 기록 (Call Logs)

### 통화 기록 생성

```dart
final response = await apiService.callLog.createCallLog(
  alarmTitle: '아침 7시 알람',
  startTime: DateTime.now().subtract(Duration(minutes: 5)),
  endTime: DateTime.now(),
  duration: 300, // 5분
  isSuccessful: true,
  transcript: 'AI와의 대화 내용',
);
```

### 통화 기록 조회

```dart
// 최근 10개 조회
final response = await apiService.callLog.getRecentCallLogs(limit: 10);

// 성공한 통화만 조회
final successfulCalls = await apiService.callLog.getSuccessfulCallLogs();

// 특정 기간 조회
final periodCalls = await apiService.callLog.getCallLogsByDateRange(
  DateTime.now().subtract(Duration(days: 7)),
  DateTime.now(),
);
```

## 🎯 포인트 시스템 (Points)

### 포인트 현황 조회

```dart
final response = await apiService.points.getPointSummary();
if (response.success) {
  final summary = response.data!;
  print('총 포인트: ${summary.totalPoints}');
  print('오늘 획득: ${summary.earnedToday}');
}
```

### 포인트 획득

```dart
// 알람 성공으로 포인트 획득
final response = await apiService.points.earnPointsForAlarmSuccess(
  alarmId: 'alarm_123',
  points: 10,
);

// 미션 완료로 포인트 획득
final missionPoints = await apiService.points.earnPointsForMissionComplete(
  missionId: 'mission_456',
  missionType: MissionType.math,
  score: 85,
);
```

### 포인트 사용

```dart
// 스킨 구매
final response = await apiService.points.spendPointsForSkin(
  skinId: 'skin_123',
  price: 100,
);
```

## 🎮 미션 (Missions)

### 수학 미션 결과 저장

```dart
final response = await apiService.mission.saveMathMissionResult(
  alarmId: 'alarm_123',
  isCompleted: true,
  score: 90,
  problems: [
    {'question': '2 + 3 = ?', 'answer': 5, 'userAnswer': 5, 'correct': true},
  ],
  correctAnswers: 1,
  totalProblems: 1,
  timeSpent: 30, // 30초
);
```

### 음성 인식 미션 결과 저장

```dart
final response = await apiService.mission.saveVoiceMissionResult(
  alarmId: 'alarm_123',
  isCompleted: true,
  score: 85,
  targetPhrase: '좋은 아침입니다',
  recognizedText: '좋은 아침입니다',
  confidence: 0.95,
  attempts: 1,
);
```

## 📊 통계 (Statistics)

### 전체 통계 조회

```dart
final response = await apiService.statistics.getOverview();
if (response.success) {
  final stats = response.data!;
  print('총 알람 수: ${stats.totalAlarms}');
  print('성공률: ${stats.successRate}%');
}
```

### 주간/월간 통계

```dart
// 이번 주 통계
final weeklyStats = await apiService.statistics.getWeeklyStatistics();

// 이번 달 통계
final monthlyStats = await apiService.statistics.getMonthlyStatistics();

// 최근 7일 통계
final recentStats = await apiService.statistics.getRecentDaysStatistics(7);
```

### 캘린더 통계

```dart
final response = await apiService.statistics.getCalendarStatistics(
  year: 2024,
  month: 3,
);
```

## 🎛️ 통합 기능

### 대시보드 데이터 한번에 로드

```dart
final data = await apiService.getDashboardData();
// 사용자 정보, 포인트 현황, 통계, 최근 기록들을 모두 포함
```

### 알람 완료 후 전체 처리

```dart
final result = await apiService.completeAlarmSession(
  alarmId: 'alarm_123',
  alarmTitle: '아침 7시 알람',
  startTime: startTime,
  endTime: endTime,
  isSuccessful: true,
  transcript: 'AI 대화 내용',
  missionResults: {
    'math': {
      'isCompleted': true,
      'score': 90,
      // ... 미션 상세 결과
    },
  },
);
// 통화 기록 저장 + 포인트 획득 + 미션 결과 저장을 한번에 처리
```

## 🔧 환경 설정

### 개발/프로덕션 환경

```dart
// lib/core/environment/environment.dart에서 설정
EnvironmentConfig.setEnvironment(Environment.development); // 개발
EnvironmentConfig.setEnvironment(Environment.production);  // 프로덕션
```

### API 베이스 URL

- 개발: `http://localhost:8080`
- 프로덕션: `https://api.aningcall.com`

## ⚠️ 에러 처리

### 기본 에러 처리

```dart
try {
  final response = await apiService.user.getMyInfo();
  if (response.success) {
    // 성공 처리
  } else {
    print('API 오류: ${response.error}');
  }
} on NetworkException catch (e) {
  print('네트워크 오류: ${e.message}');
} on AuthenticationException catch (e) {
  print('인증 오류: ${e.message}');
  // 로그인 화면으로 이동
} on ApiException catch (e) {
  print('API 오류: ${e.message}');
} catch (e) {
  print('알 수 없는 오류: $e');
}
```

### 자동 토큰 갱신

```dart
// BaseApiService에서 401 에러 시 자동으로 토큰 갱신 시도
// 갱신 실패 시 AuthenticationException 발생
```

## 📱 실제 사용 예제

자세한 사용 예제는 `api_service_example.dart` 파일을 참고하세요.

```dart
// 예제 실행
final example = ApiServiceExample();
await example.runAllExamples();
```

## 🛠️ 커스터마이징

### 새로운 API 엔드포인트 추가

1. `api_models.dart`에 모델 추가
2. 해당 도메인의 API 서비스 클래스에 메서드 추가
3. 필요시 `api_service.dart`에 통합 메서드 추가

### 에러 처리 커스터마이징

`BaseApiService`의 `_handleResponse` 메서드를 수정하여 에러 처리 로직 변경 가능

## 📋 API 엔드포인트 목록

### 인증 (Authentication)
- `POST /api/auth/register` - 회원가입
- `POST /api/auth/login` - 로그인
- `POST /api/auth/logout` - 로그아웃

### 사용자 관리 (User Management)
- `GET /api/users/me` - 내 정보 조회
- `PUT /api/users/me` - 내 정보 수정
- `PATCH /api/users/me/password` - 비밀번호 수정
- `PATCH /api/users/me/nickname` - 닉네임 수정
- `DELETE /api/users/me` - 회원 탈퇴

### 통화 기록 (Call Logs)
- `GET /api/call-logs` - 통화 기록 조회
- `POST /api/call-logs` - 통화 기록 생성

### 포인트 시스템 (Points)
- `GET /api/points/summary` - 포인트 현황 조회
- `GET /api/points/history` - 포인트 내역 조회
- `POST /api/points/spend` - 포인트 사용
- `POST /api/points/earn` - 포인트 획득

### 미션 결과 (Mission Results)
- `GET /api/mission-results` - 미션 결과 조회
- `POST /api/mission-results` - 미션 결과 저장

### 통계 (Statistics)
- `GET /api/statistics/overview` - 전체 통계 조회
- `GET /api/statistics/period` - 기간별 통계 조회
- `GET /api/statistics/calendar` - 캘린더 통계 조회

---

이 API 서비스는 노션에 정의된 API 스펙을 기반으로 구현되었습니다. 추가 기능이나 수정이 필요한 경우 해당 서비스 클래스를 수정하시면 됩니다.
