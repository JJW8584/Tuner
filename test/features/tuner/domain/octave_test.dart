import 'package:flutter_test/flutter_test.dart';
import 'package:tuner/features/tuner/domain/tuning_reading.dart';
import 'package:tuner/features/tuner/domain/yin_pitch_detector.dart';

import 'dart:typed_data';

import '../../../support/audio_fixtures.dart';

void main() {
  // Independent frequency table: do not derive expectations from the MIDI code.
  final notes = [
    (hz: 41.203445, name: 'E', octave: 1),
    (hz: 55.0, name: 'A', octave: 1),
    (hz: 61.735413, name: 'B', octave: 1),
    (hz: 65.406391, name: 'C', octave: 2),
    (hz: 82.406889, name: 'E', octave: 2),
    (hz: 110.0, name: 'A', octave: 2),
    (hz: 220.0, name: 'A', octave: 3),
    (hz: 246.941651, name: 'B', octave: 3),
    (hz: 261.625565, name: 'C', octave: 4),
    (hz: 277.182631, name: 'C#', octave: 4),
    (hz: 440.0, name: 'A', octave: 4),
    (hz: 493.883301, name: 'B', octave: 4),
    (hz: 523.251131, name: 'C', octave: 5),
    (hz: 880.0, name: 'A', octave: 5),
    (hz: 1046.502261, name: 'C', octave: 6),
    (hz: 1975.533205, name: 'B', octave: 6),
  ];
  for (final note in notes) {
    test('${note.hz} Hz decodes to ${note.name}${note.octave}', () {
      final estimate = YinPitchDetector().detect(signal(note.hz));
      expect(estimate, isNotNull);
      final reading = TuningReading.fromFrequency(
        estimate!.frequencyHz,
        referenceHz: 440,
      );
      expect(reading.noteName, note.name);
      expect(reading.octave, note.octave);
      expect(reading.cents.abs(), lessThan(2));
    });
  }
  test(
    'one detector follows octave changes without retaining the previous period',
    () {
      final detector = YinPitchDetector();
      for (final item in [(440.0, 4), (880.0, 5), (110.0, 2), (220.0, 3)]) {
        final estimate = detector.detect(signal(item.$1));
        expect(estimate, isNotNull);
        expect(
          TuningReading.fromFrequency(
            estimate!.frequencyHz,
            referenceHz: 440,
          ).octave,
          item.$2,
        );
        expect(detector.detect(Float64List(4096)), isNull);
      }
    },
  );
}
