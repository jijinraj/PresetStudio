import 'package:flutter/material.dart';

import '../../rendering/image_histogram.dart';
import 'tone_curve_editor.dart';

class ToneCurveHistogram extends StatelessWidget {
  const ToneCurveHistogram({
    required this.histogram,
    required this.channel,
    super.key,
  });

  final ImageHistogram histogram;
  final ToneCurveChannel channel;

  @override
  Widget build(BuildContext context) {
    final values = switch (channel) {
      ToneCurveChannel.master => histogram.luminance,
      ToneCurveChannel.red => histogram.red,
      ToneCurveChannel.green => histogram.green,
      ToneCurveChannel.blue => histogram.blue,
    };

    final color = switch (channel) {
      ToneCurveChannel.master => Colors.white,
      ToneCurveChannel.red => const Color(0xFFE56A72),
      ToneCurveChannel.green => const Color(0xFF63C58B),
      ToneCurveChannel.blue => const Color(0xFF6D8DFF),
    };

    return IgnorePointer(
      child: CustomPaint(
        painter: _HistogramPainter(values: values, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  const _HistogramPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final path = Path()..moveTo(0, size.height);
    for (var index = 0; index < values.length; index += 1) {
      final x = index / (values.length - 1) * size.width;
      final y = size.height - values[index] * size.height * 0.72;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) =>
      values != oldDelegate.values || color != oldDelegate.color;
}
