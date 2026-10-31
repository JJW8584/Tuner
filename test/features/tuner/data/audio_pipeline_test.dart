import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuner/features/tuner/data/pcm_frame_buffer.dart';
import 'package:tuner/features/tuner/data/pitch_worker.dart';

import '../../../support/audio_fixtures.dart';

void main() {
  test('PCM decoder preserves signed samples across odd chunks and overlapping frames', () {
    final bytes = ByteData(12);
    final samples = [-32768, -16000, 0, 16000, 20000, 32767];
    for (var i = 0; i < samples.length; i++) {
      bytes.setInt16(i * 2, samples[i], Endian.little);
    }
    final data = bytes.buffer.asUint8List();
    final buffer = PcmFrameBuffer(frameSize: 4, hopSize: 2);
    final frames = [
      ...buffer.addBytes(data.sublist(0, 3)),
      ...buffer.addBytes(data.sublist(3, 7)),
      ...buffer.addBytes(data.sublist(7)),
    ];
    expect(frames.length, 2);
    expect(frames[0], samples.take(4).map((sample) => sample / 32768));
    expect(frames[1], samples.skip(2).map((sample) => sample / 32768));
  });
  test(
    'analysis isolate detects PCM and supports a clean session restart',
    () async {
      final worker = PitchWorker();
      try {
        for (var session = 0; session < 2; session++) {
          await worker.start();
          final result = worker.estimates.first.timeout(
            const Duration(seconds: 5),
          );
          final frame = signal(440);
          final bytes = ByteData(frame.length * 2);
          for (var i = 0; i < frame.length; i++) {
            bytes.setInt16(i * 2, (frame[i] * 32767).round(), Endian.little);
          }
          worker.addBytes(bytes.buffer.asUint8List());
          expect((await result)!.frequencyHz, closeTo(440, 0.5));
          await worker.stop();
        }
      } finally {
        await worker.dispose();
      }
    },
  );
}
