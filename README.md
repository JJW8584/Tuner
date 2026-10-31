# Tuner


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

합성 PCM 신호, 무음·잡음·강한 배음, 음명·센트·LED 경계, 세션 수명, 설정 저장, 화면 크기와 글자 확대를 자동 검증합니다. 실제 악기·휴대폰 마이크의 정확도와 지연은 별도 실기 검증이 필요합니다.


