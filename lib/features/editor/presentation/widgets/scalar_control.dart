import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ScalarValueSanitizer = double Function(double value);

class ScalarControl extends StatefulWidget {
  const ScalarControl({
    required this.controlId,
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    required this.precisionStep,
    required this.interactionStep,
    required this.coarseStep,
    required this.sanitize,
    required this.onChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.valueSuffix = '',
    this.enabled = true,
    super.key,
  }) : assert(precisionStep > 0),
       assert(interactionStep > 0),
       assert(coarseStep > 0),
       assert(maxValue > minValue);

  final String controlId;
  final String label;

  final double value;
  final double minValue;
  final double maxValue;
  final double defaultValue;

  final double precisionStep;
  final double interactionStep;
  final double coarseStep;

  final ScalarValueSanitizer sanitize;

  final ValueChanged<double> onChanged;

  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  final String valueSuffix;
  final bool enabled;

  @override
  State<ScalarControl> createState() => _ScalarControlState();
}

class _ScalarControlState extends State<ScalarControl> {
  late final FocusNode _sliderFocusNode;
  late final FocusNode _valueFocusNode;
  late final TextEditingController _valueController;

  static const Duration _wheelInteractionEndDelay = Duration(milliseconds: 300);

  bool _isEditingValue = false;
  bool _isDeferredInteractionActive = false;
  Timer? _deferredInteractionEndTimer;

  @override
  void initState() {
    super.initState();

    _sliderFocusNode = FocusNode(onKeyEvent: _handleSliderKeyEvent);
    _sliderFocusNode.addListener(_handleSliderFocusChange);

    _valueFocusNode = FocusNode(onKeyEvent: _handleValueKeyEvent);

    _valueController = TextEditingController();

    _valueFocusNode.addListener(_handleValueFocusChange);
  }

