/// The frequency of A4 used to derive all equal-tempered note frequencies.
abstract final class TuningReference {
  static const double defaultHz = 440;
  static const double minimumHz = 430;
  static const double maximumHz = 450;

  static double normalize(double value) => value.isFinite
      ? value.clamp(minimumHz, maximumHz).roundToDouble()
      : defaultHz;
}
