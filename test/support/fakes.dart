import 'dart:async';

import 'package:tuner/features/tuner/domain/pitch_estimate.dart';
import 'package:tuner/features/tuner/domain/pitch_source.dart';
import 'package:tuner/features/tuner/domain/reference_repository.dart';

class FakePitchSource implements PitchSource {
  final events = StreamController<PitchEstimate?>.broadcast(sync: true);
  int startCount = 0;
  int stopCount = 0;
  Exception? startError;
  Completer<void>? startGate;
  bool disposed = false;
  @override
  Stream<PitchEstimate?> get estimates => events.stream;
  @override
  Future<void> start() async {
    startCount++;
    if (startError != null) throw startError!;
    await startGate?.future;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await events.close();
  }

  void emit(double hz) =>
      events.add(PitchEstimate(frequencyHz: hz, confidence: 0.99, rms: 0.1));
}

class MemoryReferenceRepository implements ReferenceRepository {
  MemoryReferenceRepository([this.value = 440]);
  double value;
  final savedValues = <double>[];
  Completer<double>? loadGate;
  bool failSave = false;
  @override
  Future<double> load() async =>
      loadGate == null ? value : await loadGate!.future;
  @override
  Future<void> save(double referenceHz) async {
    if (failSave) throw Exception('Storage unavailable');
    savedValues.add(referenceHz);
    value = referenceHz;
  }
}
