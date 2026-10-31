import 'pitch_estimate.dart';

abstract interface class PitchSource {
  /// Null means the current frame is silent or has no reliable pitch.
  Stream<PitchEstimate?> get estimates;

  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}

enum AudioInputFailure {
  permissionDenied,
  unsupported,
  interrupted,
  unavailable,
}

class AudioInputException implements Exception {
  const AudioInputException(this.reason);

  final AudioInputFailure reason;

  @override
  String toString() => 'AudioInputException(${reason.name})';
}
