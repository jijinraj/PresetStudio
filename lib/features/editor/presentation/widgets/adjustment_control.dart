import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/adjustment_definition.dart';

class AdjustmentControl extends StatefulWidget {
  const AdjustmentControl({
    required this.definition,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final AdjustmentDefinition definition;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  State<AdjustmentControl> createState() => _AdjustmentControlState();
}

class _AdjustmentControlState extends State<AdjustmentControl> {
  late final FocusNode _sliderFocusNode;
  late final FocusNode _valueFocusNode;
  late final TextEditingController _valueController;

  bool _isEditingValue = false;

  @override
  void initState() {
    super.initState();

    _sliderFocusNode = FocusNode(onKeyEvent: _handleSliderKeyEvent);

    _valueFocusNode = FocusNode(onKeyEvent: _handleValueKeyEvent);

    _valueController = TextEditingController();

    _valueFocusNode.addListener(_handleValueFocusChange);
  }

  @override
  void didUpdateWidget(covariant AdjustmentControl oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isEditingValue && oldWidget.value != widget.value) {
      _syncValueController();
    }
  }

  @override
  void dispose() {
    _valueFocusNode.removeListener(_handleValueFocusChange);

    _sliderFocusNode.dispose();
    _valueFocusNode.dispose();
    _valueController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final definition = widget.definition;
    final sanitizedValue = definition.sanitize(widget.value);

    final isDefault = sanitizedValue == definition.defaultValue;

    final divisions = _calculateDivisions(definition);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                definition.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            _buildValueEditor(context, sanitizedValue),
            if (!isDefault) ...[
              const SizedBox(width: 4),
              IconButton(
                key: ValueKey('adjustment-${definition.type.name}-reset'),
                onPressed: widget.enabled
                    ? () {
                        widget.onChanged(definition.defaultValue);
                      }
                    : null,
                tooltip: 'Reset ${definition.label}',
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ],
        ),
        Listener(
          key: ValueKey(
            'adjustment-${definition.type.name}-slider-interaction',
          ),
          onPointerDown: widget.enabled
              ? (_) {
                  _sliderFocusNode.requestFocus();
                }
              : null,
          onPointerSignal: widget.enabled ? _handlePointerSignal : null,
          child: Slider(
            key: ValueKey('adjustment-${definition.type.name}-slider'),
            value: sanitizedValue,
            min: definition.minValue,
            max: definition.maxValue,
            divisions: divisions,
            focusNode: _sliderFocusNode,
            onChanged: widget.enabled
                ? (nextValue) {
                    widget.onChanged(definition.sanitize(nextValue));
                  }
                : null,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatLimit(definition.minValue, definition.step),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              _formatLimit(definition.maxValue, definition.step),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueEditor(BuildContext context, double sanitizedValue) {
    final definition = widget.definition;

    if (_isEditingValue) {
      return SizedBox(
        width: 64,
        height: 32,
        child: TextField(
          key: ValueKey('adjustment-${definition.type.name}-value-input'),
          controller: _valueController,
          focusNode: _valueFocusNode,
          enabled: widget.enabled,
          autofocus: true,
          textAlign: TextAlign.end,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textInputAction: TextInputAction.done,
          style: Theme.of(context).textTheme.bodySmall,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          onSubmitted: (_) {
            _commitValueEditing();
          },
        ),
      );
    }

    return Tooltip(
      message: 'Click to enter ${definition.label.toLowerCase()} value',
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.text : MouseCursor.defer,
        child: GestureDetector(
          onTap: widget.enabled
              ? () {
                  _beginValueEditing(sanitizedValue);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              _formatValue(sanitizedValue, definition.step),
              key: ValueKey('adjustment-${definition.type.name}-value'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!widget.enabled || event is! PointerScrollEvent) {
      return;
    }

    if (event.scrollDelta.dy == 0) {
      return;
    }

    _sliderFocusNode.requestFocus();

    if (event.scrollDelta.dy < 0) {
      _adjustByStep(1);
    } else {
      _adjustByStep(-1);
    }
  }

  KeyEventResult _handleSliderKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowRight) {
      _adjustByStep(1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft) {
      _adjustByStep(-1);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleValueKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelValueEditing();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _adjustByStep(int direction) {
    final definition = widget.definition;

    final nextValue = definition.sanitize(
      widget.value + (definition.step * direction),
    );

    widget.onChanged(nextValue);
  }

  void _beginValueEditing(double value) {
    _valueController.text = _formatNumber(value, widget.definition.step);

    _valueController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _valueController.text.length,
    );

    setState(() {
      _isEditingValue = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _valueFocusNode.requestFocus();
      }
    });
  }

  void _commitValueEditing() {
    if (!_isEditingValue) {
      return;
    }

    final parsedValue = double.tryParse(_valueController.text.trim());

    if (parsedValue != null) {
      final sanitizedValue = widget.definition.sanitize(parsedValue);

      widget.onChanged(sanitizedValue);
    }

    setState(() {
      _isEditingValue = false;
    });

    _valueFocusNode.unfocus();
  }

  void _cancelValueEditing() {
    if (!_isEditingValue) {
      return;
    }

    setState(() {
      _isEditingValue = false;
    });

    _syncValueController();
    _valueFocusNode.unfocus();
  }

  void _handleValueFocusChange() {
    if (!_valueFocusNode.hasFocus && _isEditingValue) {
      _commitValueEditing();
    }
  }

  void _syncValueController() {
    _valueController.text = _formatNumber(
      widget.definition.sanitize(widget.value),
      widget.definition.step,
    );
  }

  int _calculateDivisions(AdjustmentDefinition definition) {
    final range = definition.maxValue - definition.minValue;

    return (range / definition.step).round();
  }

  String _formatValue(double value, double step) {
    final formatted = _formatNumber(value, step);

    if (value > 0) {
      return '+$formatted';
    }

    return formatted;
  }

  String _formatLimit(double value, double step) {
    final formatted = _formatNumber(value, step);

    if (value > 0) {
      return '+$formatted';
    }

    return formatted;
  }

  String _formatNumber(double value, double step) {
    if (step >= 1.0) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }
}
