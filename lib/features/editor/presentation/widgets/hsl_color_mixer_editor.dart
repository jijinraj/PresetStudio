import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../domain/hsl_color_mixer.dart';
import 'editor_ruler_control.dart';

enum HslColorComponent { hue, saturation, luminance }

class HslColorMixerEditor extends StatefulWidget {
  const HslColorMixerEditor({
    required this.colorMixer,
    required this.onChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.initialRange = HslColorRange.red,
    this.initialComponent = HslColorComponent.saturation,
    this.compact = false,
    super.key,
  });

  final HslColorMixer colorMixer;
  final ValueChanged<HslColorMixer> onChanged;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final HslColorRange initialRange;
  final HslColorComponent initialComponent;
  final bool compact;

  @override
  State<HslColorMixerEditor> createState() => _HslColorMixerEditorState();
}

class _HslColorMixerEditorState extends State<HslColorMixerEditor> {
  late HslColorRange _range;
  late HslColorComponent _component;

  HslColorAdjustment get _adjustment => widget.colorMixer.adjustmentFor(_range);

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
    _component = widget.initialComponent;
  }

  @override
  Widget build(BuildContext context) {
    final adjustment = _adjustment;
    final value = _componentValue(adjustment, _component);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RangeSelector(
          selectedRange: _range,
          compact: widget.compact,
          onSelected: (range) {
            setState(() {
              _range = range;
            });
          },
        ),
        SizedBox(height: widget.compact ? AppSpacing.sm : AppSpacing.md),
        _ComponentSelector(
          selectedComponent: _component,
          onSelected: (component) {
            setState(() {
              _component = component;
            });
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        EditorRulerControl(
          key: ValueKey(
            'hsl-color-mixer-ruler-${_range.name}-${_component.name}',
          ),
          value: value,
          minValue: HslColorAdjustment.minimumValue,
          maxValue: HslColorAdjustment.maximumValue,
          defaultValue: 0,
          precisionStep: 1,
          interactionStep: 1,
          minorTickStep: 5,
          majorTickStep: 25,
          pixelsPerMinorTick: widget.compact ? 10 : 12,
          rulerHeight: widget.compact ? 64 : 72,
          semanticsLabel:
              '${_rangeLabel(_range)} ${_componentLabel(_component)}',
          onInteractionStart: widget.onInteractionStart,
          onInteractionEnd: widget.onInteractionEnd,
          onChanged: _updateSelectedComponent,
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const ValueKey('hsl-color-mixer-reset-range'),
            onPressed: adjustment.isNeutral ? null : _resetSelectedRange,
            icon: const Icon(Icons.restart_alt, size: 16),
            label: Text('Reset ${_rangeLabel(_range)}'),
          ),
        ),
      ],
    );
  }

  void _updateSelectedComponent(double value) {
    final current = _adjustment;
    final next = switch (_component) {
      HslColorComponent.hue => current.copyWith(hue: value),
      HslColorComponent.saturation => current.copyWith(saturation: value),
      HslColorComponent.luminance => current.copyWith(luminance: value),
    };

    widget.onChanged(widget.colorMixer.withAdjustment(_range, next));
  }

  void _resetSelectedRange() {
    if (_adjustment.isNeutral) {
      return;
    }

    widget.onInteractionStart?.call();
    widget.onChanged(
      widget.colorMixer.withAdjustment(_range, HslColorAdjustment.neutral),
    );
    widget.onInteractionEnd?.call();
  }

  static double _componentValue(
    HslColorAdjustment adjustment,
    HslColorComponent component,
  ) {
    return switch (component) {
      HslColorComponent.hue => adjustment.hue,
      HslColorComponent.saturation => adjustment.saturation,
      HslColorComponent.luminance => adjustment.luminance,
    };
  }

  static String _rangeLabel(HslColorRange range) {
    return switch (range) {
      HslColorRange.red => 'Red',
      HslColorRange.orange => 'Orange',
      HslColorRange.yellow => 'Yellow',
      HslColorRange.green => 'Green',
      HslColorRange.aqua => 'Aqua',
      HslColorRange.blue => 'Blue',
      HslColorRange.purple => 'Purple',
      HslColorRange.magenta => 'Magenta',
    };
  }

  static String _componentLabel(HslColorComponent component) {
    return switch (component) {
      HslColorComponent.hue => 'Hue',
      HslColorComponent.saturation => 'Saturation',
      HslColorComponent.luminance => 'Luminance',
    };
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selectedRange,
    required this.onSelected,
    required this.compact,
  });

  final HslColorRange selectedRange;
  final ValueChanged<HslColorRange> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Color range',
      child: Row(
        key: const ValueKey('hsl-color-mixer-range-selector'),
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: HslColorRange.values
            .map(
              (range) => _RangeButton(
                range: range,
                selected: range == selectedRange,
                compact: compact,
                onPressed: () => onSelected(range),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({
    required this.range,
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  final HslColorRange range;
  final bool selected;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = _rangeColor(range);
    final diameter = compact ? 28.0 : 32.0;

    return Semantics(
      button: true,
      selected: selected,
      label: _HslColorMixerEditorState._rangeLabel(range),
      child: Tooltip(
        message: _HslColorMixerEditorState._rangeLabel(range),
        child: InkResponse(
          key: ValueKey('hsl-color-mixer-range-${range.name}'),
          onTap: onPressed,
          radius: diameter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.borderStrong,
                width: selected ? 2.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }

  static Color _rangeColor(HslColorRange range) {
    return switch (range) {
      HslColorRange.red => const Color(0xFFE45757),
      HslColorRange.orange => const Color(0xFFF08A3C),
      HslColorRange.yellow => const Color(0xFFE7C94A),
      HslColorRange.green => const Color(0xFF58AE68),
      HslColorRange.aqua => const Color(0xFF48B8B8),
      HslColorRange.blue => const Color(0xFF4D7CFE),
      HslColorRange.purple => const Color(0xFF8B67D8),
      HslColorRange.magenta => const Color(0xFFD65AA6),
    };
  }
}

class _ComponentSelector extends StatelessWidget {
  const _ComponentSelector({
    required this.selectedComponent,
    required this.onSelected,
  });

  final HslColorComponent selectedComponent;
  final ValueChanged<HslColorComponent> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('hsl-color-mixer-component-selector'),
      children: HslColorComponent.values
          .map(
            (component) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: component == HslColorComponent.luminance
                      ? 0
                      : AppSpacing.xs,
                ),
                child: _ComponentButton(
                  component: component,
                  selected: component == selectedComponent,
                  onPressed: () => onSelected(component),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ComponentButton extends StatelessWidget {
  const _ComponentButton({
    required this.component,
    required this.selected,
    required this.onPressed,
  });

  final HslColorComponent component;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = _HslColorMixerEditorState._componentLabel(component);

    return TextButton(
      key: ValueKey('hsl-color-mixer-component-${component.name}'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? AppColors.textPrimary
            : AppColors.textSecondary,
        backgroundColor: selected ? AppColors.surfaceHover : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? AppColors.borderStrong : Colors.transparent,
          ),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
