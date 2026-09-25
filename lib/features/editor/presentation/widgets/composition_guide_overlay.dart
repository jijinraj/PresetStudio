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
  goldenSpiral,
  goldenTriangle,
}

enum CompositionGuideColor { white, yellow, cyan, red, green, magenta }

extension CompositionGuideColorPresentation on CompositionGuideColor {
  String get id => name;

  String get label {
    return switch (this) {
      CompositionGuideColor.white => 'White',
      CompositionGuideColor.yellow => 'Yellow',
      CompositionGuideColor.cyan => 'Cyan',
      CompositionGuideColor.red => 'Red',
      CompositionGuideColor.green => 'Green',
      CompositionGuideColor.magenta => 'Magenta',
    };
  }

  Color get color {
    return switch (this) {
      CompositionGuideColor.white => const Color(0xFFFFFFFF),
      CompositionGuideColor.yellow => const Color(0xFFFFD54F),
      CompositionGuideColor.cyan => const Color(0xFF4DD0E1),
      CompositionGuideColor.red => const Color(0xFFFF5252),
      CompositionGuideColor.green => const Color(0xFF69F0AE),
      CompositionGuideColor.magenta => const Color(0xFFFF4081),
    };
  }
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
      CompositionGuideType.goldenSpiral => 'golden-spiral',
      CompositionGuideType.goldenTriangle => 'golden-triangle',
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
      CompositionGuideType.goldenSpiral => 'Golden Spiral',
      CompositionGuideType.goldenTriangle => 'Golden Triangle',
    };
  }

  bool get supportsOrientation {
    return switch (this) {
      CompositionGuideType.goldenSpiral ||
      CompositionGuideType.goldenTriangle => true,
      _ => false,
    };
  }
}

@immutable
class CompositionGuideOrientation {
  const CompositionGuideOrientation({
    this.quarterTurns = 0,
    this.mirrored = false,
  });

  final int quarterTurns;
  final bool mirrored;

  int get normalizedQuarterTurns => ((quarterTurns % 4) + 4) % 4;

  CompositionGuideOrientation rotateClockwise() {
    return CompositionGuideOrientation(
      quarterTurns: normalizedQuarterTurns + 1,
      mirrored: mirrored,
    );
  }

  CompositionGuideOrientation flipHorizontal() {
    return CompositionGuideOrientation(
      quarterTurns: -normalizedQuarterTurns,
      mirrored: !mirrored,
    );
  }

  CompositionGuideOrientation flipVertical() {
    return CompositionGuideOrientation(
      quarterTurns: 2 - normalizedQuarterTurns,
      mirrored: !mirrored,
    );
  }

  Offset transformNormalized(Offset point) {
    var x = point.dx;
    var y = point.dy;

    if (mirrored) {
      x = 1 - x;
    }

    return switch (normalizedQuarterTurns) {
      0 => Offset(x, y),
      1 => Offset(1 - y, x),
      2 => Offset(1 - x, 1 - y),
      3 => Offset(y, 1 - x),
      _ => throw StateError('Unexpected normalized quarter turn'),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is CompositionGuideOrientation &&
        normalizedQuarterTurns == other.normalizedQuarterTurns &&
        mirrored == other.mirrored;
  }

  @override
  int get hashCode => Object.hash(normalizedQuarterTurns, mirrored);
}

class CompositionGuideOverlay extends StatelessWidget {
  const CompositionGuideOverlay({
    required this.guide,
    required this.emphasize,
    this.orientation = const CompositionGuideOrientation(),
    this.color = CompositionGuideColor.white,
    this.opacity = 1.0,
    super.key,
  });

  final CompositionGuideType guide;
  final bool emphasize;
  final CompositionGuideOrientation orientation;
  final CompositionGuideColor color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey('composition-guide-${guide.id}-overlay');

    if (guide == CompositionGuideType.none) {
      return SizedBox.shrink(key: key);
    }

