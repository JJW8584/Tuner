import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/led_meter.dart';
import '../domain/audio_sensitivity.dart';
import '../domain/pitch_estimate.dart';
import '../domain/pitch_source.dart';
import '../domain/pitch_stabilizer.dart';
import '../domain/reference_repository.dart';
import '../domain/tuning_reading.dart';
import '../domain/tuning_reference.dart';

enum TunerStatus { idle, starting, listening, stopping, failed }

/// Owns presentation state and serializes microphone-session transitions.
class TunerController extends ChangeNotifier {
  TunerController({
    required this._pitchSource,
    required this._referenceRepository,
  });
  final PitchSource _pitchSource;
  final ReferenceRepository _referenceRepository;
  final PitchStabilizer _stabilizer = PitchStabilizer();
  final Stopwatch _clock = Stopwatch();
  StreamSubscription<PitchEstimate?>? _subscription;
  Future<void> _operations = Future<void>.value();
  Future<void> _saves = Future<void>.value();
  Timer? _watchdog;
  Timer? _saveDebounce;
  bool _disposed = false;
  bool _requestedListening = false;
  bool _referenceDirty = false;
  int _referenceRevision = 0;
  int _lastVoicedMilliseconds = 0;
  double? _frequencyHz;
  double _referenceHz = TuningReference.defaultHz;
  double get referenceHz => _referenceHz;
  TunerStatus _status = TunerStatus.idle;
  TunerStatus get status => _status;
  TuningReading? _reading;
  TuningReading? get reading => _reading;
  LedMeter _meter = const LedMeter();
  LedMeter get meter => _meter;
  String? _message;
  String? get message => _message;
  bool get isListening => _status == TunerStatus.listening;
  bool get isBusy =>
      _status == TunerStatus.starting || _status == TunerStatus.stopping;

  Future<void> initialize() async {
    final revision = _referenceRevision;
    try {
      final stored = await _referenceRepository.load();
      if (_disposed || revision != _referenceRevision) return;
      _referenceHz = TuningReference.normalize(stored);
      _recalculateReading();
    } on Exception {
      if (!_disposed) _message = '기준 주파수를 불러오지 못해 440 Hz로 시작합니다.';
    }
    _notify();
  }

  Future<void> start() {
    if (_disposed) return Future<void>.value();
    _requestedListening = true;
    return _serialize(() async {
      if (_disposed || !_requestedListening || isListening) return;
      _status = TunerStatus.starting;
      _message = null;
      _clearReading();
      _notify();
      try {
        _subscription = _pitchSource.estimates.listen(
          _onEstimate,
          onError: _onAudioError,
        );
        await _pitchSource.start();
        if (_disposed || !_requestedListening) {
          await _releaseSession();
          return;
        }
        _status = TunerStatus.listening;
        _clock
          ..reset()
          ..start();
        _lastVoicedMilliseconds = 0;
        _watchdog = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (_reading != null &&
              _clock.elapsedMilliseconds - _lastVoicedMilliseconds >
                  AudioSensitivity.readingHoldDuration.inMilliseconds) {
            _clearReading();
            _notify();
          }
        });
      } on Exception catch (error) {
        await _fail(error);
      }
      _notify();
    });
  }

  Future<void> stop() {
    _requestedListening = false;
    return _serialize(() async {
      _status = TunerStatus.stopping;
      _notify();
      try {
        await _releaseSession();
        _status = TunerStatus.idle;
      } on Exception {
        _status = TunerStatus.failed;
        _message = '마이크를 종료하지 못했습니다. 앱을 다시 실행해 주세요.';
      }
      _clearReading();
      _notify();
    });
  }

  void setReferenceHz(double value) {
    final normalized = TuningReference.normalize(value);
    if (_disposed || normalized == _referenceHz) return;
    _referenceHz = normalized;
    _referenceRevision++;
    _referenceDirty = true;
    _recalculateReading();
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(flushReference());
    });
    _notify();
  }

  /// Serialized saves keep earlier slow writes from overwriting the final value.
  Future<void> flushReference() {
    _saveDebounce?.cancel();
    if (!_referenceDirty) return _saves;
    _referenceDirty = false;
    final value = _referenceHz;
    _saves = _saves.then((_) async {
      try {
        await _referenceRepository.save(value);
      } on Exception {
        _message = '기준 주파수를 저장하지 못했습니다.';
        _referenceDirty = true;
        _notify();
      }
    });
    return _saves;
  }

  void _onEstimate(PitchEstimate? estimate) {
    if (_disposed || !_requestedListening || !isListening || estimate == null) {
      return;
    }
    if (!estimate.frequencyHz.isFinite ||
        estimate.frequencyHz <= 0 ||
        estimate.confidence < AudioSensitivity.minimumConfidence) {
      return;
    }
    _lastVoicedMilliseconds = _clock.elapsedMilliseconds;
    _frequencyHz = _stabilizer.add(estimate.frequencyHz);
    _recalculateReading();
    _notify();
  }

  void _recalculateReading() {
    final frequency = _frequencyHz;
    _reading = frequency == null
        ? null
        : TuningReading.fromFrequency(frequency, referenceHz: _referenceHz);
    _meter = LedMeter.fromReading(_reading, previous: _meter);
  }

  void _clearReading() {
    _frequencyHz = null;
    _reading = null;
    _meter = const LedMeter();
    _stabilizer.reset();
  }

  void _onAudioError(Object error, StackTrace stackTrace) {
    if (_disposed || !_requestedListening) return;
    _requestedListening = false;
    unawaited(
      _serialize(() async {
        await _fail(error);
        _notify();
      }),
    );
  }

  Future<void> _fail(Object error) async {
    _requestedListening = false;
    try {
      await _releaseSession();
    } on Exception {
      /* Preserve the original failure. */
    }
    _status = TunerStatus.failed;
    _clearReading();
    _message = switch (error) {
      AudioInputException(reason: AudioInputFailure.permissionDenied) =>
        '마이크 권한이 필요합니다. 앱 설정에서 허용한 뒤 앱으로 돌아와 주세요.',
      AudioInputException(reason: AudioInputFailure.interrupted) =>
        '다른 앱이나 통화로 마이크가 중단됐습니다. 앱을 다시 열어 주세요.',
      AudioInputException(reason: AudioInputFailure.unsupported) =>
        '이 기기는 필요한 오디오 입력 형식을 지원하지 않습니다.',
      _ => '마이크를 사용할 수 없습니다. 연결을 확인하고 앱을 다시 열어 주세요.',
    };
  }

  Future<void> _releaseSession() async {
    _watchdog?.cancel();
    _watchdog = null;
    _clock.stop();
    await _subscription?.cancel();
    _subscription = null;
    await _pitchSource.stop();
  }

  Future<void> _serialize(Future<void> Function() action) {
    _operations = _operations.then((_) => action());
    return _operations;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _requestedListening = false;
    _watchdog?.cancel();
    _saveDebounce?.cancel();
    unawaited(flushReference());
    unawaited(
      _serialize(() async {
        try {
          await _releaseSession();
        } finally {
          await _pitchSource.dispose();
        }
      }).catchError((Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'tuner',
          ),
        );
      }),
    );
    super.dispose();
  }
}
