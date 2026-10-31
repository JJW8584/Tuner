import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';

import 'package:tuner/features/tuner/domain/yin_pitch_detector.dart';

/// A repeatable local CPU microbenchmark, not an app-startup measurement.
void main() {
  const iterations = 200;
  var checksum = 0.0;
  for (final hz in [41.203, 110.0, 440.0, 880.0]) {
    final samples = Float64List.fromList(
      List.generate(4096, (i) => 0.2 * math.sin(2 * math.pi * hz * i / 44100)),
    );
    final detector = YinPitchDetector();
    for (var i = 0; i < 100; i++) {
      detector.detect(samples);
    }
    final clock = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      checksum += detector.detect(samples)?.frequencyHz ?? 0;
    }
    clock.stop();
    // stdout keeps this development tool separate from application logging.
    stdout.writeln(
      '$hz Hz: ${(clock.elapsedMicroseconds / iterations).toStringAsFixed(1)} us/frame',
    );
  }
  stdout.writeln('checksum=${checksum.toStringAsFixed(2)}');
}
