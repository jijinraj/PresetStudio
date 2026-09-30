import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../domain/curve_point.dart';
import '../../domain/tone_curves.dart';

enum ToneCurveChannel { master, red, green, blue }

class ToneCurveEditor extends StatefulWidget {
  const ToneCurveEditor({
    required this.toneCurves,
    required this.onChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.initialChannel = ToneCurveChannel.master,
    this.graphHeight = 220,
    super.key,
  });

  final ToneCurves toneCurves;
  final ValueChanged<ToneCurves> onChanged;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final ToneCurveChannel initialChannel;
  final double graphHeight;

  @override
  State<ToneCurveEditor> createState() => _ToneCurveEditorState();
}

class _ToneCurveEditorState extends State<ToneCurveEditor> {
  static const double _pointHitRadius = 24;
  static const double _minimumInputGap = 0.001;

  late ToneCurveChannel _channel;
  int? _selectedIndex;
  bool _dragActive = false;
  final GlobalKey _graphKey = GlobalKey();

  ToneCurve get _curve => _curveFor(widget.toneCurves, _channel);

  @override
  void initState() {
    super.initState();
    _channel = widget.initialChannel;
  }

  @override
  void didUpdateWidget(covariant ToneCurveEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selectedIndex;
    if (selected != null && selected >= _curve.points.length) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final curve = _curve;
    final selected = _selectedIndex;
    final selectedPoint = selected == null ? null : curve.points[selected];
    final canDelete =
        selected != null && selected > 0 && selected < curve.points.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          key: const ValueKey('tone-curve-channel-selector'),
          spacing: AppSpacing.xs,
          children: ToneCurveChannel.values
              .map((channel) {
                return ChoiceChip(
                  key: ValueKey('tone-curve-channel-${channel.name}'),
                  label: Text(_channelLabel(channel)),
                  selected: _channel == channel,
                  onSelected: (_) => _selectChannel(channel),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            right: AppSpacing.lg,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.graphHeight),
              child: GestureDetector(
                key: _graphKey,
                behavior: HitTestBehavior.opaque,
                onTapUp: _handleTap,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: (_) => _finishDrag(),
                onPanCancel: _finishDrag,
                child: CustomPaint(
                  key: const ValueKey('tone-curve-gesture-surface'),
                  painter: _ToneCurvePainter(
                    curve: curve,
                    channel: _channel,
                    selectedIndex: selected,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                selectedPoint == null
                    ? 'Tap the curve to add a point'
                    : 'Input ${_percent(selectedPoint.input)}  •  Output ${_percent(selectedPoint.output)}',
                key: const ValueKey('tone-curve-point-readout'),
                style: AppTypography.label,
              ),
            ),
            IconButton(
              key: const ValueKey('tone-curve-delete-point'),
              tooltip: 'Delete selected point',
              onPressed: canDelete ? _deleteSelectedPoint : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            TextButton(
              key: const ValueKey('tone-curve-reset-channel'),
              onPressed: curve.isIdentity ? null : _resetChannel,
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }

  void _selectChannel(ToneCurveChannel channel) {
    if (_channel == channel) return;
    setState(() {
      _channel = channel;
      _selectedIndex = null;
    });
  }

  void _handleTap(TapUpDetails details) {
    final box = _graphKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || box.size.isEmpty) return;

    final normalized = _normalizedPoint(details.localPosition, box.size);
    final hit = _nearestPointIndex(details.localPosition, box.size);
    if (hit != null) {
      setState(() => _selectedIndex = hit);
      return;
    }

    final points = [..._curve.points, normalized];
    final nextCurve = ToneCurve(points: points);
    final index = nextCurve.points.indexWhere(
      (point) => (point.input - normalized.input).abs() < 0.000001,
    );

    widget.onInteractionStart?.call();
    widget.onChanged(_replaceCurve(widget.toneCurves, _channel, nextCurve));
    widget.onInteractionEnd?.call();
    setState(() => _selectedIndex = index < 0 ? null : index);
  }

  void _handlePanStart(DragStartDetails details) {
    final box = _graphKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || box.size.isEmpty) return;

    final hit = _nearestPointIndex(details.localPosition, box.size);
    if (hit == null) return;

    _dragActive = true;
    _selectedIndex = hit;
    widget.onInteractionStart?.call();
    setState(() {});
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final index = _selectedIndex;
    if (!_dragActive || index == null) return;

    final box = _graphKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || box.size.isEmpty) return;

    final curve = _curve;
    final raw = _normalizedPoint(details.localPosition, box.size);
    final isFirst = index == 0;
    final isLast = index == curve.points.length - 1;
    final input = isFirst
        ? 0.0
        : isLast
        ? 1.0
        : raw.input
              .clamp(
                curve.points[index - 1].input + _minimumInputGap,
                curve.points[index + 1].input - _minimumInputGap,
              )
              .toDouble();

    final points = [...curve.points];
    points[index] = CurvePoint(input: input, output: raw.output);
    final nextCurve = ToneCurve(points: points);
    widget.onChanged(_replaceCurve(widget.toneCurves, _channel, nextCurve));
  }

  void _finishDrag() {
    if (!_dragActive) return;
    _dragActive = false;
    widget.onInteractionEnd?.call();
  }

  void _deleteSelectedPoint() {
    final index = _selectedIndex;
    final curve = _curve;
    if (index == null || index <= 0 || index >= curve.points.length - 1) return;

    final points = [...curve.points]..removeAt(index);
    widget.onInteractionStart?.call();
    widget.onChanged(
      _replaceCurve(widget.toneCurves, _channel, ToneCurve(points: points)),
    );
    widget.onInteractionEnd?.call();
    setState(() => _selectedIndex = null);
  }

  void _resetChannel() {
    widget.onInteractionStart?.call();
    widget.onChanged(
      _replaceCurve(widget.toneCurves, _channel, ToneCurve.identity),
    );
    widget.onInteractionEnd?.call();
    setState(() => _selectedIndex = null);
  }

  int? _nearestPointIndex(Offset position, Size size) {
    var bestDistance = double.infinity;
    int? bestIndex;
    for (var index = 0; index < _curve.points.length; index += 1) {
      final point = _offsetFor(_curve.points[index], size);
      final distance = (point - position).distance;
      if (distance <= _pointHitRadius && distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  CurvePoint _normalizedPoint(Offset position, Size size) {
    return CurvePoint(
      input: (position.dx / size.width).clamp(0.0, 1.0).toDouble(),
      output: (1 - (position.dy / size.height)).clamp(0.0, 1.0).toDouble(),
    );
  }

  Offset _offsetFor(CurvePoint point, Size size) {
    return Offset(point.input * size.width, (1 - point.output) * size.height);
  }

  static ToneCurve _curveFor(ToneCurves curves, ToneCurveChannel channel) {
    return switch (channel) {
      ToneCurveChannel.master => curves.master,
      ToneCurveChannel.red => curves.red,
      ToneCurveChannel.green => curves.green,
      ToneCurveChannel.blue => curves.blue,
    };
  }

  static ToneCurves _replaceCurve(
    ToneCurves curves,
    ToneCurveChannel channel,
    ToneCurve curve,
  ) {
    return switch (channel) {
      ToneCurveChannel.master => curves.copyWith(master: curve),
      ToneCurveChannel.red => curves.copyWith(red: curve),
      ToneCurveChannel.green => curves.copyWith(green: curve),
      ToneCurveChannel.blue => curves.copyWith(blue: curve),
    };
  }

  static String _channelLabel(ToneCurveChannel channel) => switch (channel) {
    ToneCurveChannel.master => 'Master',
    ToneCurveChannel.red => 'R',
    ToneCurveChannel.green => 'G',
    ToneCurveChannel.blue => 'B',
  };

  static String _percent(double value) => '${(value * 100).round()}';
}

class _ToneCurvePainter extends CustomPainter {
  const _ToneCurvePainter({
    required this.curve,
    required this.channel,
    required this.selectedIndex,
  });

  final ToneCurve curve;
  final ToneCurveChannel channel;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = AppColors.canvas;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      background,
    );

    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var step = 1; step < 4; step += 1) {
      final fraction = step / 4;
      canvas.drawLine(
        Offset(size.width * fraction, 0),
        Offset(size.width * fraction, size.height),
        grid,
      );
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        grid,
      );
    }

    final diagonal = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), diagonal);

