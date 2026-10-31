import 'dart:math' as math;

/// A three-frame median rejects transients; log smoothing preserves cent scale.
class PitchStabilizer {
  final List<double> _history = [];
  double? _smoothedSemitones;

  double add(double frequencyHz) {
    final semitones = 12 * math.log(frequencyHz) / math.ln2;
    _history.add(semitones);
    if (_history.length > 3) _history.removeAt(0);
    final sorted = [..._history]..sort();
    final median = sorted[sorted.length ~/ 2];
    final previous = _smoothedSemitones;
    _smoothedSemitones = previous == null || (median - previous).abs() > 0.65
        ? median
        : previous + 0.4 * (median - previous);
    return math.pow(2, _smoothedSemitones! / 12).toDouble();
  }

  void reset() {
    _history.clear();
    _smoothedSemitones = null;
  }
}
