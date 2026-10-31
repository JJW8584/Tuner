import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/tuner_app.dart';
import 'features/tuner/data/microphone_pitch_source.dart';
import 'features/tuner/data/preferences_reference_repository.dart';
import 'features/tuner/presentation/tuner_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF030404),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    TunerApp(
      controller: TunerController(
        pitchSource: MicrophonePitchSource(),
        referenceRepository: PreferencesReferenceRepository(),
      ),
    ),
  );
}
