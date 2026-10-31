import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuner/features/tuner/domain/audio_sensitivity.dart';
import 'package:tuner/features/tuner/domain/tuning_reading.dart';
import 'package:tuner/features/tuner/domain/yin_pitch_detector.dart';

Float64List guitarFrame(double hz, double amplitude, {int offset = 0}) {
  final random = math.Random(17 + offset);
  return Float64List.fromList(
    List.generate(4096, (i) {
      final phase = 2 * math.pi * hz * (offset + i) / 44100;
      final envelope = math.exp(-i / (2048 * 18));
      return amplitude *
              envelope *
              (0.65 * math.sin(phase) +
                  0.25 * math.sin(phase * 2) +
                  0.1 * math.sin(phase * 3)) +
          0.00002 * (random.nextDouble() * 2 - 1);
    }),
  );
}

void main() {
  for (final string in [
    (82.406889, 'E', 2),
    (110.0, 'A', 2),
    (146.832384, 'D', 3),
    (195.997718, 'G', 3),
    (246.941651, 'B', 3),
    (329.627557, 'E', 4),
  ]) {
    test(
      'quiet ${string.$2}${string.$3} sustain stays recognized below the old gate',
      () {
        final detector = YinPitchDetector();
        final samples = guitarFrame(string.$1, 0.001);
        final estimate = detector.detect(samples);
        expect(estimate, isNotNull);
        expect(estimate!.rms, lessThan(0.003));
        final reading = TuningReading.fromFrequency(
          estimate.frequencyHz,
          referenceHz: 440,
        );
        expect(reading.noteName, string.$2);
        expect(reading.octave, string.$3);
        expect(reading.cents.abs(), lessThan(3));
        expect(YinPitchDetector(minimumRms: 0.003).detect(samples), isNull);
      },
    );
  }

  test(
    'tracks a decaying pluck across frames instead of only the initial attack',
    () {
      final detector = YinPitchDetector();
      for (var frame = 0; frame < 60; frame++) {
        final amplitude = 0.02 * math.exp(-frame / 18);
        final estimate = detector.detect(
          guitarFrame(82.406889, amplitude, offset: frame * 2048),
        );
        expect(estimate, isNotNull, reason: 'Sustain dropped at frame $frame');
        final reading = TuningReading.fromFrequency(
          estimate!.frequencyHz,
          referenceHz: 440,
        );
        expect(reading.noteName, 'E');
        expect(reading.octave, 2);
        expect(reading.cents.abs(), lessThan(3));
      }
    },
  );

  test(
    'sensitive gate still rejects silence, DC and quiet nonperiodic noise',
    () {
      final detector = YinPitchDetector();
      final random = math.Random(7);
      expect(detector.detect(Float64List(4096)), isNull);
      expect(
        detector.detect(Float64List.fromList(List.filled(4096, 0.01))),
        isNull,
      );
      for (final amplitude in [0.0001, 0.001, 0.01]) {
        final noise = Float64List.fromList(
          List.generate(4096, (_) => amplitude * (random.nextDouble() * 2 - 1)),
        );
        expect(detector.detect(noise), isNull);
      }
      expect(
        detector.detect(guitarFrame(110, AudioSensitivity.minimumRms / 10)),
        isNull,
      );
    },
  );
}
