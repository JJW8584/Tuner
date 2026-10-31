# GitHub 저장소 포함·제외 기준

저장소 이름은 `Tuner`, 기본 브랜치는 `main`입니다.

## 포함

- Dart 소스와 테스트, Android / iOS 플랫폼 소스
- `pubspec.yaml`, `pubspec.lock`, Flutter `.metadata`
- Gradle wrapper 스크립트·JAR·버전 설정: 새 환경에서 같은 빌드 도구를 사용하기 위한 파일
- 앱 아이콘 원본 및 플랫폼별 아이콘 리소스
- 문서와 검증에 필요한 스크린샷
- GitHub CI, 정적 분석·포맷 설정, 기기 경로가 없는 공용 VS Code 실행 설정
- 비밀값 대신 자리표시자를 사용하는 `android/key.properties.example`

## 제외

- APK / AAB / IPA 및 기타 배포 파일, 빌드·커버리지·디버그 산출물
- Flutter / Gradle / Kotlin / C++ / Xcode 캐시와 생성된 플러그인·SDK 경로
- `.idea`, 사용자별 IDE 상태, 로컬 VS Code 설정
- 실제 `key.properties`, keystore, 개인키, 인증서 번들, 프로비저닝 프로필
- `.env`와 자격증명·서비스 계정 파일
- 마이크 녹음, 로그, 다운로드 압축 파일, `work` 등 임시 작업 폴더

파일을 실제로 삭제하지 않고 `.gitignore`로 제외합니다. 배포용 APK는 로컬에서 빌드하며 CI도 APK를 자동 업로드하지 않습니다.

새 파일을 추가할 때는 `git status --short`와 `git diff --cached`로 포함 내용을 확인하세요. 이미 추적 중인 파일은 `.gitignore`를 추가해도 자동으로 제외되지 않습니다. 실제 비밀값을 커밋한 경우에는 파일 삭제만으로 해결되지 않으므로 해당 비밀값을 폐기·교체하고 Git 이력도 별도로 정리해야 합니다.
