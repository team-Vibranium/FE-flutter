# AningCall REST API 명세서

## 개요
AningCall 앱의 REST API 명세서입니다. 알람은 로컬 OS에서 처리하고, 사용자 데이터, 포인트, 통계, 통화 기록 등은 서버 API를 통해 관리합니다.

## 기본 정보
- **Base URL**: `https://api.aningcall.com`
- **개발 환경**: `http://localhost:8080`
- **Content-Type**: `application/json`
- **인증**: Bearer Token

---

## 1. 인증 (Authentication)

### 1.1 회원가입
```http
POST /api/auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "nickname": "알람마스터"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "email": "user@example.com",
      "nickname": "알람마스터",
      "points": 0,
      "createdAt": "2024-01-15T09:00:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 1.2 로그인
```http
POST /api/auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "email": "user@example.com",
      "nickname": "알람마스터",
      "points": 1250,
      "createdAt": "2024-01-15T09:00:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 1.3 로그아웃
```http
POST /api/auth/logout
```

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "로그아웃 되었습니다."
}
```

---

## 2. 사용자 관리 (User Management)

### 2.1 사용자 정보 조회
```http
GET /api/users/me
```

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "user@example.com",
    "nickname": "알람마스터",
    "points": 1250,
    "selectedAvatar": "avatar_1",
    "createdAt": "2024-01-15T09:00:00Z"
  }
}
```

### 2.2 사용자 정보 수정
```http
PUT /api/users/me
```

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "nickname": "새로운닉네임",
  "selectedAvatar": "avatar_2"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "user@example.com",
    "nickname": "새로운닉네임",
    "points": 1250,
    "selectedAvatar": "avatar_2",
    "createdAt": "2024-01-15T09:00:00Z"
  }
}
```

### 2.3 회원탈퇴
```http
DELETE /api/users/me
```

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "회원탈퇴가 완료되었습니다."
}
```

---

## 3. 포인트 시스템 (Point System)

### 3.1 포인트 현황 조회
```http
GET /api/points/summary
```

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "consumptionPoints": 850,
    "gradePoints": 1250,
    "totalPoints": 2100,
    "currentGrade": "GOLD"
  }
}
```

### 3.2 포인트 내역 조회
```http
GET /api/points/history?type={type}&limit={limit}&offset={offset}
```

**Query Parameters:**
- `type`: `CONSUMPTION` | `GRADE` | `ALL` (선택사항)
- `limit`: 조회할 개수 (기본값: 20)
- `offset`: 시작 위치 (기본값: 0)

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": 1,
        "type": "GRADE",
        "amount": 10,
        "description": "알람 성공 (등급 포인트)",
        "createdAt": "2024-01-15T07:30:00Z",
        "relatedAlarmId": "alarm_123"
      },
      {
        "id": 2,
        "type": "CONSUMPTION",
        "amount": -50,
        "description": "아바타 구매 (소비 포인트)",
        "createdAt": "2024-01-14T15:20:00Z",
        "relatedAlarmId": null
      }
    ],
    "totalCount": 45,
    "hasMore": true
  }
}
```

### 3.3 포인트 획득
```http
POST /api/points/earn
```

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "type": "GRADE",
  "amount": 10,
  "description": "알람 성공 보너스",
  "relatedAlarmId": "alarm_123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": 123,
      "type": "GRADE",
      "amount": 10,
      "description": "알람 성공 보너스",
      "createdAt": "2024-01-15T07:30:00Z",
      "relatedAlarmId": "alarm_123"
    },
    "newBalance": {
      "consumptionPoints": 850,
      "gradePoints": 1260,
      "totalPoints": 2110
    }
  }
}
```

### 3.4 포인트 사용
```http
POST /api/points/spend
```

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "type": "CONSUMPTION",
  "amount": 100,
  "description": "캐릭터 구매",
  "itemId": "avatar_premium_1"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": 124,
      "type": "CONSUMPTION",
      "amount": -100,
      "description": "캐릭터 구매",
      "createdAt": "2024-01-15T16:45:00Z",
      "relatedAlarmId": null
    },
    "newBalance": {
      "consumptionPoints": 750,
      "gradePoints": 1260,
      "totalPoints": 2010
    }
  }
}
```

---

## 4. 통화 기록 (Call Logs)

### 4.1 통화 기록 생성
```http
POST /api/call-logs
```

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "callStart": "2024-01-15T07:30:00Z",
  "callEnd": "2024-01-15T07:32:30Z",
  "result": "SUCCESS",
  "snoozeCount": 0
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "userId": 1,
    "callStart": "2024-01-15T07:30:00Z",
    "callEnd": "2024-01-15T07:32:30Z",
    "result": "SUCCESS",
    "snoozeCount": 0
  }
}
```

### 4.2 통화 기록 조회
```http
GET /api/call-logs?limit={limit}&offset={offset}&startDate={startDate}&endDate={endDate}
```

**Query Parameters:**
- `limit`: 조회할 개수 (기본값: 20)
- `offset`: 시작 위치 (기본값: 0)
- `startDate`: 시작 날짜 (YYYY-MM-DD)
- `endDate`: 종료 날짜 (YYYY-MM-DD)

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "callLogs": [
      {
        "id": 1,
        "userId": 1,
        "callStart": "2024-01-15T07:30:00Z",
        "callEnd": "2024-01-15T07:32:30Z",
        "result": "SUCCESS",
        "snoozeCount": 0
      },
      {
        "id": 2,
        "userId": 1,
        "callStart": "2024-01-14T07:30:00Z",
        "callEnd": null,
        "result": "FAIL_NO_TALK",
        "snoozeCount": 2
      }
    ],
    "totalCount": 45,
    "hasMore": true
  }
}
```

