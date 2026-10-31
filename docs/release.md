# Android 배포 준비

현재 검증 산출물은 테스트 설치용 debug APK입니다. Play Console 업로드와 공개 배포는 아직 수행하지 않았습니다. iOS는 플랫폼 골격과 마이크 사용 설명을 포함하지만 Windows에서 빌드하지 않았습니다.

## 식별자와 서명

현재 Android applicationId와 iOS bundle identifier는 `com.jjw.tuner`입니다. 첫 출시 전에 소유자가 사용할 영구 식별자인지 확인해야 합니다. Android applicationId는 `android/app/build.gradle.kts`에서 관리합니다.

릴리스는 debug 키로 대체하지 않습니다. 로컬 `android/key.properties`에 실제 업로드 키를 설정해야 합니다. 예시는 `android/key.properties.example`을 복사해 사용하며 실제 파일과 키는 Git에서 제외됩니다.

키는 프로젝트 밖 X: 경로에 생성하고 비밀번호를 대화형으로 입력하세요.

```powershell
New-Item -ItemType Directory -Force X:\Dev\Signing
keytool -genkeypair -v -keystore X:\Dev\Signing\tuner-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`key.properties`의 경로에는 `X:/Dev/Signing/tuner-upload.jks`처럼 슬래시를 사용할 수 있습니다. 키와 비밀번호는 별도로 백업하고 공유 저장소에는 올리지 않습니다.

```sh
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

Google Play에는 서명된 AAB를 준비합니다. 버전은 `pubspec.yaml`의 `version`에서 관리합니다. 계정 등록, 스토어 설명·스크린샷, 데이터 보안·개인정보 처리방침과 실제 기기 검증은 배포 전에 완료해야 합니다. 계정별 테스트 요건과 대상 API 정책은 출시 시점의 Play Console에서 확인합니다.

## 기기 검증

- 마이크 허용 / 거부 / 설정에서 권한 회수 / 재시작
- 기타 개방현, 베이스 E1, 고음, 배음이 강한 입력과 무음 복귀
- 기준음 430 / 440 / 442 / 450 Hz와 재실행 후 복원
- 음이 높거나 낮을 때 LED 방향·줄 수·중앙 정음 표시
- 통화·다른 오디오 앱·화면 잠금·백그라운드 진입 후 마이크 해제
- 작은 화면 / 가로 화면 / 글자 확대와 실제 음향 환경

관련 문서: [Flutter Android 배포](https://docs.flutter.dev/deployment/android).
