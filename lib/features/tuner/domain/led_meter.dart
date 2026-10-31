import 'tuning_reading.dart';

/// Row zero is nearest the note; row four is the outer red row.
class LedMeter {
  const LedMeter({this.direction = PitchDirection.inTune, this.activeRows = 0});

  factory LedMeter.fromReading(TuningReading? reading, {LedMeter? previous}) {
    if (reading == null) return const LedMeter();
    final distance = reading.cents.abs();
    var direction = reading.direction;
    // A small Schmitt band prevents green/off flicker around ±3 cents.
    if (previous?.direction == PitchDirection.inTune && distance <= 3.5) {
      direction = PitchDirection.inTune;
    } else if (previous != null &&
        previous.direction != PitchDirection.inTune &&
        distance >= 2.5) {
      direction = reading.cents > 0
          ? PitchDirection.sharp
          : PitchDirection.flat;
    }
    if (direction == PitchDirection.inTune) return const LedMeter();
    var rows = 1;
    for (final threshold in rowThresholds.skip(1)) {
      if (distance >= threshold) rows++;
    }
    if (previous != null && previous.direction == direction) {
      if (rows > previous.activeRows &&
          previous.activeRows > 0 &&
          distance < rowThresholds[rows - 1] + 0.75) {
        rows = previous.activeRows;
      } else if (rows < previous.activeRows &&
          distance > rowThresholds[previous.activeRows - 1] - 0.75) {
        rows = previous.activeRows;
      }
    }
    return LedMeter(direction: direction, activeRows: rows);
  }

  static const rowThresholds = [3.0, 10.0, 20.0, 30.0, 40.0];
  final PitchDirection direction;
  final int activeRows;
}