    final curvePaint = Paint()
      ..color = _channelColor(channel)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var index = 0; index < curve.points.length; index += 1) {
      final point = curve.points[index];
      final offset = Offset(
        point.input * size.width,
        (1 - point.output) * size.height,
      );
      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    canvas.drawPath(path, curvePaint);

    for (var index = 0; index < curve.points.length; index += 1) {
      final point = curve.points[index];
      final offset = Offset(
        point.input * size.width,
        (1 - point.output) * size.height,
      );
      final selected = index == selectedIndex;
      final fill = Paint()
        ..color = selected ? _channelColor(channel) : AppColors.surfaceElevated;
      final border = Paint()
        ..color = _channelColor(channel)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.5 : 1.5;
      canvas.drawCircle(offset, selected ? 6 : 5, fill);
      canvas.drawCircle(offset, selected ? 6 : 5, border);
    }
  }

  static Color _channelColor(ToneCurveChannel channel) => switch (channel) {
    ToneCurveChannel.master => AppColors.textPrimary,
    ToneCurveChannel.red => const Color(0xFFE56A72),
    ToneCurveChannel.green => const Color(0xFF63C58B),
    ToneCurveChannel.blue => const Color(0xFF6D8DFF),
  };

  @override
  bool shouldRepaint(covariant _ToneCurvePainter oldDelegate) {
    return curve != oldDelegate.curve ||
        channel != oldDelegate.channel ||
        selectedIndex != oldDelegate.selectedIndex;
  }
}
