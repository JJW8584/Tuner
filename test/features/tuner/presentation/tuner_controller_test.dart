import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuner/features/tuner/domain/pitch_source.dart';
import 'package:tuner/features/tuner/domain/pitch_estimate.dart';
import 'package:tuner/features/tuner/presentation/tuner_controller.dart';

import '../../../support/fakes.dart';

void main() {
  late FakePitchSource source;
  late MemoryReferenceRepository repository;
  late TunerController controller;
  setUp(() {
    source = FakePitchSource();
    repository = MemoryReferenceRepository();
    controller = TunerController(
      pitchSource: source,
      referenceRepository: repository,
    );
  });
  tearDown(() async {
    await controller.stop();
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'loads reference, follows live pitch and recalibrates immediately',
    () async {
      repository.value = 442;
      await controller.initialize();
      await controller.start();
      source.emit(442);
      expect(controller.reading!.noteName, 'A');
      expect(controller.reading!.octave, 4);
      expect(controller.reading!.cents, closeTo(0, 1e-6));
      controller.setReferenceHz(440);
      expect(controller.reading!.cents, greaterThan(0));
      await controller.flushReference();
      expect(repository.value, 440);
      await controller.stop();
      expect(controller.reading, isNull);
    },
  );
  test('permission denial releases resources and allows retry', () async {
    source.startError = const AudioInputException(
      AudioInputFailure.permissionDenied,
    );
    await controller.start();
    expect(controller.status, TunerStatus.failed);
    expect(controller.message, contains('권한'));
    source.startError = null;
    await controller.start();
    expect(controller.isListening, isTrue);
  });
  test(
    'stopping during permission/startup does not leave microphone active',
    () async {
      source.startGate = Completer<void>();
      final starting = controller.start();
      await Future<void>.delayed(Duration.zero);
      final stopping = controller.stop();
      source.startGate!.complete();
      await starting;
      await stopping;
      expect(controller.status, TunerStatus.idle);
      expect(source.stopCount, greaterThan(0));
    },
  );
  test('repeated start calls open exactly one audio session', () async {
    await Future.wait([controller.start(), controller.start()]);
    expect(source.startCount, 1);
  });
  test('late settings load cannot overwrite a user edit', () async {
    repository.loadGate = Completer<double>();
    final loading = controller.initialize();
    controller.setReferenceHz(445);
    repository.loadGate!.complete(432);
    await loading;
    expect(controller.referenceHz, 445);
    controller.setReferenceHz(999);
    expect(controller.referenceHz, 450);
    await controller.flushReference();
    expect(repository.savedValues, [450]);
  });
  test(
    'stream interruptions clear the note and permit a new session',
    () async {
      await controller.start();
      source.emit(440);
      source.events.addError(
        const AudioInputException(AudioInputFailure.interrupted),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.status, TunerStatus.failed);
      expect(controller.reading, isNull);
      await controller.start();
      expect(controller.isListening, isTrue);
    },
  );
  test('silence clears the last note after the hold interval', () async {
    await controller.start();
    source.emit(440);
    expect(controller.reading, isNotNull);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(controller.reading, isNotNull);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(controller.reading, isNull);
  });

  test(
    'presentation accepts quiet sustain admitted by the detector gate',
    () async {
      await controller.start();
      source.events.add(
        const PitchEstimate(frequencyHz: 440, confidence: 0.82, rms: 0.0005),
      );
      expect(controller.reading!.noteName, 'A');
      expect(controller.reading!.octave, 4);
      source.events.add(
        const PitchEstimate(frequencyHz: 220, confidence: 0.70, rms: 0.0005),
      );
      expect(controller.reading!.octave, 4);
    },
  );
}
