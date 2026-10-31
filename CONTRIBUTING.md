# 개발 가이드

Flutter stable 3.47.9 / Dart 3.13.7과 JDK 21을 기준으로 개발합니다.

```sh
flutter pub get
dart format lib test
flutter analyze --fatal-infos
flutter test --coverage
flutter build apk --debug
```

파일은 `snake_case.dart`, 타입은 `UpperCamelCase`, 변수·메서드는 `lowerCamelCase`를 사용합니다. 포맷은 Dart formatter와 `.editorconfig`, 정적 분석은 `analysis_options.yaml`을 따릅니다.

도메인은 Flutter와 플러그인을 참조하지 않습니다. 외부 오디오·저장소는 인터페이스로 주입하고, 단일 화면에 불필요한 라우터나 서비스 로케이터를 도입하지 않습니다. 비동기 자원은 세션 종료·백그라운드 진입·dispose에서 해제해야 합니다.

커밋 메시지는 `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:` 접두사를 권장합니다. PR에는 동작 변화와 실제 실행한 검증을 기록합니다.

`pubspec.lock`은 앱의 재현 가능한 빌드를 위해 커밋합니다. 생성된 SDK 경로, 인증정보, 빌드 산출물은 커밋하지 않습니다. 프로젝트의 공개 라이선스는 소유자가 결정하기 전까지 임의로 지정하지 않습니다.
