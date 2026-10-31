import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuner/app/tuner_app.dart';
import 'package:tuner/app/tuner_theme.dart';
import 'package:tuner/features/tuner/presentation/tuner_screen.dart';
import 'package:tuner/features/tuner/presentation/tuner_controller.dart';
import 'package:tuner/features/tuner/presentation/widgets/led_bank.dart';
import 'package:tuner/features/tuner/domain/pitch_source.dart';

import '../../../support/fakes.dart';

void main() {
  testWidgets('reference controls and microphone update the real screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = FakePitchSource();
    final repository = MemoryReferenceRepository(442);
    final controller = TunerController(
      pitchSource: source,
      referenceRepository: repository,
    );
    await tester.pumpWidget(TunerApp(controller: controller));
    await tester.pumpAndSettle();
    expect(controller.referenceHz, 442);
    expect(controller.isListening, isTrue);
    expect(source.startCount, 1);
    expect(find.text('TUNER'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('마이크를 켜고 악기의 한 음을 연주하세요'), findsNothing);
    expect(find.text('마이크 시작'), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.text('A4 REFERENCE'), findsNothing);
    expect(find.byType(LedBank), findsNWidgets(2));
    await tester.tap(find.byTooltip('기준 주파수 1 Hz 높이기'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.referenceHz, 443);
    expect(repository.value, 443);
    // Both callbacks can run before a rebuild; each must use the latest state.
    await tester.tap(find.byTooltip('기준 주파수 1 Hz 높이기'));
    await tester.tap(find.byTooltip('기준 주파수 1 Hz 높이기'));
    expect(controller.referenceHz, 445);
    await tester.pump(const Duration(milliseconds: 300));
    source.emit(445);
    await tester.pump();
    expect(find.bySemanticsLabel('A, 옥타브 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(controller.isListening, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpUntil(tester, () => controller.isListening);
    expect(controller.isListening, isTrue);
    expect(source.startCount, 2);
    // A fast background/resume cycle must also queue a restart after stop.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpUntil(tester, () => controller.isListening);
    expect(controller.isListening, isTrue);
    expect(source.startCount, 3);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('permission denial shows an error without repeatedly prompting', (
    tester,
  ) async {
    final source = FakePitchSource()
      ..startError = const AudioInputException(
        AudioInputFailure.permissionDenied,
      );
    final controller = TunerController(
      pitchSource: source,
      referenceRepository: MemoryReferenceRepository(),
    );
    await tester.pumpWidget(TunerApp(controller: controller));
    await _pumpUntil(tester, () => controller.status == TunerStatus.failed);
    expect(controller.status, TunerStatus.failed);
    expect(find.textContaining('마이크 권한이 필요합니다'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(source.startCount, 1);
    source.startError = null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpUntil(tester, () => controller.isListening);
    expect(controller.isListening, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  for (final dimensions in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    testWidgets('fits $dimensions without overflow at large text scale', (
      tester,
    ) async {
      tester.view.physicalSize = dimensions;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TunerController(
        pitchSource: FakePitchSource(),
        referenceRepository: MemoryReferenceRepository(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTunerTheme(),
          home: MediaQuery(
            data: MediaQueryData(
              size: dimensions,
              textScaler: TextScaler.linear(2),
            ),
            child: TunerScreen(controller: controller),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await tester.pump();
    });
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 10));
    if (condition()) return;
  }
  expect(condition(), isTrue, reason: 'Audio session did not settle');
}
