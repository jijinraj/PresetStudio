import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';

/// Precision, camera-style ruler control for editor values.
///
/// The center indicator remains stationary while the ruler moves beneath it.
/// The control is intentionally independent from the adjustment domain model so
/// it can also be reused by crop straightening and other numeric editor tools.
class EditorRulerControl extends StatefulWidget {
  const EditorRulerControl({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    required this.precisionStep,
    required this.interactionStep,
    required this.minorTickStep,
    required this.majorTickStep,
    required this.onChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.valueFormatter,
    this.labelFormatter,
    this.semanticsLabel,
    this.unit,
    this.showPositiveSign = true,
    this.enableHaptics = false,
    this.pixelsPerMinorTick = 12,
    this.rulerHeight = 72,
    super.key,
  }) : assert(maxValue > minValue),
       assert(defaultValue >= minValue && defaultValue <= maxValue),
       assert(precisionStep > 0),
       assert(interactionStep > 0),
       assert(minorTickStep > 0),
       assert(majorTickStep >= minorTickStep),
       assert(pixelsPerMinorTick > 0),
       assert(rulerHeight > 0);

  final double value;
  final double minValue;
  final double maxValue;
  final double defaultValue;

  /// Smallest representable value. Dragging is sanitized to this step.
  final double precisionStep;

  /// Meaningful keyboard/accessibility step and optional haptic interval.
  final double interactionStep;

  /// Numeric distance between adjacent ruler ticks.
  final double minorTickStep;

  /// Numeric distance between labeled major ticks.
  final double majorTickStep;

  final ValueChanged<double> onChanged;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  final String Function(double value)? valueFormatter;
  final String Function(double value)? labelFormatter;
  final String? semanticsLabel;
  final String? unit;
  final bool showPositiveSign;
  final bool enableHaptics;

  /// Horizontal visual spacing between adjacent minor ticks.
  final double pixelsPerMinorTick;
  final double rulerHeight;

  @override
  State<EditorRulerControl> createState() => _EditorRulerControlState();
}

class _EditorRulerControlState extends State<EditorRulerControl> {
  double? _dragWorkingValue;
  int? _lastHapticBucket;

  double get _sanitizedValue => _sanitize(widget.value);

