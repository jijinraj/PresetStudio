import 'dart:math' as math;

import 'package:flutter/material.dart';

enum CompositionGuideType {
  none,
  ruleOfThirds,
  centerSymmetry,
  squareGrid,
  fineGrid,
  phiGrid,
  diagonalMethod,
}

extension CompositionGuideTypeLabel on CompositionGuideType {
  String get id {
    return switch (this) {
      CompositionGuideType.none => 'none',
      CompositionGuideType.ruleOfThirds => 'rule-of-thirds',
      CompositionGuideType.centerSymmetry => 'center-symmetry',
      CompositionGuideType.squareGrid => 'square-grid',
      CompositionGuideType.fineGrid => 'fine-grid',
      CompositionGuideType.phiGrid => 'phi-grid',
      CompositionGuideType.diagonalMethod => 'diagonal-method',
    };
  }

  String get label {
    return switch (this) {
      CompositionGuideType.none => 'None',
      CompositionGuideType.ruleOfThirds => 'Rule of Thirds',
      CompositionGuideType.centerSymmetry => 'Center / Symmetry',
      CompositionGuideType.squareGrid => 'Square Grid',
      CompositionGuideType.fineGrid => 'Fine Grid',
      CompositionGuideType.phiGrid => 'Phi Grid / Golden Ratio',
      CompositionGuideType.diagonalMethod => 'Diagonal Method',
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
    final key = ValueKey('composition-guide-${guide.id}-overlay');

    return switch (guide) {
      CompositionGuideType.none => SizedBox.shrink(key: key),
      CompositionGuideType.ruleOfThirds => CustomPaint(
        key: key,
        painter: _RuleOfThirdsGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.centerSymmetry => CustomPaint(
        key: key,
        painter: _CenterSymmetryGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.squareGrid => CustomPaint(
        key: key,
        painter: _SquareGridGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.fineGrid => CustomPaint(
        key: key,
        painter: _FineGridGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.phiGrid => CustomPaint(
        key: key,
        painter: _PhiGridGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.diagonalMethod => CustomPaint(
        key: key,
        painter: _DiagonalMethodGuidePainter(emphasize: emphasize),
      ),
    };
  }
}

Paint _guidePaint(bool emphasize) {
  return Paint()
    ..color = emphasize ? const Color(0x70FFFFFF) : const Color(0x2AFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
}

class _RuleOfThirdsGuidePainter extends CustomPainter {
  const _RuleOfThirdsGuidePainter({required this.emphasize});

  final bool emphasize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _guidePaint(emphasize);
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
    final paint = _guidePaint(emphasize);
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

class _SquareGridGuidePainter extends CustomPainter {
  const _SquareGridGuidePainter({required this.emphasize});

  final bool emphasize;

  static const int _shortAxisDivisions = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);

    if (shortestSide <= 0) {
      return;
    }

    final paint = _guidePaint(emphasize);
    final spacing = shortestSide / _shortAxisDivisions;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    _drawCenteredGridLines(
      canvas: canvas,
      paint: paint,
      extent: size.width,
      center: centerX,
      spacing: spacing,
      lineBuilder: (position) =>
          (Offset(position, 0), Offset(position, size.height)),
    );

    _drawCenteredGridLines(
      canvas: canvas,
      paint: paint,
      extent: size.height,
      center: centerY,
      spacing: spacing,
      lineBuilder: (position) =>
          (Offset(0, position), Offset(size.width, position)),
    );
  }

  @override
  bool shouldRepaint(covariant _SquareGridGuidePainter oldDelegate) {
    return oldDelegate.emphasize != emphasize;
  }
}

class _FineGridGuidePainter extends CustomPainter {
  const _FineGridGuidePainter({required this.emphasize});

  final bool emphasize;

  static const int _divisions = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _guidePaint(emphasize);

    for (var index = 1; index < _divisions; index += 1) {
      final x = size.width * index / _divisions;
      final y = size.height * index / _divisions;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FineGridGuidePainter oldDelegate) {
    return oldDelegate.emphasize != emphasize;
  }
}

class _PhiGridGuidePainter extends CustomPainter {
  const _PhiGridGuidePainter({required this.emphasize});

  final bool emphasize;

  static const double _minorSection = 0.3819660112501051;
  static const double _majorSection = 1 - _minorSection;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _guidePaint(emphasize);

    for (final fraction in [_minorSection, _majorSection]) {
      final x = size.width * fraction;
      final y = size.height * fraction;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PhiGridGuidePainter oldDelegate) {
    return oldDelegate.emphasize != emphasize;
  }
}

class _DiagonalMethodGuidePainter extends CustomPainter {
  const _DiagonalMethodGuidePainter({required this.emphasize});

  final bool emphasize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _guidePaint(emphasize);
    final diagonalLength = math.min(size.width, size.height);

    canvas.drawLine(Offset.zero, Offset(diagonalLength, diagonalLength), paint);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - diagonalLength, diagonalLength),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(diagonalLength, size.height - diagonalLength),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - diagonalLength, size.height - diagonalLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DiagonalMethodGuidePainter oldDelegate) {
    return oldDelegate.emphasize != emphasize;
  }
}

typedef _GridLine = (Offset start, Offset end);

void _drawCenteredGridLines({
  required Canvas canvas,
  required Paint paint,
  required double extent,
  required double center,
  required double spacing,
  required _GridLine Function(double position) lineBuilder,
}) {
  if (spacing <= 0 || extent <= 0) {
    return;
  }

  for (
    var position = center;
    position > 0 && position < extent;
    position -= spacing
  ) {
    final line = lineBuilder(position);
    canvas.drawLine(line.$1, line.$2, paint);
  }

  for (
    var position = center + spacing;
    position > 0 && position < extent;
    position += spacing
  ) {
    final line = lineBuilder(position);
    canvas.drawLine(line.$1, line.$2, paint);
  }
}
