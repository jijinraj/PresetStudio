import 'package:flutter/material.dart';

enum CompositionGuideType { none, ruleOfThirds, centerSymmetry }

extension CompositionGuideTypeLabel on CompositionGuideType {
  String get label {
    return switch (this) {
      CompositionGuideType.none => 'None',
      CompositionGuideType.ruleOfThirds => 'Rule of Thirds',
      CompositionGuideType.centerSymmetry => 'Center / Symmetry',
    };
  }
}

class CompositionGuideOverlay extends StatelessWidget {
  const CompositionGuideOverlay({
    required this.guide,
    required this.emphasize,
    super.key,
  });

  final CompositionGuideType guide;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return switch (guide) {
      CompositionGuideType.none => const SizedBox.shrink(
        key: ValueKey('composition-guide-none-overlay'),
      ),
      CompositionGuideType.ruleOfThirds => CustomPaint(
        key: const ValueKey('composition-guide-rule-of-thirds-overlay'),
        painter: _RuleOfThirdsGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.centerSymmetry => CustomPaint(
        key: const ValueKey('composition-guide-center-symmetry-overlay'),
        painter: _CenterSymmetryGuidePainter(emphasize: emphasize),
      ),
    };
  }
}

class _RuleOfThirdsGuidePainter extends CustomPainter {
  const _RuleOfThirdsGuidePainter({required this.emphasize});

  final bool emphasize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = emphasize ? const Color(0x70FFFFFF) : const Color(0x2AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final thirdWidth = size.width / 3;
    final thirdHeight = size.height / 3;

    for (var index = 1; index <= 2; index += 1) {
      canvas.drawLine(
        Offset(thirdWidth * index, 0),
        Offset(thirdWidth * index, size.height),
        paint,
      );

      canvas.drawLine(
        Offset(0, thirdHeight * index),
        Offset(size.width, thirdHeight * index),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RuleOfThirdsGuidePainter oldDelegate) {
    return oldDelegate.emphasize != emphasize;
  }
}

class _CenterSymmetryGuidePainter extends CustomPainter {
  const _CenterSymmetryGuidePainter({required this.emphasize});

  final bool emphasize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = emphasize ? const Color(0x70FFFFFF) : const Color(0x2AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);
  }

  @override
  bool shouldRepaint(covariant _CenterSymmetryGuidePainter oldDelegate) {
    return oldDelegate.emphasize != emphasize;
  }
}
