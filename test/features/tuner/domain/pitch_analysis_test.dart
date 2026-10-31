import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuner/features/tuner/domain/led_meter.dart';
import 'package:tuner/features/tuner/domain/pitch_stabilizer.dart';
import 'package:tuner/features/tuner/domain/tuning_reading.dart';
import 'package:tuner/features/tuner/domain/yin_pitch_detector.dart';

import '../../../support/audio_fixtures.dart';

void main() {
  group('YIN pitch analysis', () {
    for (final hz in [
      41.203,
      55.0,
      82.407,
      110.0,
      261.626,
      440.0,
      880.0,
      1318.51,
      1975.53,
    ]) {
      test('detects $hz Hz within two cents', () {
        final estimate = YinPitchDetector().detect(signal(hz));
        expect(estimate, isNotNull);
        final cents = 1200 * math.log(estimate!.frequencyHz / hz) / math.ln2;
        expect(cents.abs(), lessThan(2));
      });
    }
    test('finds fundamental under stronger harmonics and moderate noise', () {
      for (final hz in [82.407, 110.0, 220.0, 440.0]) {
        final estimate = YinPitchDetector().detect(
          signal(hz, harmonics: true, noise: 0.015),
        );
        expect(estimate, isNotNull);
        expect(
          (1200 * math.log(estimate!.frequencyHz / hz) / math.ln2).abs(),
          lessThan(3),
        );
      }
    });
    test('rejects silence, DC offset and unpitched noise', () {
      final detector = YinPitchDetector();
      expect(detector.detect(Float64List(4096)), isNull);
      expect(
        detector.detect(Float64List.fromList(List.filled(4096, 0.2))),
        isNull,
      );
      final random = math.Random(42);
      expect(
        detector.detect(
          Float64List.fromList(
            List.generate(4096, (_) => random.nextDouble() - 0.5),
          ),
        ),
        isNull,
      );
    });
  });

  test('maps all twelve pitch classes using sharps and scientific octaves', () {
    for (var midi = 24; midi <= 107; midi++) {
      final hz = (440 * math.pow(2, (midi - 69) / 12)).toDouble();
      final reading = TuningReading.fromFrequency(hz, referenceHz: 440);
      expect(reading.midiNote, midi);
      expect(reading.noteName, TuningReading.noteNames[midi % 12]);
      expect(reading.octave, midi ~/ 12 - 1);
      expect(reading.noteName.contains('b'), isFalse);
    }
  });
  test(
    'recalibration changes cents without changing the measured frequency',
    () {
      final reading = TuningReading.fromFrequency(442, referenceHz: 442);
      expect(reading.noteName, 'A');
      expect(reading.octave, 4);
      expect(reading.cents, closeTo(0, 1e-8));
      expect(
        TuningReading.fromFrequency(440, referenceHz: 442).cents,
        lessThan(0),
      );
      expect(
        () => TuningReading.fromFrequency(double.nan, referenceHz: 440),
        throwsArgumentError,
      );
    },
  );
  test('LED rows accumulate symmetrically with a stable threshold band', () {
    TuningReading reading(double cents) => TuningReading.fromFrequency(
      (440 * math.pow(2, cents / 1200)).toDouble(),
      referenceHz: 440,
    );
    for (final sign in [-1, 1]) {
      for (final item in [
        (5.0, 1),
        (15.0, 2),
        (25.0, 3),
        (35.0, 4),
        (45.0, 5),
      ]) {
        final meter = LedMeter.fromReading(reading(sign * item.$1));
        expect(meter.activeRows, item.$2);
        expect(
          meter.direction,
          sign > 0 ? PitchDirection.sharp : PitchDirection.flat,
        );
      }
    }
    expect(LedMeter.fromReading(reading(2)).activeRows, 0);
    const previous = LedMeter(direction: PitchDirection.sharp, activeRows: 2);
    expect(
      LedMeter.fromReading(reading(9.8), previous: previous).activeRows,
      2,
    );
  });
  test('median stabilization rejects a single octave glitch', () {
    final stabilizer = PitchStabilizer();
    stabilizer.add(440);
    stabilizer.add(440);
    expect(stabilizer.add(880), closeTo(440, 0.01));
    stabilizer.reset();
    expect(stabilizer.add(220), closeTo(220, 0.01));
  });
}
