import 'package:flutter/material.dart';

import '../../../../app/tuner_theme.dart';
import '../../domain/led_meter.dart';
import '../../domain/tuning_reading.dart';
import 'led_bank.dart';
import 'segment_note_display.dart';

/// Scales the meter as one unit so LED circles and note proportions stay intact.
class PitchDisplay extends StatelessWidget {
  const PitchDisplay({required this.reading, required this.meter, super.key});

  final TuningReading? reading;
  final LedMeter meter;

  @override
  Widget build(BuildContext context) => Center(
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 300,
        height: 518,
        child: Column(
          children: [
            LedBank(
              isUpper: true,
              activeRows: meter.direction == PitchDirection.sharp
                  ? meter.activeRows
                  : 0,
            ),
            SizedBox(
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SegmentNoteDisplay(reading: reading),
                  if (reading != null &&
                      meter.direction == PitchDirection.inTune) ...[
                    const Positioned(
                      left: 29,
                      top: 57,
                      child: Icon(
                        Icons.arrow_right,
                        color: TunerColors.green,
                        size: 27,
                      ),
                    ),
                    const Positioned(
                      right: 29,
                      top: 57,
                      child: Icon(
                        Icons.arrow_left,
                        color: TunerColors.green,
                        size: 27,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            LedBank(
              isUpper: false,
              activeRows: meter.direction == PitchDirection.flat
                  ? meter.activeRows
                  : 0,
            ),
          ],
        ),
      ),
    ),
  );
}
