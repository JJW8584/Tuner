# Development conventions

- Use Effective Dart: snake_case files, UpperCamelCase types, lowerCamelCase members, private implementation with `_`.
- Organize code by feature. Keep `domain/` pure Dart, plugin adapters in `data/`, and widgets/state orchestration in `presentation/`.
- Inject `PitchSource` and `ReferenceRepository`; do not call plugins from widgets or the domain.
- Keep audio analysis outside the UI isolate. Retain PCM sample ordering and the configured sample rate.
- Keep note spelling sharp-only and scientific octave numbering (A4 = MIDI 69).
- Render the header as TUNER text, keep the 5-by-5 LED banks, and start the microphone automatically. Do not introduce a microphone toggle or an A4 REFERENCE heading.
- Follow existing Korean interface copy and English code identifiers/documentation comments.
- Run `dart format lib test`, `flutter analyze --fatal-infos`, and `flutter test` after relevant changes. Build Android for changes to plugins/native configuration.
- Never commit signing keys, key.properties, SDK paths, generated builds, or audio recordings.
- On the owner's Windows workstation, activate `X:\Dev\Activate-Dev.ps1` before running tools. Keep downloads, SDKs, caches, and temporary files on X:.
- Android is the validated target. Preserve iOS scaffold compatibility, but do not claim iOS build validation without macOS/Xcode.
