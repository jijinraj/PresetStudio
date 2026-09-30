import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/curve_point.dart';
import 'package:presetstudio/features/editor/domain/tone_curves.dart';
import 'package:presetstudio/features/editor/presentation/widgets/tone_curve_editor.dart';

void main() {
  testWidgets('shows master and RGB channel controls', (tester) async {
    await tester.pumpWidget(_Harness());

    expect(find.text('Master'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('tap adds a point to the selected channel', (tester) async {
    ToneCurves? changed;
    await tester.pumpWidget(_Harness(onChanged: (value) => changed = value));

    final surface = find.byKey(const ValueKey('tone-curve-gesture-surface'));
    final rect = tester.getRect(surface);
    await tester.tapAt(
      Offset(rect.left + rect.width * 0.5, rect.top + rect.height * 0.25),
    );
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!.master.points, hasLength(3));
    expect(changed!.master.points[1].input, closeTo(0.5, 0.02));
    expect(changed!.master.points[1].output, closeTo(0.75, 0.02));
  });

  testWidgets('channel selection routes edits to that RGB channel', (
    tester,
  ) async {
    ToneCurves? changed;
    await tester.pumpWidget(_Harness(onChanged: (value) => changed = value));

    await tester.tap(find.byKey(const ValueKey('tone-curve-channel-red')));
    await tester.pump();

    final surface = find.byKey(const ValueKey('tone-curve-gesture-surface'));
    final rect = tester.getRect(surface);
    await tester.tapAt(
      Offset(rect.left + rect.width * 0.5, rect.top + rect.height * 0.25),
    );
    await tester.pump();

    expect(changed!.master.isIdentity, isTrue);
    expect(changed!.red.points, hasLength(3));
    expect(changed!.green.isIdentity, isTrue);
    expect(changed!.blue.isIdentity, isTrue);
  });

  testWidgets('reset affects only the selected channel', (tester) async {
    final curves = ToneCurves.initial.copyWith(
      red: ToneCurve(
        points: [
          CurvePoint(input: 0, output: 0),
          CurvePoint(input: 0.5, output: 0.7),
          CurvePoint(input: 1, output: 1),
        ],
      ),
      blue: ToneCurve(
        points: [
          CurvePoint(input: 0, output: 0.1),
          CurvePoint(input: 1, output: 1),
        ],
      ),
    );
    ToneCurves? changed;
    await tester.pumpWidget(
      _Harness(
        toneCurves: curves,
        initialChannel: ToneCurveChannel.red,
        onChanged: (value) => changed = value,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('tone-curve-reset-channel')));
    await tester.pump();

    expect(changed!.red.isIdentity, isTrue);
    expect(changed!.blue, curves.blue);
  });

  testWidgets('adding a point is one interaction transaction', (tester) async {
    var starts = 0;
    var ends = 0;
    await tester.pumpWidget(
      _Harness(
        onInteractionStart: () => starts += 1,
        onInteractionEnd: () => ends += 1,
      ),
    );

    final surface = find.byKey(const ValueKey('tone-curve-gesture-surface'));
    final rect = tester.getRect(surface);
    await tester.tapAt(
      Offset(rect.left + rect.width * 0.5, rect.top + rect.height * 0.25),
    );
    await tester.pump();

    expect(starts, 1);
    expect(ends, 1);
  });
}

class _Harness extends StatefulWidget {
  const _Harness({
    this.toneCurves,
    this.initialChannel = ToneCurveChannel.master,
    this.onChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  final ToneCurves? toneCurves;
  final ToneCurveChannel initialChannel;
  final ValueChanged<ToneCurves>? onChanged;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late ToneCurves curves = widget.toneCurves ?? ToneCurves.initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: ToneCurveEditor(
              toneCurves: curves,
              initialChannel: widget.initialChannel,
              onInteractionStart: widget.onInteractionStart,
              onInteractionEnd: widget.onInteractionEnd,
              onChanged: (value) {
                widget.onChanged?.call(value);
                setState(() => curves = value);
              },
            ),
          ),
        ),
      ),
    );
  }
}
