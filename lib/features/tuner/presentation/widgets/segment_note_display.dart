import 'package:flutter/material.dart';

import '../../../../app/tuner_theme.dart';
import '../../domain/tuning_reading.dart';

class SegmentNoteDisplay extends StatelessWidget {
  const SegmentNoteDisplay({required this.reading, super.key});
  final TuningReading? reading;
  @override
  Widget build(BuildContext context) {
    final note = reading?.noteName;
    return Semantics(
      label: reading == null ? '감지된 음 없음' : '${note!}, 옥타브 ${reading!.octave}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 172,
          height: 126,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 45,
                top: 2,
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(82, 116),
                    painter: _SegmentPainter(note == null ? '-' : note[0]),
                  ),
                ),
              ),
              if (note != null && note.contains('#'))
                const Positioned(
                  left: 132,
                  top: 4,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 28,
                      color: TunerColors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              if (reading != null)
                Positioned(
                  left: 136,
                  bottom: 5,
                  child: CustomPaint(
                    size: const Size(23, 36),
                    painter: _SegmentPainter('${reading!.octave}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  const _SegmentPainter(this.character);
  final String character;
  static const _segments = {
    '-': 'g',
    'A': 'abcefg',
    'C': 'adef',
    'E': 'adefg',
    'F': 'aefg',
    '0': 'abcdef',
    '1': 'bc',
    '2': 'abdeg',
    '3': 'abcdg',
    '4': 'bcfg',
    '5': 'acdfg',
    '6': 'acdefg',
    '7': 'abc',
    '8': 'abcdefg',
    '9': 'abcdfg',
  };
  Path _polygon(List<Offset> points) => Path()..addPolygon(points, true);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 82, size.height / 116);
    final paths = <Path>[];
    // Angular bowls preserve uppercase B/D instead of a flat-looking lowercase b.
    if (character == 'B' || character == 'D') {
      final path = Path()..fillType = PathFillType.evenOdd;
      if (character == 'B') {
        path
          ..moveTo(5, 2)
          ..lineTo(58, 2)
          ..lineTo(76, 17)
          ..lineTo(76, 43)
          ..lineTo(65, 56)
          ..lineTo(78, 69)
          ..lineTo(78, 98)
          ..lineTo(59, 114)
          ..lineTo(5, 114)
          ..close()
          ..addRect(const Rect.fromLTRB(17, 14, 57, 49))
          ..addRect(const Rect.fromLTRB(17, 64, 59, 102));
      } else {
        path
          ..moveTo(5, 2)
          ..lineTo(56, 2)
          ..lineTo(78, 23)
          ..lineTo(78, 93)
          ..lineTo(56, 114)
          ..lineTo(5, 114)
          ..close()
          ..moveTo(17, 14)
          ..lineTo(51, 14)
          ..lineTo(66, 29)
          ..lineTo(66, 87)
          ..lineTo(51, 102)
          ..lineTo(17, 102)
          ..close();
      }
      paths.add(path);
    } else {
      final segments = character == 'G' ? 'adefc' : _segments[character] ?? 'g';
      for (final segment in segments.split('')) {
        paths.add(switch (segment) {
          'a' => _polygon(const [
            Offset(14, 2),
            Offset(68, 2),
            Offset(76, 9),
            Offset(68, 15),
            Offset(14, 15),
            Offset(6, 9),
          ]),
          'g' => _polygon(const [
            Offset(15, 51),
            Offset(67, 51),
            Offset(75, 58),
            Offset(67, 64),
            Offset(15, 64),
            Offset(7, 58),
          ]),
          'd' => _polygon(const [
            Offset(14, 101),
            Offset(68, 101),
            Offset(76, 108),
            Offset(68, 114),
            Offset(14, 114),
            Offset(6, 108),
          ]),
          'f' => _polygon(const [
            Offset(3, 14),
            Offset(14, 22),
            Offset(14, 46),
            Offset(5, 54),
            Offset(2, 49),
          ]),
          'b' => _polygon(const [
            Offset(79, 14),
            Offset(80, 49),
            Offset(77, 54),
            Offset(68, 46),
            Offset(68, 22),
          ]),
          'e' => _polygon(const [
            Offset(5, 62),
            Offset(14, 69),
            Offset(14, 94),
            Offset(3, 103),
            Offset(2, 67),
          ]),
          _ => _polygon(const [
            Offset(77, 62),
            Offset(80, 67),
            Offset(79, 103),
            Offset(68, 94),
            Offset(68, 69),
          ]),
        });
      }
      if (character == 'G') {
        paths.add(
          _polygon(const [
            Offset(43, 51),
            Offset(68, 51),
            Offset(76, 58),
            Offset(68, 64),
            Offset(43, 64),
          ]),
        );
      }
    }
    for (final path in paths) {
      canvas.drawPath(
        path,
        Paint()
          ..color = TunerColors.white.withValues(alpha: 0.24)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(path, Paint()..color = TunerColors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SegmentPainter oldDelegate) =>
      oldDelegate.character != character;
}