    final overlay = switch (guide) {
      CompositionGuideType.none => const SizedBox.shrink(),
      CompositionGuideType.ruleOfThirds => CustomPaint(
        painter: _RuleOfThirdsGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.centerSymmetry => CustomPaint(
        painter: _CenterSymmetryGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.squareGrid => CustomPaint(
        painter: _SquareGridGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.fineGrid => CustomPaint(
        painter: _FineGridGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.phiGrid => CustomPaint(
        painter: _PhiGridGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.diagonalMethod => CustomPaint(
        painter: _DiagonalMethodGuidePainter(emphasize: emphasize),
      ),
      CompositionGuideType.goldenSpiral => CustomPaint(
        painter: _GoldenSpiralGuidePainter(
          emphasize: emphasize,
          orientation: orientation,
        ),
      ),
      CompositionGuideType.goldenTriangle => CustomPaint(
        painter: _GoldenTriangleGuidePainter(
          emphasize: emphasize,
          orientation: orientation,
        ),
      ),
    };

    return Opacity(
      key: key,
      opacity: opacity.clamp(0.0, 1.0).toDouble(),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(color.color, BlendMode.srcIn),
        child: overlay,
      ),
    );
  }
}

Paint _guidePaint(bool emphasize) {
  return Paint()
    ..color = emphasize ? const Color(0xFFFFFFFF) : const Color(0xC0FFFFFF)
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

class _GoldenSpiralGuidePainter extends CustomPainter {
  const _GoldenSpiralGuidePainter({
    required this.emphasize,
    required this.orientation,
  });

  final bool emphasize;
  final CompositionGuideOrientation orientation;

  static const double _phi = 1.618033988749895;
  static const int _samples = 220;
  static const double _sweepRadians = math.pi * 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final rawPoints = <Offset>[];
    final growth = math.log(_phi) / (math.pi / 2);

    for (var index = 0; index < _samples; index += 1) {
      final theta = _sweepRadians * index / (_samples - 1);
      final radius = math.exp(-growth * theta);

      rawPoints.add(Offset(radius * math.cos(theta), radius * math.sin(theta)));
    }

    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;

    for (final point in rawPoints) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    final spanX = maxX - minX;
    final spanY = maxY - minY;

    if (spanX <= 0 || spanY <= 0) {
      return;
    }

    final path = Path();

    for (var index = 0; index < rawPoints.length; index += 1) {
      final raw = rawPoints[index];
      final normalized = Offset(
        (raw.dx - minX) / spanX,
        (raw.dy - minY) / spanY,
      );
      final point = _mapNormalizedPoint(normalized, size, orientation);

      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, _guidePaint(emphasize));
  }

  @override
  bool shouldRepaint(covariant _GoldenSpiralGuidePainter oldDelegate) {
    return oldDelegate.emphasize != emphasize ||
        oldDelegate.orientation != orientation;
  }
}

class _GoldenTriangleGuidePainter extends CustomPainter {
  const _GoldenTriangleGuidePainter({
    required this.emphasize,
    required this.orientation,
  });

  final bool emphasize;
  final CompositionGuideOrientation orientation;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final paint = _guidePaint(emphasize);
    final denominator = (size.width * size.width) + (size.height * size.height);
    final topProjection = size.width * size.width / denominator;
    final bottomProjection = size.height * size.height / denominator;

    final lines = <_NormalizedGuideLine>[
      (start: Offset.zero, end: const Offset(1, 1)),
      (start: const Offset(1, 0), end: Offset(topProjection, topProjection)),
      (
        start: const Offset(0, 1),
        end: Offset(bottomProjection, bottomProjection),
      ),
    ];

    for (final line in lines) {
      canvas.drawLine(
        _mapNormalizedPoint(line.start, size, orientation),
        _mapNormalizedPoint(line.end, size, orientation),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenTriangleGuidePainter oldDelegate) {
    return oldDelegate.emphasize != emphasize ||
        oldDelegate.orientation != orientation;
  }
}

Offset _mapNormalizedPoint(
  Offset point,
  Size size,
  CompositionGuideOrientation orientation,
) {
  final transformed = orientation.transformNormalized(point);
  return Offset(transformed.dx * size.width, transformed.dy * size.height);
}

typedef _NormalizedGuideLine = ({Offset start, Offset end});
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
