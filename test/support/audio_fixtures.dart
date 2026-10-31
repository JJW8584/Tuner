import 'dart:math' as math;
import 'dart:typed_data';

/// Deterministic 44.1 kHz frames for detector and streaming-pipeline tests.
Float64List signal(double hz, {bool harmonics = false, double noise = 0}) {
  final random = math.Random(7);
  return Float64List.fromList(
    List.generate(4096, (i) {
      final phase = 2 * math.pi * hz * i / 44100;
      return 0.2 * math.sin(phase) +
          (harmonics
              ? 0.35 * math.sin(2 * phase) + 0.15 * math.sin(3 * phase)
              : 0) +
          noise * (random.nextDouble() * 2 - 1);
    }),
  );
}
