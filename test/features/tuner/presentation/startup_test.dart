import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuner/app/tuner_app.dart';
import 'package:tuner/features/tuner/presentation/tuner_controller.dart';

import '../../../support/fakes.dart';

void main() {
  testWidgets('first frame and microphone do not wait for preference storage', (
    tester,
  ) async {
    final source = FakePitchSource();
    final repository = MemoryReferenceRepository()
      ..loadGate = Completer<double>();
    final controller = TunerController(
      pitchSource: source,
      referenceRepository: repository,
    );
    await tester.pumpWidget(TunerApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('TUNER'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(source.startCount, 1);
    expect(controller.isListening, isTrue);
    source.emit(442);
    expect(controller.reading!.cents, greaterThan(0));
    repository.loadGate!.complete(442);
    await tester.pump();
    expect(controller.referenceHz, 442);
    expect(controller.reading!.cents, closeTo(0, 1e-6));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
