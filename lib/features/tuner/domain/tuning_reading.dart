import 'dart:math' as math;

enum PitchDirection { flat, inTune, sharp }

/// Equal temperament with scientific pitch notation (MIDI 69 = A4).
class TuningReading {
  const TuningReading({
    required this.frequencyHz,
    required this.midiNote,
    required this.targetFrequencyHz,
    required this.cents,
  });

  factory TuningReading.fromFrequency(
    double frequencyHz, {
    required double referenceHz,
  }) {
    if (!frequencyHz.isFinite ||
        frequencyHz <= 0 ||
        !referenceHz.isFinite ||
        referenceHz <= 0) {
      throw ArgumentError('Frequencies must be finite and positive.');
    }
    final fractionalNote =
        69 + 12 * math.log(frequencyHz / referenceHz) / math.ln2;
    final midiNote = fractionalNote.round();
    final target = referenceHz * math.pow(2, (midiNote - 69) / 12);
    return TuningReading(
      frequencyHz: frequencyHz,
      midiNote: midiNote,
      targetFrequencyHz: target,
      cents: (fractionalNote - midiNote) * 100,
    );
  }

  static const noteNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  static const inTuneToleranceCents = 3.0;

  final double frequencyHz;
  final int midiNote;
  final double targetFrequencyHz;
  final double cents;

  String get noteName => noteNames[midiNote % 12];
  int get octave => (midiNote / 12).floor() - 1;
  PitchDirection get direction => cents.abs() <= inTuneToleranceCents
      ? PitchDirection.inTune
      : cents > 0
      ? PitchDirection.sharp
      : PitchDirection.flat;
}
