import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/adjustment_definition.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';
import 'package:presetstudio/features/editor/presentation/widgets/adjustment_control.dart';

void main() {
  group('Continuous history interaction grouping', () {
    testWidgets('mouse-wheel burst creates one history entry', (tester) async {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');

      await tester.pumpWidget(_HistoryHarness(controller: controller));

      final interaction = find.byKey(
        const ValueKey('adjustment-exposure-slider-interaction'),
      );

      Future<void> scrollUp() async {
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: tester.getCenter(interaction),
            scrollDelta: const Offset(0, -20),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }

      await scrollUp();
      await scrollUp();
      await scrollUp();

      expect(controller.session.adjustments.exposure, closeTo(0.3, 0.000001));
      expect(controller.isEditTransactionActive, isTrue);
      expect(controller.history, hasLength(1));

      await tester.pump(const Duration(milliseconds: 301));

      expect(controller.isEditTransactionActive, isFalse);
      expect(controller.history, hasLength(2));
      expect(controller.history.last.label, 'Exposure +0.30');
    });

    testWidgets('held arrow-key interaction creates one history entry', (
      tester,
    ) async {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');

      await tester.pumpWidget(_HistoryHarness(controller: controller));

      await tester.tap(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(controller.session.adjustments.exposure, closeTo(0.3, 0.000001));
      expect(controller.isEditTransactionActive, isTrue);
      expect(controller.history, hasLength(1));

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(controller.isEditTransactionActive, isFalse);
      expect(controller.history, hasLength(2));
      expect(controller.history.last.label, 'Exposure +0.30');
    });

    test(
      'transaction returning to its starting value creates no history entry',
      () {
        final controller = EditorController();
        addTearDown(controller.dispose);

        controller.setSourceImage('photo.jpg');

        controller.beginEditTransaction();
        controller.updateAdjustment(AdjustmentType.exposure, 1.2);
        controller.updateAdjustment(AdjustmentType.exposure, 0.0);
        controller.endEditTransaction();

        expect(controller.history, hasLength(1));
        expect(controller.history.single.label, 'Original');
        expect(controller.canUndo, isFalse);
      },
    );
  });
}

class _HistoryHarness extends StatelessWidget {
  const _HistoryHarness({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final definition = AdjustmentDefinitions.of(AdjustmentType.exposure);

    return MaterialApp(
      home: Scaffold(
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Center(
              child: SizedBox(
                width: 360,
                child: AdjustmentControl(
                  definition: definition,
                  value: controller.session.adjustments.exposure,
                  onChanged: (value) {
                    controller.updateAdjustment(AdjustmentType.exposure, value);
                  },
                  onInteractionStart: controller.beginEditTransaction,
                  onInteractionEnd: controller.endEditTransaction,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
