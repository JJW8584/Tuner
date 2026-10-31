import 'package:flutter/material.dart';

/// Uses only the system-safe viewport supplied by the screen's SafeArea.
class TunerLayout extends StatelessWidget {
  const TunerLayout({
    required this.header,
    required this.display,
    required this.controls,
    super.key,
  });

  final Widget header;
  final Widget display;
  final Widget controls;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          constraints.maxWidth >= 560 &&
          constraints.maxWidth > constraints.maxHeight;
      final minimumHeight =
          300 + MediaQuery.textScalerOf(context).scale(12) * 4;
      final needsScroll = !wide && constraints.maxHeight < minimumHeight;
      final availableHeight = needsScroll
          ? minimumHeight
          : constraints.maxHeight;
      final body = wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: display),
                const SizedBox(width: 24),
                SizedBox(
                  width: (constraints.maxWidth * 0.38).clamp(220.0, 320.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(child: controls),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(child: display),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: (availableHeight - 48) * 0.6,
                  ),
                  child: SingleChildScrollView(child: controls),
                ),
              ],
            );
      final content = Column(
        children: [
          SizedBox(
            height: 40,
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: header),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: body),
        ],
      );
      // Retain usable touch targets in exceptionally short split-screen views.
      // Scrolling is clipped inside SafeArea, never under a camera or nav bar.
      if (needsScroll) {
        return SingleChildScrollView(
          child: SizedBox(height: minimumHeight, child: content),
        );
      }
      return content;
    },
  );
}