---

## 5. 미션 결과 (Mission Results)

### 5.1 미션 결과 저장
```http
POST /api/mission-results
```

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "callLogId": 1,
  "missionType": "PUZZLE",
  "success": true
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "callLogId": 1,
    "missionType": "PUZZLE",
    "success": true
  }
}
```

### 5.2 미션 결과 조회
```http
GET /api/mission-results?callLogId={callLogId}
```

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "callLogId": 1,
      "missionType": "PUZZLE",
      "success": true
    }
  ]
}
```

---

## 6. 통계 (Statistics)

### 6.1 전체 통계 조회
```http
GET /api/statistics/overview
```

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "totalAlarms": 45,
    "successAlarms": 38,
    "missedAlarms": 7,
    "successRate": 84.4,
    "consecutiveDays": 12,
    "averageWakeTime": "07:15",
    "last30DaysSuccessRate": 87,
    "monthlySuccessRate": 85,
    "monthlyPoints": 320
  }
}
```

### 6.2 기간별 통계 조회
```http
GET /api/statistics/period?startDate={startDate}&endDate={endDate}
```

**Query Parameters:**
- `startDate`: 시작 날짜 (YYYY-MM-DD)
- `endDate`: 종료 날짜 (YYYY-MM-DD)

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "period": {
      "startDate": "2024-01-01",
      "endDate": "2024-01-31"
    },
    "totalAlarms": 62,
    "successAlarms": 54,
    "failedAlarms": 8,
    "successRate": 87.1,
    "totalPoints": 540,
    "averageWakeTime": "07:12",
    "dailyStats": [
      {
        "date": "2024-01-01",
        "alarmCount": 2,
        "successCount": 2,
        "failCount": 0,
        "points": 20
      }
    ]
  }
}
```

### 6.3 캘린더 통계 조회
```http
GET /api/statistics/calendar?year={year}&month={month}
```

**Query Parameters:**
- `year`: 연도 (예: 2024)
- `month`: 월 (1-12)

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "year": 2024,
    "month": 1,
    "dailyResults": [
      {
        "day": 1,
        "alarmCount": 2,
        "successCount": 2,
        "failCount": 0,
        "status": "success"
      },
      {
        "day": 2,
        "alarmCount": 1,
        "successCount": 0,
        "failCount": 1,
        "status": "failure"
      },
      {
        "day": 3,
        "alarmCount": 0,
        "successCount": 0,
        "failCount": 0,
        "status": "none"
      }
    ],
    "monthSummary": {
      "totalAlarms": 62,
      "successAlarms": 54,
      "failedAlarms": 8,
      "successRate": 87.1
    }
  }
}
```

---

## 7. 에러 응답 형식

모든 에러 응답은 다음 형식을 따릅니다:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "입력값이 올바르지 않습니다.",
    "details": {
      "field": "email",
      "reason": "이메일 형식이 올바르지 않습니다."
    }
  }
}
```

### 7.1 에러 코드 목록

| 코드 | HTTP Status | 설명 |
|------|-------------|------|
| `VALIDATION_ERROR` | 400 | 입력값 검증 실패 |
| `UNAUTHORIZED` | 401 | 인증 실패 |
| `FORBIDDEN` | 403 | 권한 없음 |
| `NOT_FOUND` | 404 | 리소스를 찾을 수 없음 |
| `CONFLICT` | 409 | 리소스 충돌 (중복 등) |
| `INSUFFICIENT_POINTS` | 422 | 포인트 부족 |
| `INTERNAL_SERVER_ERROR` | 500 | 서버 내부 오류 |

---

## 8. 로컬 알람 처리

알람은 로컬 OS에서 처리되며, 다음과 같은 정보만 서버와 동기화합니다:

### 8.1 알람 성공/실패 결과
- 알람이 울렸을 때 → 통화 기록 생성 (`POST /api/call-logs`)
- 미션 수행 결과 → 미션 결과 저장 (`POST /api/mission-results`)
- 포인트 획득 → 포인트 획득 (`POST /api/points/earn`)

### 8.2 로컬에서만 관리되는 데이터
- 알람 설정 (시간, 요일, 타입 등)
- 알람 스케줄링
- 로컬 알림 권한
- 사운드 설정

---

## 9. 인증 헤더

모든 보호된 엔드포인트는 다음 헤더가 필요합니다:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

---

## 10. 페이지네이션

목록 조회 API는 다음과 같은 페이지네이션을 지원합니다:

**Query Parameters:**
- `limit`: 한 페이지당 항목 수 (기본값: 20, 최대: 100)
- `offset`: 시작 위치 (기본값: 0)

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [...],
    "totalCount": 150,
    "hasMore": true,
    "limit": 20,
    "offset": 0
  }
}
```
