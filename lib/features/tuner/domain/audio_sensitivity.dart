/// Shared input gates for the detector and presentation layer.
/// Tune these values here instead of maintaining separate acceptance thresholds.
abstract final class AudioSensitivity {
  /// Normalized PCM RMS (0..1). Lower values accept quieter instrument sustain.
  /// 0.0003 is about -70.5 dBFS, 20 dB below the previous 0.003 gate.
  static const double minimumRms = 0.0003;

  /// Higher values tolerate less periodic/noisier signals; keep this modest
  /// to avoid accepting room noise as a musical note.
  static const double yinThreshold = 0.20;
  static const double minimumConfidence = 1 - yinThreshold;

  /// Bridges brief rejected frames; valid new pitches still update immediately.
  static const Duration readingHoldDuration = Duration(milliseconds: 500);
}
