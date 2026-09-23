import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_rotation_layout.dart';

void main() {
  group('EditorRotationLayout', () {
    testWidgets('reports rotated bounds for arbitrary angle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EditorRotationLayout(
                key: ValueKey('rotation-layout'),
                rotationDegrees: 45.0,
                child: SizedBox(width: 200.0, height: 100.0),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(
        find.byKey(const ValueKey('rotation-layout')),
      );

      final expected = 300.0 / math.sqrt(2.0);

      expect(size.width, closeTo(expected, 0.001));

      expect(size.height, closeTo(expected, 0.001));
    });

    testWidgets('scales rotated bounds to available space', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150.0,
                height: 150.0,
                child: Center(
                  child: EditorRotationLayout(
                    key: ValueKey('rotation-layout'),
                    rotationDegrees: 45.0,
                    child: SizedBox(width: 200.0, height: 100.0),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(
        find.byKey(const ValueKey('rotation-layout')),
      );

      expect(size.width, closeTo(150.0, 0.001));

      expect(size.height, closeTo(150.0, 0.001));
    });
  });
}