  @override
  Widget build(BuildContext context) {
    final value = _sanitizedValue;

    return Semantics(
      label: widget.semanticsLabel,
      value: _formatCurrentValue(value),
      increasedValue: _formatCurrentValue(
        _sanitize(value + widget.interactionStep),
      ),
      decreasedValue: _formatCurrentValue(
        _sanitize(value - widget.interactionStep),
      ),
      onIncrease: value >= widget.maxValue
          ? null
          : () => _changeBy(widget.interactionStep),
      onDecrease: value <= widget.minValue
          ? null
          : () => _changeBy(-widget.interactionStep),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCurrentValue(value),
            key: const ValueKey('editor-ruler-current-value'),
            style: AppTypography.title.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            key: const ValueKey('editor-ruler-gesture-surface'),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) {
              _dragWorkingValue = value;
              _lastHapticBucket = _hapticBucket(value);
              widget.onInteractionStart?.call();
            },
            onHorizontalDragUpdate: (details) {
              final working = _dragWorkingValue ?? value;
              final deltaValue =
                  -(details.delta.dx / widget.pixelsPerMinorTick) *
                  widget.minorTickStep;
              final next = _sanitize(working + deltaValue);
              _dragWorkingValue = next;

              if (next == value && next == widget.value) {
                return;
              }

              _emitValue(next, allowHaptic: true);
            },
            onHorizontalDragEnd: (_) => _finishInteraction(),
            onHorizontalDragCancel: _finishInteraction,
            onDoubleTap: () {
              final resetValue = _sanitize(widget.defaultValue);
              if (resetValue == value) {
                return;
              }

              widget.onInteractionStart?.call();
              _emitValue(resetValue);
              widget.onInteractionEnd?.call();
            },
            child: SizedBox(
              height: widget.rulerHeight,
              width: double.infinity,
              child: CustomPaint(
                key: const ValueKey('editor-ruler-painter'),
                painter: _EditorRulerPainter(
                  value: value,
                  minValue: widget.minValue,
                  maxValue: widget.maxValue,
                  defaultValue: widget.defaultValue,
                  minorTickStep: widget.minorTickStep,
                  majorTickStep: widget.majorTickStep,
                  pixelsPerMinorTick: widget.pixelsPerMinorTick,
                  labelFormatter: _formatTickLabel,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finishInteraction() {
    _dragWorkingValue = null;
    _lastHapticBucket = null;
    widget.onInteractionEnd?.call();
  }

  void _changeBy(double delta) {
    final current = _sanitizedValue;
    final next = _sanitize(current + delta);

    if (next == current) {
      return;
    }

    widget.onInteractionStart?.call();
    _emitValue(next);
    widget.onInteractionEnd?.call();
  }

  void _emitValue(double value, {bool allowHaptic = false}) {
    widget.onChanged(value);

    if (!allowHaptic || !widget.enableHaptics) {
      return;
    }

    final bucket = _hapticBucket(value);
    if (bucket == _lastHapticBucket) {
      return;
    }

    _lastHapticBucket = bucket;
    HapticFeedback.selectionClick();
  }

  int _hapticBucket(double value) {
    return ((value - widget.defaultValue) / widget.interactionStep).round();
  }

  double _sanitize(double value) {
    final clamped = value.clamp(widget.minValue, widget.maxValue).toDouble();
    final steps = ((clamped - widget.minValue) / widget.precisionStep).round();
    final snapped = widget.minValue + (steps * widget.precisionStep);
    final decimalPlaces = _decimalPlaces(widget.precisionStep);
    final factor = math.pow(10, decimalPlaces).toDouble();
    final rounded = (snapped * factor).round() / factor;

    return rounded.clamp(widget.minValue, widget.maxValue).toDouble();
  }

  String _formatCurrentValue(double value) {
    final custom = widget.valueFormatter;
    if (custom != null) {
      return custom(value);
    }

    final decimals = _decimalPlaces(widget.precisionStep);
    final number = value.toStringAsFixed(decimals);
    final sign = widget.showPositiveSign && value > 0 ? '+' : '';
    final unit = widget.unit ?? '';

    return '$sign$number$unit';
  }

  String _formatTickLabel(double value) {
    final custom = widget.labelFormatter;
    if (custom != null) {
      return custom(value);
    }

    final decimals = _decimalPlaces(widget.majorTickStep);
    return value.toStringAsFixed(decimals);
  }

  static int _decimalPlaces(double value) {
    if (value == value.roundToDouble()) {
      return 0;
    }

    final text = value.toString();
    if (!text.contains('.')) {
      return 0;
    }

    return text.split('.').last.length;
  }
}

class _EditorRulerPainter extends CustomPainter {
  const _EditorRulerPainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    required this.minorTickStep,
    required this.majorTickStep,
    required this.pixelsPerMinorTick,
    required this.labelFormatter,
  });

  final double value;
  final double minValue;
  final double maxValue;
  final double defaultValue;
  final double minorTickStep;
  final double majorTickStep;
  final double pixelsPerMinorTick;
  final String Function(double value) labelFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    const tickTop = 17.0;
    const minorBottom = 36.0;
    const majorBottom = 43.0;
    const labelTop = 48.0;

    final minorPaint = Paint()
      ..color = AppColors.textDisabled
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1.2;
    final defaultPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.75)
      ..strokeWidth = 1.5;
    final centerPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2;

    final firstVisibleValue =
        value -
        (((centerX + pixelsPerMinorTick) / pixelsPerMinorTick) * minorTickStep);
    final lastVisibleValue =
        value +
        (((centerX + pixelsPerMinorTick) / pixelsPerMinorTick) * minorTickStep);

    final firstIndex = math
        .max(0, ((firstVisibleValue - minValue) / minorTickStep).floor())
        .toInt();
    final lastIndex = math
        .min(
          ((maxValue - minValue) / minorTickStep).round(),
          ((lastVisibleValue - minValue) / minorTickStep).ceil(),
        )
        .toInt();

    for (var index = firstIndex; index <= lastIndex; index += 1) {
      final tickValue = minValue + (index * minorTickStep);
      final x =
          centerX + ((tickValue - value) / minorTickStep) * pixelsPerMinorTick;

      if (x < -pixelsPerMinorTick || x > size.width + pixelsPerMinorTick) {
        continue;
      }

      final isMajor = _isMultipleFromDefault(tickValue, majorTickStep);
      final isDefault = _nearlyEqual(tickValue, defaultValue);
      final paint = isDefault
          ? defaultPaint
          : isMajor
          ? majorPaint
          : minorPaint;
      final bottom = isMajor ? majorBottom : minorBottom;

      canvas.drawLine(Offset(x, tickTop), Offset(x, bottom), paint);

      if (isMajor) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: labelFormatter(tickValue),
            style: AppTypography.label.copyWith(
              color: isDefault ? AppColors.accent : AppColors.textSecondary,
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

        labelPainter.paint(
          canvas,
          Offset(x - (labelPainter.width / 2), labelTop),
        );
      }
    }

    final indicatorPath = Path()
      ..moveTo(centerX - 5, 0)
      ..lineTo(centerX + 5, 0)
      ..lineTo(centerX, 7)
      ..close();
    canvas.drawPath(indicatorPath, centerPaint);
    canvas.drawLine(
      Offset(centerX, 8),
      Offset(centerX, majorBottom),
      centerPaint,
    );
  }

  bool _isMultipleFromDefault(double value, double step) {
    final ratio = (value - defaultValue) / step;
    return (ratio - ratio.round()).abs() < 0.000001;
  }

  bool _nearlyEqual(double a, double b) => (a - b).abs() < 0.000001;

  @override
  bool shouldRepaint(covariant _EditorRulerPainter oldDelegate) {
    return value != oldDelegate.value ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue ||
        defaultValue != oldDelegate.defaultValue ||
        minorTickStep != oldDelegate.minorTickStep ||
        majorTickStep != oldDelegate.majorTickStep ||
        pixelsPerMinorTick != oldDelegate.pixelsPerMinorTick ||
        labelFormatter != oldDelegate.labelFormatter;
  }
}
