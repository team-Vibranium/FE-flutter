# AningCall - Flutter 알람 앱

> 퍼즐을 풀어야만 끌 수 있는 혁신적인 알람 앱

## 📱 프로젝트 개요

AningCall은 사용자가 알람을 끄기 위해 반드시 퍼즐을 풀어야 하는 독특한 알람 앱입니다. 단순히 알람을 끄는 것이 아니라, 뇌를 자극하는 퍼즐을 통해 완전히 깨어나도록 도와줍니다.

## ✨ 주요 기능

### 🔐 인증 시스템
- **로그인/회원가입**: 이메일 기반 사용자 인증
- **테스트 계정**: 개발용 테스트 계정 제공
- **사용자 정보 관리**: 닉네임, 포인트 시스템

### ⏰ 알람 시스템
- **빠른 알람 설정**: 5분, 10분, 15분, 30분, 1시간, 2시간 후
- **상세 알람 설정**: 시간 선택, 제목/내용 커스터마이징
- **스누즈 정책**: 최대 3회 스누즈, 총 15분 지연
- **알람 테스트**: 개발용 즉시 알람 테스트 기능

### 🧩 퍼즐 미션
- **3가지 퍼즐 타입**:
  - **숫자 시퀀스**: 다음 숫자 찾기
  - **패턴 인식**: 도형 패턴 완성
  - **색상 조합**: 색상 순서 맞추기
- **30초 제한 시간**: 긴장감 있는 퍼즐 해결
- **포인트 시스템**: 성공 시 +10점 획득

### 🤖 AI 음성 통화 (NEW!)
- **OpenAI Realtime API**: GPT-4o 기반 실시간 음성 대화
- **WebRTC 통신**: 저지연 실시간 오디오 스트리밍
- **자연스러운 대화**: AI와 음성으로 자연스럽게 소통
- **깨우기 미션**: AI가 제공하는 질문과 퍼즐로 완전한 각성 유도
- **지능형 알람 해제**: AI가 사용자의 각성 상태를 판단하여 알람 해제 승인

### 🎨 현대적인 UI/UX
- **그라데이션 디자인**: 보라색 계열 모던한 색상
- **애니메이션 효과**: 알람 울림 시 펄스, 흔들림 효과
- **반응형 레이아웃**: 다양한 화면 크기 지원
- **직관적인 네비게이션**: 사용자 친화적 인터페이스

## 🏗️ 기술 스택

### Frontend
- **Flutter**: 크로스 플랫폼 모바일 앱 개발
- **Dart**: 프로그래밍 언어

### 상태 관리
- **Riverpod**: 상태 관리 및 의존성 주입

### 아키텍처 패턴
- **Repository Pattern**: 데이터 접근 계층 분리
- **Environment Pattern**: 개발/프로덕션 환경 분리

### 로컬 저장소
- **SharedPreferences**: 간단한 설정 저장
- **SQLite**: 복잡한 데이터 저장 (sqflite)

### 알람 관리
- **flutter_local_notifications**: 로컬 알람 스케줄링
- **timezone**: 시간대 관리

### HTTP 통신
- **Dio**: HTTP 클라이언트

### WebRTC & AI 통화
- **flutter_webrtc**: WebRTC 실시간 통신
- **web_socket_channel**: WebSocket 통신
- **permission_handler**: 권한 관리

### JSON 처리
- **json_annotation**: JSON 직렬화 어노테이션
- **json_serializable**: JSON 직렬화 코드 생성
- **build_runner**: 코드 생성 도구

### 기타
- **uuid**: 고유 ID 생성
- **intl**: 국제화 및 날짜 포맷팅

## 📁 프로젝트 구조

