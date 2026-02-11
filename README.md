# 오늘 뭐 먹지? (Lunch Menu Roulette)

Flutter로 만든 점심 메뉴 추천 앱입니다.  
룰렛을 돌리거나 휴대폰을 흔들어 메뉴를 랜덤으로 뽑고, 결과를 공유하거나 주변 맛집/유튜브 쇼츠까지 바로 확인할 수 있습니다.

## 주요 기능

- 메뉴 룰렛 추천
  - 버튼 클릭 또는 휴대폰 흔들기(가속도 센서)로 랜덤 추첨
- 카테고리 필터
  - 한식/중식/일식/양식/분식/야식/간편식/다이어트/치킨 등 선택 가능
- 메뉴 직접 관리
  - 메뉴 추가/삭제, 로컬 저장(`shared_preferences`)
- 결과 후속 액션
  - 결과 공유 (`share_plus`)
  - 주변 맛집 검색 (`geolocator` + 외부 지도 URL 실행)
  - 메뉴 관련 유튜브 쇼츠 검색 (`webview_flutter`)

## 기술 스택

- Flutter / Dart
- 주요 패키지
  - `sensors_plus`
  - `geolocator`
  - `url_launcher`
  - `webview_flutter`
  - `shared_preferences`
  - `share_plus`
  - `flutter_fortune_wheel` (의존성 포함)

## 시작하기

### 1) 환경 준비
- Flutter SDK 설치
- Android Studio 또는 VS Code + Flutter 플러그인

### 2) 프로젝트 실행
```bash
flutter pub get
flutter run
