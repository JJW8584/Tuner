/// A voiced fundamental-frequency estimate, independent of A4 calibration.
class PitchEstimate {
  const PitchEstimate({
    required this.frequencyHz,
    required this.confidence,
    required this.rms,
  });

  final double frequencyHz;
  final double confidence;
  final double rms;
}
