import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../domain/curve_point.dart';
import '../../domain/tone_curves.dart';

enum ToneCurveChannel { master, red, green, blue }

typedef ToneCurveBackgroundBuilder = Widget Function(ToneCurveChannel channel);

class ToneCurveEditor extends StatefulWidget {
  const ToneCurveEditor({
    required this.toneCurves,
    required this.onChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.initialChannel = ToneCurveChannel.master,
    this.graphHeight = 220,
    this.mobileOverlay = false,
    this.graphAspectRatio = 1,
    this.graphBackgroundBuilder,
    super.key,
  });

  final ToneCurves toneCurves;
  final ValueChanged<ToneCurves> onChanged;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final ToneCurveChannel initialChannel;
  final double graphHeight;
  final bool mobileOverlay;
  final double graphAspectRatio;
  final ToneCurveBackgroundBuilder? graphBackgroundBuilder;

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

    final selector = Row(
      key: const ValueKey('tone-curve-channel-selector'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ToneCurveChannel.values
          .map((channel) {
            return ChoiceChip(
              key: ValueKey('tone-curve-channel-${channel.name}'),
              avatar: widget.mobileOverlay
                  ? CircleAvatar(
                      radius: 5,
                      backgroundColor: _channelColor(channel),
                    )
                  : null,
              label: Text(_channelLabel(channel, mobile: widget.mobileOverlay)),
              selected: _channel == channel,
              onSelected: (_) => _selectChannel(channel),
            );
          })
          .toList(growable: false),
    );

    Widget buildGraph({double? maxHeight}) {
      final aspectRatio = widget.mobileOverlay ? widget.graphAspectRatio : 1.0;
      final graph = ClipRRect(
        borderRadius: BorderRadius.circular(widget.mobileOverlay ? 18 : 12),
        child: GestureDetector(
          key: _graphKey,
          behavior: HitTestBehavior.opaque,
          onTapUp: _handleTap,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: (_) => _finishDrag(),
          onPanCancel: _finishDrag,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.graphBackgroundBuilder != null)
                widget.graphBackgroundBuilder!(_channel),
              CustomPaint(
                key: const ValueKey('tone-curve-gesture-surface'),
                painter: _ToneCurvePainter(
                  curve: curve,
                  channel: _channel,
                  selectedIndex: selected,
                  transparentBackground: widget.graphBackgroundBuilder != null,
                ),
              ),
            ],
          ),
        ),
      );

      if (maxHeight == null) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.graphHeight),
            child: AspectRatio(aspectRatio: aspectRatio, child: graph),
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final widthFromHeight = maxHeight * aspectRatio;
          final width = widthFromHeight < constraints.maxWidth
              ? widthFromHeight
              : constraints.maxWidth;
          final height = width / aspectRatio;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: width, height: height, child: graph),
          );
        },
      );
    }

    if (widget.mobileOverlay) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Keep enough room for channel controls, readout, divider and the
          // bottom action row. The photo/curve rectangle gets the remainder.
          const controlsHeight = 164.0;
          final remainingHeight = constraints.maxHeight - controlsHeight;
          final availableGraphHeight = remainingHeight.clamp(0.0, 520.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildGraph(maxHeight: availableGraphHeight),
              const SizedBox(height: AppSpacing.sm),
              selector,
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  selectedPoint == null
                      ? 'Tap the image to add a curve point'
                      : 'Input  ${_percent(selectedPoint.input)}     │     Output  ${_percent(selectedPoint.output)}',
                  key: const ValueKey('tone-curve-point-readout'),
                  style: AppTypography.label,
                ),
              ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _CurveAction(
                      key: const ValueKey('tone-curve-add-point'),
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Add Point',
                      onPressed: _addPoint,
                    ),
                  ),
                  Expanded(
                    child: _CurveAction(
                      key: const ValueKey('tone-curve-delete-point'),
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete Point',
                      onPressed: canDelete ? _deleteSelectedPoint : null,
                    ),
                  ),
                  Expanded(
                    child: _CurveAction(
                      key: const ValueKey('tone-curve-reset-channel'),
                      icon: Icons.restart_alt_rounded,
                      label: 'Reset Channel',
                      onPressed: curve.isIdentity ? null : _resetChannel,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          children: ToneCurveChannel.values
              .map((channel) {
                return ChoiceChip(
                  key: ValueKey('tone-curve-channel-${channel.name}'),
                  label: Text(_channelLabel(channel, mobile: false)),
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
          child: buildGraph(),
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

  void _addPoint() {
    final points = _curve.points;
    var gapIndex = 0;
    var largestGap = -1.0;
    for (var i = 0; i < points.length - 1; i += 1) {
      final gap = points[i + 1].input - points[i].input;
      if (gap > largestGap) {
        largestGap = gap;
        gapIndex = i;
      }
    }
    final left = points[gapIndex];
    final right = points[gapIndex + 1];
    _commitPoint(
      CurvePoint(
        input: (left.input + right.input) / 2,
        output: (left.output + right.output) / 2,
      ),
    );
  }

  void _handleTap(TapUpDetails details) {
    final box = _graphKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || box.size.isEmpty) return;
    final hit = _nearestPointIndex(details.localPosition, box.size);
    if (hit != null) {
      setState(() => _selectedIndex = hit);
      return;
    }
    _commitPoint(_normalizedPoint(details.localPosition, box.size));
  }

  void _commitPoint(CurvePoint point) {
    final nextCurve = ToneCurve(points: [..._curve.points, point]);
    final index = nextCurve.points.indexWhere(
      (candidate) => (candidate.input - point.input).abs() < 0.000001,
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
    widget.onChanged(
      _replaceCurve(widget.toneCurves, _channel, ToneCurve(points: points)),
    );
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
      final distance =
          (_offsetFor(_curve.points[index], size) - position).distance;
      if (distance <= _pointHitRadius && distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  CurvePoint _normalizedPoint(Offset position, Size size) => CurvePoint(
    input: (position.dx / size.width).clamp(0.0, 1.0).toDouble(),
    output: (1 - (position.dy / size.height)).clamp(0.0, 1.0).toDouble(),
  );

  Offset _offsetFor(CurvePoint point, Size size) =>
      Offset(point.input * size.width, (1 - point.output) * size.height);

  static ToneCurve _curveFor(ToneCurves curves, ToneCurveChannel channel) =>
      switch (channel) {
        ToneCurveChannel.master => curves.master,
        ToneCurveChannel.red => curves.red,
        ToneCurveChannel.green => curves.green,
        ToneCurveChannel.blue => curves.blue,
      };

  static ToneCurves _replaceCurve(
    ToneCurves curves,
    ToneCurveChannel channel,
    ToneCurve curve,
  ) => switch (channel) {
    ToneCurveChannel.master => curves.copyWith(master: curve),
    ToneCurveChannel.red => curves.copyWith(red: curve),
    ToneCurveChannel.green => curves.copyWith(green: curve),
    ToneCurveChannel.blue => curves.copyWith(blue: curve),
  };

  static String _channelLabel(
    ToneCurveChannel channel, {
    required bool mobile,
  }) => switch (channel) {
    ToneCurveChannel.master => mobile ? 'RGB' : 'Master',
    ToneCurveChannel.red => 'R',
    ToneCurveChannel.green => 'G',
    ToneCurveChannel.blue => 'B',
  };

  static Color _channelColor(ToneCurveChannel channel) => switch (channel) {
    ToneCurveChannel.master => AppColors.textPrimary,
    ToneCurveChannel.red => const Color(0xFFE56A72),
    ToneCurveChannel.green => const Color(0xFF63C58B),
    ToneCurveChannel.blue => const Color(0xFF6D8DFF),
  };

  static String _percent(double value) => '${(value * 100).round()}';
}

class _CurveAction extends StatelessWidget {
  const _CurveAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ToneCurvePainter extends CustomPainter {
  const _ToneCurvePainter({
    required this.curve,
    required this.channel,
    required this.selectedIndex,
    required this.transparentBackground,
  });

  final ToneCurve curve;
  final ToneCurveChannel channel;
  final int? selectedIndex;
  final bool transparentBackground;

  @override
  void paint(Canvas canvas, Size size) {
    if (!transparentBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
        Paint()..color = AppColors.canvas,
      );
    }
    final grid = Paint()
      ..color = transparentBackground
          ? Colors.white.withValues(alpha: 0.22)
          : AppColors.border
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
      ..color = transparentBackground
          ? Colors.white.withValues(alpha: 0.35)
          : AppColors.borderStrong
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), diagonal);

    final color = _ToneCurveEditorState._channelColor(channel);
    final curvePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = transparentBackground ? 2.5 : 2
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
        ..color = selected ? color : AppColors.surfaceElevated;
      final border = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.5 : 1.5;
      canvas.drawCircle(offset, selected ? 7 : 5.5, fill);
      canvas.drawCircle(offset, selected ? 7 : 5.5, border);
    }
  }

  @override
  bool shouldRepaint(covariant _ToneCurvePainter oldDelegate) =>
      curve != oldDelegate.curve ||
      channel != oldDelegate.channel ||
      selectedIndex != oldDelegate.selectedIndex ||
      transparentBackground != oldDelegate.transparentBackground;
}
