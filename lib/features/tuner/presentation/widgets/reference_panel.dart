import 'package:flutter/material.dart';

import '../../../../app/tuner_theme.dart';
import '../../domain/tuning_reference.dart';

class ReferencePanel extends StatelessWidget {
  const ReferencePanel({
    required this.referenceHz,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
  });
  final double referenceHz;
  final ValueChanged<double> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFF202426)),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0C0E0F), Color(0xFF070909)],
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ReferenceButton(
              icon: Icons.remove,
              label: '기준 주파수 1 Hz 낮추기',
              onPressed: referenceHz > TuningReference.minimumHz
                  ? onDecrement
                  : null,
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Semantics(
                  label: 'A4 기준 주파수 ${referenceHz.round()} 헤르츠',
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${referenceHz.round()}',
                          style: const TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -1,
                          ),
                        ),
                        const TextSpan(
                          text: ' Hz',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(color: TunerColors.white),
                  ),
                ),
              ),
            ),
            _ReferenceButton(
              icon: Icons.add,
              label: '기준 주파수 1 Hz 높이기',
              onPressed: referenceHz < TuningReference.maximumHz
                  ? onIncrement
                  : null,
            ),
          ],
        ),
        SizedBox(
          height: 32,
          child: Slider(
            key: const ValueKey('reference-slider'),
            value: referenceHz,
            min: TuningReference.minimumHz,
            max: TuningReference.maximumHz,
            divisions: 20,
            onChanged: onChanged,
            semanticFormatterCallback: (value) => 'A4 기준 ${value.round()} 헤르츠',
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '430',
                style: TextStyle(fontSize: 11, color: TunerColors.muted),
              ),
              Text(
                '450',
                style: TextStyle(fontSize: 11, color: TunerColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReferenceButton extends StatelessWidget {
  const _ReferenceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: label,
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    padding: const EdgeInsets.all(6),
    icon: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF181C1E),
        border: Border.all(color: const Color(0xFF2A3033)),
      ),
      child: Icon(
        icon,
        size: 23,
        color: onPressed == null ? const Color(0xFF4A5053) : TunerColors.white,
      ),
    ),
  );
}
