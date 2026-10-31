import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/tuner_theme.dart';
import 'tuner_controller.dart';
import 'widgets/pitch_display.dart';
import 'widgets/reference_panel.dart';
import 'widgets/tuner_layout.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({required this.controller, super.key});
  final TunerController controller;
  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> with WidgetsBindingObserver {
  bool _wasBackgrounded = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permission dialogs only cause inactive/resumed; they must not retrigger
    // startup. Restart automatically only after an actual background transition.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      unawaited(widget.controller.stop());
      unawaited(widget.controller.flushReference());
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      unawaited(widget.controller.start());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      minimum: const EdgeInsets.all(12),
      maintainBottomViewPadding: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final controller = widget.controller;
                return TunerLayout(
                  key: const ValueKey('tuner-safe-content'),
                  header: const Text(
                    'TUNER',
                    style: TextStyle(
                      color: TunerColors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.3,
                    ),
                  ),
                  display: PitchDisplay(
                    reading: controller.reading,
                    meter: controller.meter,
                  ),
                  controls: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PitchStatus(controller: controller),
                          const SizedBox(height: 8),
                          ReferencePanel(
                            referenceHz: controller.referenceHz,
                            onChanged: controller.setReferenceHz,
                            onIncrement: () => controller.setReferenceHz(
                              controller.referenceHz + 1,
                            ),
                            onDecrement: () => controller.setReferenceHz(
                              controller.referenceHz - 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _PitchStatus extends StatelessWidget {
  const _PitchStatus({required this.controller});
  final TunerController controller;

  @override
  Widget build(BuildContext context) {
    final message = controller.message;
    final reading = controller.reading;
    if (message != null) {
      return Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFFB65B),
          fontSize: 12,
          height: 1.4,
        ),
      );
    }
    if (reading == null) return const SizedBox.shrink();
    return Text(
      '${reading.frequencyHz.toStringAsFixed(1)} Hz  ·  ${reading.cents >= 0 ? '+' : ''}${reading.cents.toStringAsFixed(1)} cents',
      textAlign: TextAlign.center,
      style: const TextStyle(color: TunerColors.muted, fontSize: 11),
    );
  }
}