```
lib/
├── core/                          # 핵심 기능
│   ├── constants/                 # 상수 정의
│   │   └── app_constants.dart
│   ├── environment/               # 환경 설정
│   │   └── environment.dart
│   ├── models/                    # 데이터 모델
│   │   ├── user.dart
│   │   ├── call_log.dart
│   │   ├── mission_result.dart
│   │   ├── puzzle_mission.dart
│   │   └── api_response.dart
│   ├── providers/                 # 상태 관리
│   │   ├── auth_provider.dart
│   │   ├── alarm_provider.dart
│   │   └── puzzle_provider.dart
│   └── repositories/              # 데이터 접근 계층
│       ├── auth_repository.dart
│       ├── alarm_repository.dart
│       ├── mock_auth_repository.dart
│       └── mock_alarm_repository.dart
├── services/                     # 비즈니스 로직 서비스
│   ├── webrtc_service.dart        # WebRTC 통신 관리
│   ├── audio_processor.dart       # 오디오 데이터 처리
│   └── ai_call_service.dart       # AI 통화 통합 서비스
├── screens/                      # 화면 UI
│   ├── dashboard_screen.dart      # 메인 대시보드
│   ├── ai_call_screen.dart        # AI 통화 화면 (NEW!)
│   ├── alarm_ring_screen.dart     # 알람 울림 화면
│   ├── alarm_add_screen.dart      # 알람 추가 화면
│   ├── stats_screen.dart          # 통계 화면
│   ├── profile_screen.dart        # 프로필 화면
│   └── call_history_screen.dart   # 통화 기록 화면
│   │       └── recent_logs.dart
│   ├── puzzle/                    # 퍼즐 기능
│   │   └── screens/
│   │       └── puzzle_screen.dart
│   └── alarm/                     # 알람 기능
│       └── screens/
│           ├── alarm_ring_screen.dart
│           └── alarm_result_screen.dart
└── main.dart                      # 앱 진입점
```

## 🚀 설치 및 실행

### 필수 요구사항
- Flutter SDK (3.0 이상)
- Dart SDK
- Chrome 브라우저 (웹 실행용)

### 설치 방법

1. **저장소 클론**
```bash
git clone <repository-url>
cd FE-flutter
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **JSON 직렬화 코드 생성**
```bash
flutter pub run build_runner build
```

4. **앱 실행**
```bash
# Chrome에서 실행 (권장)
flutter run -d chrome

# Windows에서 실행 (Developer Mode 필요)
flutter run -d windows
```

### 테스트 실행
```bash
flutter test
```

## 🎯 사용 방법

### 1. 로그인
- **테스트 계정**: `test@example.com` / `123456`
- **또는**: "테스트 계정 입력" 버튼 클릭

### 2. 알람 설정
- **빠른 설정**: 5분, 10분, 15분, 30분, 1시간, 2시간 후 버튼 클릭
- **상세 설정**: 시간 선택 후 제목/내용 입력하고 "알람 설정" 클릭
- **테스트**: "알람 테스트 (개발용)" 버튼으로 즉시 테스트

### 3. 알람 해제 플로우
1. **알람 울림** → 애니메이션과 함께 알람 화면 표시
2. **퍼즐 풀기** → 30초 내에 퍼즐 해결
3. **결과 확인** → 성공/실패 결과 및 포인트 획득
4. **완료** → 홈 화면으로 복귀

## 🔧 개발 환경 설정

### 환경 분리
- **Development**: Mock 데이터 사용, 로컬 알람 비활성화
- **Production**: 실제 API 연동, 로컬 알람 활성화

### 코드 생성
```bash
# JSON 직렬화 코드 재생성
flutter pub run build_runner build --delete-conflicting-outputs

# 파일 감시 모드 (개발 중)
flutter pub run build_runner watch
```

## 📱 지원 플랫폼

- ✅ **Web** (Chrome, Edge)
- ✅ **Windows** (Developer Mode 필요)
- ⏳ **Android** (개발 예정)
- ⏳ **iOS** (개발 예정)

## 🐛 알려진 이슈

1. **Windows 실행**: Developer Mode 활성화 필요
2. **웹 알람**: 실제 알람 대신 테스트 모드로 동작
3. **타임존**: 웹에서 timezone 초기화 필요

## 🚧 개발 로드맵

### Phase 1 (완료)
- [x] 기본 앱 구조 설정
- [x] 인증 시스템 구현
- [x] 알람 설정 기능
- [x] 퍼즐 미션 시스템
- [x] UI/UX 디자인

### Phase 2 (진행 중)
- [ ] 실제 알람 스케줄링
- [ ] 데이터베이스 연동
- [ ] API 서버 연동
- [ ] 푸시 알림

### Phase 3 (계획)
- [ ] 사용자 통계
- [ ] 퍼즐 난이도 조절
- [ ] 소셜 기능
- [ ] 다국어 지원

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 연락처

프로젝트 링크: [https://github.com/username/aningcall](https://github.com/username/aningcall)

---

**AningCall** - 더 이상 단순한 알람이 아닙니다. 🧠✨