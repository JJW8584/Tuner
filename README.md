# Tuner

페달 튜너의 디스플레이를 참고한 Flutter 크로매틱 튜너입니다. 단일 악기음을 마이크로 받아 음명·옥타브·음정 편차를 실시간으로 표시합니다.

<img src="docs/images/android-idle.png" alt="Android에서 실행한 TUNER 대기 화면" width="260">

## 기능

- 상단 TUNER 텍스트와 흰색 세그먼트 음명, 오른쪽 아래 옥타브
- 플랫 기호 없이 C / C# / D / D# / E / F / F# / G / G# / A / A# / B 표시
- 위·아래 각각 5개 × 5줄 LED: 높은 음은 위쪽, 낮은 음은 아래쪽으로 누적 점등
- 중앙부터 초록 → 노랑 → 주황 → 주홍 → 빨강, 정음은 중앙 초록 화살표
- 하단 패널에서 A4 기준 430~450 Hz를 버튼·슬라이더로 변경하고 기기에 저장
- 별도 isolate에서 YIN 기본 주파수 분석, 무음·잡음 필터링과 표시 안정화
- 마이크 권한·오디오 중단·앱 백그라운드 처리. 오디오 파일 저장 및 외부 전송 없음
- 화면 비율·회전에 따른 자동 배치와 노치·카메라·하단 시스템 내비게이션 안전 여백

## 개발 환경과 실행

검증 환경: Flutter 3.47.9 / Dart 3.13.7 / JDK 21 / Android API 36. Android 최소 지원 버전은 API 24입니다. iOS 프로젝트는 포함하지만 아직 빌드·검증하지 않았습니다.

```sh
flutter pub get
flutter run
```

소유자의 Windows 개발 환경에서는 먼저 다음을 실행합니다. SDK·캐시·임시 경로를 X:로 유지합니다.

```powershell
. X:\Dev\Activate-Dev.ps1
Set-Location X:\Github\Tuner
flutter run
```

앱을 열면 마이크가 자동으로 시작됩니다. 처음 표시되는 마이크 권한 요청을 허용한 뒤 한 음씩 연주하세요. 백그라운드에서는 마이크를 종료하고 앱으로 돌아오면 자동으로 다시 시작합니다. 하단 Hz는 측정값이 아닌 A4 기준음이며, 현재 측정 주파수와 센트는 패널 위에 작게 표시됩니다.

## 검증과 APK

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --coverage
flutter build apk --debug
```

테스트 APK: `build/app/outputs/flutter-apk/app-debug.apk`. `tool/build_android.ps1`로 빌드하면 `Tuner.apk`도 생성합니다. GitHub Actions는 포맷·정적 분석·테스트·Android debug 빌드를 검증하며 APK를 자동 업로드하지 않습니다. APK와 build 폴더는 Git에 포함하지 않습니다.

합성 PCM 신호, 무음·잡음·강한 배음, 음명·센트·LED 경계, 세션 수명, 설정 저장, 화면 크기와 글자 확대를 자동 검증합니다. 실제 악기·휴대폰 마이크의 정확도와 지연은 별도 실기 검증이 필요합니다.

## 문서

앱 표시 이름은 `Tuner`입니다. 제공된 앱 아이콘 원본은 `assets/branding/app_icon.png`에 보관하며, 아이콘 변경 시 `dart run flutter_launcher_icons`로 Android와 iOS 크기별 아이콘을 재생성합니다. 시작 화면에는 아이콘을 표시하지 않습니다.

- [설계와 오디오 처리](docs/architecture.md)
- [코드 컨벤션과 기여](CONTRIBUTING.md)
- [서명과 배포 준비](docs/release.md)
- [실행한 검증과 범위](docs/testing.md)
- [옥타브 확인과 시작 최적화](docs/startup-and-pitch.md)
- [작은 소리 감도 조절과 Tuner.apk 빌드](docs/sensitivity.md)

현재 식별자는 `com.jjw.tuner`입니다. 첫 출시 전 소유자 식별자를 확정해야 하며, 릴리스 키는 로컬에서 별도로 설정합니다. 이 저장소는 비밀키·SDK 절대경로·빌드 결과물을 추적하지 않습니다.
