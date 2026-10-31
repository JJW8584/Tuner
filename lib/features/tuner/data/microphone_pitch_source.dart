import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../domain/pitch_estimate.dart';
import '../domain/pitch_source.dart';
import 'pitch_worker.dart';

class MicrophonePitchSource implements PitchSource {
  MicrophonePitchSource({AudioRecorder? recorder, PitchWorker? worker})
    : _recorder = recorder ?? AudioRecorder(),
      _worker = worker ?? PitchWorker();

  final AudioRecorder _recorder;
  final PitchWorker _worker;
  final _estimates = StreamController<PitchEstimate?>.broadcast();
  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<PitchEstimate?>? _pitchSubscription;
  StreamSubscription<RecordState>? _stateSubscription;
  bool _active = false;
  bool? _supportsPcm16;

  @override
  Stream<PitchEstimate?> get estimates => _estimates.stream;

  @override
  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw const AudioInputException(AudioInputFailure.permissionDenied);
    }
    await Future.wait([_ensureSupportedEncoder(), _worker.start()]);
    _pitchSubscription = _worker.estimates.listen(
      _estimates.add,
      onError: _estimates.addError,
    );
    final audio = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 44100,
        numChannels: 1,
        streamBufferSize: 4096,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.unprocessed,
          manageBluetooth: false,
        ),
      ),
    );
    _active = true;
    _audioSubscription = audio.listen(
      _worker.addBytes,
      onError: _estimates.addError,
      onDone: () {
        if (_active) _reportInterruption();
      },
    );
    _stateSubscription = _recorder.onStateChanged().listen((state) {
      if (_active && state != RecordState.record) _reportInterruption();
    }, onError: _estimates.addError);
  }

  Future<void> _ensureSupportedEncoder() async {
    _supportsPcm16 ??= await _recorder.isEncoderSupported(
      AudioEncoder.pcm16bits,
    );
    if (!_supportsPcm16!) {
      throw const AudioInputException(AudioInputFailure.unsupported);
    }
  }

  void _reportInterruption() => _estimates.addError(
    const AudioInputException(AudioInputFailure.interrupted),
  );

  @override
  Future<void> stop() async {
    _active = false;
    await _audioSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _pitchSubscription?.cancel();
    _audioSubscription = null;
    _stateSubscription = null;
    _pitchSubscription = null;
    try {
      await _recorder.stop();
    } finally {
      await _worker.stop();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    await _worker.dispose();
    await _estimates.close();
  }
}