  @override
  void didUpdateWidget(covariant ScalarControl oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isEditingValue && oldWidget.value != widget.value) {
      _syncValueController();
    }
  }

  @override
  void dispose() {
    _deferredInteractionEndTimer?.cancel();

    _sliderFocusNode.removeListener(_handleSliderFocusChange);
    _valueFocusNode.removeListener(_handleValueFocusChange);

    _sliderFocusNode.dispose();
    _valueFocusNode.dispose();
    _valueController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sanitizedValue = widget.sanitize(widget.value);

    final sanitizedDefault = widget.sanitize(widget.defaultValue);

    final isDefault = sanitizedValue == sanitizedDefault;

    final divisions = _calculateDivisions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            _buildValueEditor(context, sanitizedValue),
            if (!isDefault) ...[
              const SizedBox(width: 4),
              IconButton(
                key: ValueKey('${widget.controlId}-reset'),
                onPressed: widget.enabled
                    ? () {
                        widget.onChanged(sanitizedDefault);
                      }
                    : null,
                tooltip: 'Reset ${widget.label}',
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
          key: ValueKey('${widget.controlId}-slider-interaction'),
          onPointerDown: widget.enabled
              ? (_) {
                  _sliderFocusNode.requestFocus();
                }
              : null,
          onPointerSignal: widget.enabled ? _handlePointerSignal : null,
          child: Slider(
            key: ValueKey('${widget.controlId}-slider'),
            value: sanitizedValue,
            min: widget.minValue,
            max: widget.maxValue,
            divisions: divisions,
            focusNode: _sliderFocusNode,
            onChangeStart: widget.enabled && widget.onInteractionStart != null
                ? (_) {
                    _finishDeferredInteraction();
                    widget.onInteractionStart!();
                  }
                : null,
            onChanged: widget.enabled
                ? (nextValue) {
                    widget.onChanged(widget.sanitize(nextValue));
                  }
                : null,
            onChangeEnd: widget.enabled && widget.onInteractionEnd != null
                ? (_) {
                    widget.onInteractionEnd!();
                  }
                : null,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatLimit(widget.minValue),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              _formatLimit(widget.maxValue),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueEditor(BuildContext context, double sanitizedValue) {
    if (_isEditingValue) {
      return SizedBox(
        width: 64,
        height: 32,
        child: TextField(
          key: ValueKey('${widget.controlId}-value-input'),
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
      message: 'Click to enter ${widget.label.toLowerCase()} value',
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
              _formatValue(sanitizedValue),
              key: ValueKey('${widget.controlId}-value'),
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

    GestureBinding.instance.pointerSignalResolver.register(
      event,
      _handleResolvedPointerSignal,
    );
  }

  void _handleResolvedPointerSignal(PointerSignalEvent event) {
    if (!widget.enabled || event is! PointerScrollEvent) {
      return;
    }

    if (event.scrollDelta.dy == 0) {
      return;
    }

    _sliderFocusNode.requestFocus();

    _beginDeferredInteraction();

    if (event.scrollDelta.dy < 0) {
      _adjustByCurrentStep(1);
    } else {
      _adjustByCurrentStep(-1);
    }

    _scheduleDeferredInteractionEnd();
  }

  KeyEventResult _handleSliderKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isIncrementKey =
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowRight;
    final isDecrementKey =
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft;

    if (!isIncrementKey && !isDecrementKey) {
      return KeyEventResult.ignored;
    }

    if (event is KeyUpEvent) {
      _finishDeferredInteraction();
      return KeyEventResult.handled;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    _beginDeferredInteraction();

    if (isIncrementKey) {
      _adjustByCurrentStep(1);
    } else {
      _adjustByCurrentStep(-1);
    }

    return KeyEventResult.handled;
  }

  void _beginDeferredInteraction() {
    if (_isDeferredInteractionActive) {
      return;
    }

    final onInteractionStart = widget.onInteractionStart;

    if (onInteractionStart == null) {
      return;
    }

    onInteractionStart();

    // Some mobile flows intentionally provide only an interaction-start
    // callback and keep the controller transaction open until focused mode
    // closes. In that case there is nothing for this control to debounce.
    if (widget.onInteractionEnd == null) {
      return;
    }

    _isDeferredInteractionActive = true;
  }

  void _scheduleDeferredInteractionEnd() {
    if (!_isDeferredInteractionActive) {
      return;
    }

    _deferredInteractionEndTimer?.cancel();

    _deferredInteractionEndTimer = Timer(
      _wheelInteractionEndDelay,
      _finishDeferredInteraction,
    );
  }

  void _finishDeferredInteraction() {
    _deferredInteractionEndTimer?.cancel();
    _deferredInteractionEndTimer = null;

    if (!_isDeferredInteractionActive) {
      return;
    }

    _isDeferredInteractionActive = false;
    widget.onInteractionEnd?.call();
  }

  void _handleSliderFocusChange() {
    if (!_sliderFocusNode.hasFocus) {
      _finishDeferredInteraction();
    }
  }

  KeyEventResult _handleValueKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) {
        _cancelValueEditing();
      }

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      _adjustEditingValueByStep(1);

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      _adjustEditingValueByStep(-1);

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _adjustEditingValueByStep(int direction) {
    final step = _stepForCurrentModifiers();

    final currentValue =
        double.tryParse(_valueController.text.trim()) ??
        widget.sanitize(widget.value);

    final nextValue = widget.sanitize(currentValue + (step * direction));

    final formattedValue = _formatNumber(nextValue);

    _valueController.value = TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }

  void _adjustByCurrentStep(int direction) {
    final step = _stepForCurrentModifiers();

    final nextValue = widget.sanitize(widget.value + (step * direction));

    widget.onChanged(nextValue);
  }

  double _stepForCurrentModifiers() {
    final keyboard = HardwareKeyboard.instance;

    if (keyboard.isControlPressed) {
      return widget.precisionStep;
    }

    if (keyboard.isShiftPressed) {
      return widget.coarseStep;
    }

    return widget.interactionStep;
  }

  void _beginValueEditing(double value) {
    _valueController.text = _formatNumber(value);

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
      widget.onChanged(widget.sanitize(parsedValue));
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
    _valueController.text = _formatNumber(widget.sanitize(widget.value));
  }

  int _calculateDivisions() {
    final range = widget.maxValue - widget.minValue;

    return (range / widget.interactionStep).round();
  }

  String _formatValue(double value) {
    final formatted = _formatNumber(value);

    final signed = value > 0 ? '+$formatted' : formatted;

    return '$signed${widget.valueSuffix}';
  }

  String _formatLimit(double value) {
    final formatted = _formatNumber(value);

    final signed = value > 0 ? '+$formatted' : formatted;

    return '$signed${widget.valueSuffix}';
  }

  String _formatNumber(double value) {
    final decimalPlaces = _decimalPlaces(widget.precisionStep);

    return value.toStringAsFixed(decimalPlaces);
  }

  int _decimalPlaces(double value) {
    final text = value.toString();

    if (!text.contains('.')) {
      return 0;
    }

    return text.split('.').last.length;
  }
}
