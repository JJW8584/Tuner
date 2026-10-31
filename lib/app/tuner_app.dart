import 'dart:async';

import 'package:flutter/material.dart';

import '../features/tuner/presentation/tuner_controller.dart';
import '../features/tuner/presentation/tuner_screen.dart';
import 'tuner_theme.dart';

class TunerApp extends StatefulWidget {
  const TunerApp({required this.controller, super.key});
  final TunerController controller;
  @override
  State<TunerApp> createState() => _TunerAppState();
}

class _TunerAppState extends State<TunerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialize());
    });
  }

  Future<void> _initialize() async {
    // Neither local preferences nor microphone setup blocks the first frame,
    // and a slow settings read must not delay microphone permission/setup.
    await Future.wait([
      widget.controller.initialize(),
      widget.controller.start(),
    ]);
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Tuner',
    debugShowCheckedModeBanner: false,
    theme: buildTunerTheme(),
    home: TunerScreen(controller: widget.controller),
  );
}
