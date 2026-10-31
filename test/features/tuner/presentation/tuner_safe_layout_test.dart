import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuner/app/tuner_theme.dart';
import 'package:tuner/features/tuner/presentation/tuner_controller.dart';
import 'package:tuner/features/tuner/presentation/tuner_screen.dart';
import 'package:tuner/features/tuner/presentation/widgets/led_bank.dart';
import 'package:tuner/features/tuner/presentation/widgets/reference_panel.dart';

import '../../../support/fakes.dart';

void main() {
  final cases = [
    (
      name: 'small phone with navigation buttons',
      size: const Size(320, 568),
      insets: const EdgeInsets.only(top: 24, bottom: 48),
    ),
    (
      name: 'notch and home indicator',
      size: const Size(390, 844),
      insets: const EdgeInsets.only(top: 59, bottom: 34),
    ),
    (
      name: 'tall phone',
      size: const Size(412, 960),
      insets: const EdgeInsets.only(top: 48, bottom: 24),
    ),
    (
      name: 'landscape camera cutout',
      size: const Size(844, 390),
      insets: const EdgeInsets.fromLTRB(44, 0, 24, 24),
    ),
    (
      name: 'tablet',
      size: const Size(768, 1024),
      insets: const EdgeInsets.only(top: 24, bottom: 24),
    ),
  ];
  for (final scenario in cases) {
    testWidgets('${scenario.name}: content fits outside system areas', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.size;
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
              size: scenario.size,
              padding: scenario.insets,
              viewPadding: scenario.insets,
            ),
            child: TunerScreen(controller: controller),
          ),
        ),
      );
      await tester.pump();
      final safe = Rect.fromLTRB(
        scenario.insets.left,
        scenario.insets.top,
        scenario.size.width - scenario.insets.right,
        scenario.size.height - scenario.insets.bottom,
      );
      for (final finder in [
        find.byKey(const ValueKey('tuner-safe-content')),
        find.text('TUNER'),
        find.byType(ReferencePanel),
        ...find
            .byType(LedBank)
            .evaluate()
            .map((element) => find.byWidget(element.widget)),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(safe.left - 0.01));
        expect(rect.top, greaterThanOrEqualTo(safe.top - 0.01));
        expect(rect.right, lessThanOrEqualTo(safe.right + 0.01));
        expect(rect.bottom, lessThanOrEqualTo(safe.bottom + 0.01));
      }
      for (final scrollable in tester.widgetList<Scrollable>(
        find.byType(Scrollable),
      )) {
        expect(
          tester
              .state<ScrollableState>(find.byWidget(scrollable))
              .position
              .maxScrollExtent,
          0,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await tester.pump();
    });
  }

  testWidgets('rotation updates layout and retains tuning calibration', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TunerController(
      pitchSource: FakePitchSource(),
      referenceRepository: MemoryReferenceRepository(),
    )..setReferenceHz(442);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTunerTheme(),
        home: TunerScreen(controller: controller),
      ),
    );
    await tester.pump();
    final portraitPanel = tester.getRect(find.byType(ReferencePanel));
    expect(portraitPanel.center.dx, closeTo(195, 1));
    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    final landscapePanel = tester.getRect(find.byType(ReferencePanel));
    expect(landscapePanel.center.dx, greaterThan(422));
    expect(controller.referenceHz, 442);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.pump();
  });
}
