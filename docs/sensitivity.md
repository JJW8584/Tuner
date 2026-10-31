# 작은 소리 감도 조절

감도 설정은 `lib/features/tuner/domain/audio_sensitivity.dart` 한 파일에서 관리합니다. 검출기와 화면 컨트롤러가 이 값을 함께 사용하므로 한쪽만 수정해 약한 음이 다시 버려지는 일을 피합니다.

| 설정 | 현재 값 | 조절 방법 |
|---|---|---|
| `minimumRms` | `0.0003` | 작을수록 작은 입력을 받습니다. 가장 먼저 조절할 값입니다. |
| `yinThreshold` | `0.20` | 커질수록 잡음이 섞여 주기성이 약한 신호도 허용합니다. |
| `minimumConfidence` | `1 - yinThreshold` | 위 값에서 자동 계산되며 검출기와 표시 필터에 함께 적용됩니다. |
| `readingHoldDuration` | `500ms` | 유효 피치가 잠깐 끊겼을 때 기존 표시를 유지하는 시간입니다. 작은 소리 검출 자체를 강화하는 설정은 아닙니다. |

기존 `minimumRms = 0.003`은 약 -50.5 dBFS였고, 현재 `0.0003`은 약 -70.5 dBFS입니다. 정규화된 PCM 진폭 기준 10분의 1인 입력까지 허용하도록 문턱을 낮췄습니다.

더 작은 소리를 받고 싶으면 먼저 다음처럼 바꿔 보세요.

```dart
static const double minimumRms = 0.00015;
```

그다음에도 주기성이 약한 기타 잔향이 끊기면 `yinThreshold`를 `0.20`에서 `0.22` 정도로 조금씩 올릴 수 있습니다. 값을 크게 올리면 주변 소음이나 배음을 음으로 판단할 수 있으므로 한 번에 한 설정만 바꾸어 확인하세요. 이 앱은 PCM을 메모리에서 분석하며 소리를 녹음 파일로 저장하지 않습니다.

## 수정 후 테스트와 APK

이 PC의 PowerShell에서:

```powershell
. X:\Dev\Activate-Dev.ps1
Set-Location X:\Github\Tuner
dart format lib test
flutter analyze --fatal-infos
flutter test
.\tool\build_android.ps1
```

결과 파일은 `build/app/outputs/flutter-apk/Tuner.apk`입니다. 기본 빌드는 디버그이며, `-Mode release`는 별도의 릴리스 서명 설정이 필요합니다.

자동 테스트에는 기타 E2 / A2 / D3 / G3 / B3 / E4의 작은 합성 입력, 약 2.8초 동안 감쇠하는 E2, 무음·DC·비주기 잡음 제외, 표시 필터 통과 여부가 포함됩니다. 실제 기타·마이크 조합에서는 입력 레벨과 하드웨어 잡음 억제에 따라 결과가 달라질 수 있습니다.
