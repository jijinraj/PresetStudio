import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';
import 'package:presetstudio/features/editor/presentation/widgets/hsl_color_mixer_editor.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('shows all eight color ranges and three HSL components', (
    tester,
  ) async {
    await tester.pumpWidget(const _Harness());

    for (final range in HslColorRange.values) {
      expect(
        find.byKey(ValueKey('hsl-color-mixer-range-${range.name}')),
        findsOneWidget,
      );
    }

    for (final component in HslColorComponent.values) {
      expect(
        find.byKey(ValueKey('hsl-color-mixer-component-${component.name}')),
        findsOneWidget,
      );
    }

    expect(find.text('Saturation'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('range selection shows that range value', (tester) async {
    final mixer = HslColorMixer.initial.copyWith(
      blue: HslColorAdjustment(saturation: 37),
    );

    await tester.pumpWidget(_Harness(colorMixer: mixer));

    await tester.tap(find.byKey(const ValueKey('hsl-color-mixer-range-blue')));
    await tester.pump();

    expect(find.text('+37'), findsOneWidget);
  });

  testWidgets('component selection routes ruler changes to selected field', (
    tester,
  ) async {
    final mixer = HslColorMixer.initial.copyWith(
      green: HslColorAdjustment(hue: 24, saturation: 31, luminance: -12),
    );
    HslColorMixer? changed;

    await tester.pumpWidget(
      _Harness(colorMixer: mixer, onChanged: (value) => changed = value),
    );

    await tester.tap(find.byKey(const ValueKey('hsl-color-mixer-range-green')));
    await tester.tap(
      find.byKey(const ValueKey('hsl-color-mixer-component-hue')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hsl-color-mixer-ruler-green-hue')),
      findsOneWidget,
    );
    expect(find.text('+24'), findsOneWidget);

    final surface = find.byKey(const ValueKey('editor-ruler-gesture-surface'));
    expect(surface, findsOneWidget);

    final detector = tester.widget<GestureDetector>(surface);
    detector.onDoubleTap!.call();
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!.green.hue, 0);
    expect(changed!.green.saturation, 31);
    expect(changed!.green.luminance, -12);
  });

  testWidgets('reset affects only selected color range in one interaction', (
    tester,
  ) async {
    final mixer = HslColorMixer.initial.copyWith(
      red: HslColorAdjustment(hue: 20, saturation: 30),
      blue: HslColorAdjustment(luminance: -25),
    );
    HslColorMixer? changed;
    var starts = 0;
    var ends = 0;

    await tester.pumpWidget(
      _Harness(
        colorMixer: mixer,
        onChanged: (value) => changed = value,
        onInteractionStart: () => starts += 1,
        onInteractionEnd: () => ends += 1,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('hsl-color-mixer-reset-range')));
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!.red, HslColorAdjustment.neutral);
    expect(changed!.blue, mixer.blue);
    expect(starts, 1);
    expect(ends, 1);
  });

  testWidgets('ruler interaction forwards transaction callbacks', (
    tester,
  ) async {
    var starts = 0;
    var ends = 0;

    await tester.pumpWidget(
      _Harness(
        colorMixer: HslColorMixer.initial.copyWith(
          red: HslColorAdjustment(saturation: 25),
        ),
        onInteractionStart: () => starts += 1,
        onInteractionEnd: () => ends += 1,
      ),
    );

    final surface = find.byKey(const ValueKey('editor-ruler-gesture-surface'));
    expect(surface, findsOneWidget);

    final detector = tester.widget<GestureDetector>(surface);
    detector.onDoubleTap!.call();
    await tester.pump();

    expect(starts, 1);
    expect(ends, 1);
  });
}

class _Harness extends StatefulWidget {
  const _Harness({
    this.colorMixer = HslColorMixer.initial,
    this.onChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  final HslColorMixer colorMixer;
  final ValueChanged<HslColorMixer>? onChanged;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late HslColorMixer mixer = widget.colorMixer;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PresetStudioTheme.dark,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            child: HslColorMixerEditor(
              colorMixer: mixer,
              onInteractionStart: widget.onInteractionStart,
              onInteractionEnd: widget.onInteractionEnd,
              onChanged: (value) {
                widget.onChanged?.call(value);
                setState(() => mixer = value);
              },
            ),
          ),
        ),
      ),
    );
  }
}
