# 🌿 YaM Diary - You and My Diary for Android

YaM Diary는 **Flutter와 Firebase**로 제작된 안드로이드 전용 다이어리 앱입니다.  
사용자의 **개인 다이어리**는 물론, **그룹 다이어리 및 일정 공유 기능**까지 지원하여,  
일정을 기록하고 나누는 새로운 경험을 제공합니다.

---

## 📱 주요 기능

### 🔐 개인 다이어리
- 비밀번호 잠금 기능
- 날짜별 일정 기록
- 태그 및 카테고리 분류
- 알림 설정 기능

### 👥 그룹 다이어리 & 일정
- **초대 코드**를 통해 그룹 참여
- 그룹 구성원과 일정/다이어리 공유
- 내가 참여 중인 그룹 목록 확인
- 그룹 탈퇴 및 삭제 기능

### 🎨 기타 기능
- 다크 모드 지원
- 위젯 기능 (추후 예정)
- 캘린더 UI 기반 일정 확인
- Firebase 백업 및 복원 기능

---

## 📸 스크린샷

| 로그인 | 캘린더 화면 | 개인 다이어리 |
|--------|--------------|----------------|
| ![Login](screenshot/login.png) | ![Calendar](screenshot/calendar.png) | ![Diary](screenshot/diary.png) |

> `screenshot/` 폴더 안에 있는 이미지 경로를 위처럼 지정해두면 자동으로 표시됩니다.

---

## ⚙️ 기술 스택

- Flutter 3.x
- Dart
- Firebase (Authentication, Firestore, Storage)
- Android (안드로이드 전용)

---

## 📂 프로젝트 구조 (일부 예시)

```bash
lib/
├── main.dart
├── screens/
│   ├── login_screen.dart
│   ├── calendar_screen.dart
│   └── diary_screen.dart
├── widgets/
│   └── custom_calendar.dart
└── services/
    └── firebase_service.dart