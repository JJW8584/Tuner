import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../domain/pitch_estimate.dart';
import '../domain/yin_pitch_detector.dart';
import 'pcm_frame_buffer.dart';

/// Owns one long-lived analysis isolate per microphone session.
class PitchWorker {
  final _estimates = StreamController<PitchEstimate?>.broadcast();
  Isolate? _isolate;
  SendPort? _input;
  ReceivePort? _results;
  ReceivePort? _errors;
  StreamSubscription<dynamic>? _resultSubscription;
  StreamSubscription<dynamic>? _errorSubscription;

  Stream<PitchEstimate?> get estimates => _estimates.stream;

  Future<void> start() async {
    await stop();
    final ready = Completer<SendPort>();
    _results = ReceivePort();
    _errors = ReceivePort();
    _resultSubscription = _results!.listen((dynamic message) {
      if (message is SendPort) {
        ready.complete(message);
      } else if (message == null) {
        _estimates.add(null);
      } else if (message is List<double>) {
        _estimates.add(
          PitchEstimate(
            frequencyHz: message[0],
            confidence: message[1],
            rms: message[2],
          ),
        );
      }
    });
    _errorSubscription = _errors!.listen((dynamic error) {
      if (!ready.isCompleted) {
        ready.completeError(StateError('Pitch worker failed: $error'));
      }
      _estimates.addError(StateError('Pitch worker failed: $error'));
    });
    _isolate = await Isolate.spawn(
      _analyzeAudio,
      _results!.sendPort,
      onError: _errors!.sendPort,
      errorsAreFatal: true,
      debugName: 'tuner.pitch',
    );
    _input = await ready.future.timeout(const Duration(seconds: 5));
  }

  void addBytes(Uint8List bytes) =>
      _input?.send(TransferableTypedData.fromList([bytes]));

  Future<void> stop() async {
    _input = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    await _resultSubscription?.cancel();
    await _errorSubscription?.cancel();
    _resultSubscription = null;
    _errorSubscription = null;
    _results?.close();
    _errors?.close();
    _results = null;
    _errors = null;
  }

  Future<void> dispose() async {
    await stop();
    await _estimates.close();
  }
}

void _analyzeAudio(SendPort results) {
  final input = ReceivePort();
  final buffer = PcmFrameBuffer();
  final detector = YinPitchDetector();
  results.send(input.sendPort);
  input.listen((dynamic message) {
    if (message is! TransferableTypedData) return;
    for (final frame in buffer.addBytes(message.materialize().asUint8List())) {
      final pitch = detector.detect(frame);
      results.send(
        pitch == null
            ? null
            : <double>[pitch.frequencyHz, pitch.confidence, pitch.rms],
      );
    }
  });
}
