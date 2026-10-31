import 'package:flutter/material.dart';

import '../../../../app/tuner_theme.dart';

class LedBank extends StatelessWidget {
  const LedBank({required this.activeRows, required this.isUpper, super.key});
  final int activeRows;
  final bool isUpper;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${isUpper ? '높은 음' : '낮은 음'} 표시: 5줄 중 $activeRows줄 점등',
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: const Size(300, 184),
          painter: _LedBankPainter(activeRows: activeRows, isUpper: isUpper),
        ),
      ),
    ),
  );
}

class _LedBankPainter extends CustomPainter {
  const _LedBankPainter({required this.activeRows, required this.isUpper});
  final int activeRows;
  final bool isUpper;
  @override
  void paint(Canvas canvas, Size size) {
    for (var row = 0; row < 5; row++) {
      final color = TunerColors.leds[row];
      final active = row < activeRows;
      final y = isUpper ? 166.0 - row * 37 : 18.0 + row * 37;
      final spacing = 32.0 + row * 5;
      for (var column = 0; column < 5; column++) {
        final position = Offset(size.width / 2 + (column - 2) * spacing, y);
        if (active) {
          canvas.drawCircle(
            position,
            13,
            Paint()
              ..color = color.withValues(alpha: 0.32)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          );
          canvas.drawCircle(
            position,
            10,
            Paint()
              ..color = color.withValues(alpha: 0.65)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
        canvas.drawCircle(
          position,
          8.8,
          Paint()..color = active ? color : color.withValues(alpha: 0.12),
        );
        if (active) {
          canvas.drawCircle(
            position.translate(-1.5, -1.5),
            4.5,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.12)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LedBankPainter oldDelegate) =>
      oldDelegate.activeRows != activeRows || oldDelegate.isUpper != isUpper;
}
