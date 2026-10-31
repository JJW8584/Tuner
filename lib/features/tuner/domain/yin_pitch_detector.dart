import 'dart:math' as math;
import 'dart:typed_data';

import 'pitch_estimate.dart';
import 'audio_sensitivity.dart';

/// YIN difference-function estimator for monophonic instrument input.
///
/// Operates on a complete 4096-sample PCM frame at 44.1 kHz. Pair averaging
/// halves analysis cost. No FFT peak picking: harmonics must not become notes.
class YinPitchDetector {
  YinPitchDetector({
    this.sampleRate = 44100,
    this.minimumFrequencyHz = 40,
    this.maximumFrequencyHz = 2000,
    this.minimumRms = AudioSensitivity.minimumRms,
    this.threshold = AudioSensitivity.yinThreshold,
    this.minimumConfidence = AudioSensitivity.minimumConfidence,
  });

  final int sampleRate;
  final double minimumFrequencyHz;
  final double maximumFrequencyHz;
  final double minimumRms;
  final double threshold;
  final double minimumConfidence;
  Float64List _reduced = Float64List(0);
  Float64List _difference = Float64List(0);

  PitchEstimate? detect(Float64List samples) {
    if (samples.length < 2048) return null;
    var mean = 0.0;
    for (final sample in samples) {
      mean += sample;
    }
    mean /= samples.length;
    if (_reduced.length != samples.length ~/ 2) {
      _reduced = Float64List(samples.length ~/ 2);
    }
    final reduced = _reduced;
    var sumSquares = 0.0;
    for (var i = 0; i < reduced.length; i++) {
      final sample = (samples[i * 2] + samples[i * 2 + 1]) / 2 - mean;
      reduced[i] = sample;
      sumSquares += sample * sample;
    }
    final rms = math.sqrt(sumSquares / reduced.length);
    if (!rms.isFinite || rms < minimumRms) return null;
    final analysisRate = sampleRate / 2;
    final window = reduced.length ~/ 2;
    final minimumLag = math.max(2, (analysisRate / maximumFrequencyHz).floor());
    final maximumLag = math.min(
      window - 1,
      (analysisRate / minimumFrequencyHz).ceil(),
    );
    if (_difference.length != maximumLag + 1) {
      _difference = Float64List(maximumLag + 1);
    }
    final difference = _difference;
    difference[0] = 1;
    var cumulative = 0.0;
    int? candidateLag;
    for (var lag = 1; lag <= maximumLag; lag++) {
      var value = 0.0;
      for (var i = 0; i < window; i++) {
        final delta = reduced[i] - reduced[i + lag];
        value += delta * delta;
      }
      cumulative += value;
      difference[lag] = cumulative == 0 ? 1 : value * lag / cumulative;
      if (lag < minimumLag) continue;
      if (candidateLag == null) {
        if (difference[lag] < threshold) candidateLag = lag;
      } else if (difference[lag] < difference[candidateLag]) {
        candidateLag = lag;
      } else {
        // The first qualifying minimum and its right neighbor are complete;
        // computing all lower-frequency lags would not change YIN's result.
        break;
      }
    }
    final lag = candidateLag;
    if (lag == null || lag >= maximumLag) return null;
    final confidence = 1 - difference[lag];
    if (confidence < minimumConfidence) return null;
    final left = difference[lag - 1];
    final center = difference[lag];
    final right = difference[lag + 1];
    final denominator = 2 * (2 * center - right - left);
    final correction = denominator.abs() < 1e-12
        ? 0.0
        : (right - left) / denominator;
    // Refine on original-rate samples. Interpolation at the reduced rate is
    // biased near the upper range, where one period spans only ~11 samples.
    final originalLag = ((lag + correction.clamp(-1.0, 1.0)) * 2).round();
    double originalDifference(int period) {
      var value = 0.0;
      for (var i = 0; i < samples.length ~/ 2; i++) {
        final delta = samples[i] - samples[i + period];
        value += delta * delta;
      }
      return value;
    }

    final originalLeft = originalDifference(originalLag - 1);
    final originalCenter = originalDifference(originalLag);
    final originalRight = originalDifference(originalLag + 1);
    final originalDenominator =
        2 * (2 * originalCenter - originalRight - originalLeft);
    final originalCorrection = originalDenominator.abs() < 1e-12
        ? 0.0
        : (originalRight - originalLeft) / originalDenominator;
    final frequency =
        sampleRate / (originalLag + originalCorrection.clamp(-1.0, 1.0));
    if (frequency < minimumFrequencyHz || frequency > maximumFrequencyHz) {
      return null;
    }
    return PitchEstimate(
      frequencyHz: frequency,
      confidence: confidence,
      rms: rms,
    );
  }
}
