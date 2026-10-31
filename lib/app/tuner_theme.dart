import 'package:flutter/material.dart';

abstract final class TunerColors {
  static const background = Color(0xFF030404);
  static const white = Color(0xFFF3F5F5);
  static const muted = Color(0xFF777F85);
  static const green = Color(0xFF00EE45);
  static const leds = [
    green,
    Color(0xFFE7F500),
    Color(0xFFFFAF00),
    Color(0xFFFF5A00),
    Color(0xFFFF0929),
  ];
}

ThemeData buildTunerTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: TunerColors.background,
  colorScheme: const ColorScheme.dark(
    primary: TunerColors.green,
    surface: Color(0xFF111416),
  ),
  fontFamily: 'sans-serif',
  useMaterial3: true,
  sliderTheme: const SliderThemeData(
    trackHeight: 3,
    activeTrackColor: TunerColors.green,
    inactiveTrackColor: Color(0xFF293034),
    activeTickMarkColor: Colors.transparent,
    inactiveTickMarkColor: Colors.transparent,
    thumbColor: TunerColors.white,
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
    overlayShape: RoundSliderOverlayShape(overlayRadius: 17),
    showValueIndicator: ShowValueIndicator.never,
  ),
);
