import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/presentation/widgets/composition_guide_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/composition_guide_overlay.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_guides_panel.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';
import 'package:presetstudio/theme/tokens/app_dimensions.dart';

void main() {
  testWidgets(
    'mobile guides panel exposes supported guide presentation state',
    (tester) async {
      final controller = CompositionGuideController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: PresetStudioTheme.dark,
          home: Scaffold(body: MobileGuidesPanel(controller: controller)),
        ),
      );

      expect(
        find.byKey(const ValueKey('mobile-guide-rule-of-thirds')),
        findsOneWidget,
      );
      expect(controller.guide, CompositionGuideType.ruleOfThirds);
      expect(find.byKey(const ValueKey('mobile-guide-rotate')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('mobile-guide-golden-spiral')),
      );
      await tester.pump();

      expect(controller.guide, CompositionGuideType.goldenSpiral);
      expect(find.byKey(const ValueKey('mobile-guide-rotate')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mobile-guide-rotate')));
      await tester.pump();
      expect(controller.orientation.normalizedQuarterTurns, 1);

      await tester.tap(
        find.byKey(const ValueKey('mobile-guide-flip-horizontal')),
      );
      await tester.pump();
      expect(controller.orientation.mirrored, isTrue);

      final opacity = tester.widget<Slider>(
        find.byKey(const ValueKey('mobile-guide-opacity')),
      );
      opacity.onChanged?.call(0.5);
      await tester.pump();
      expect(controller.opacity, 0.5);

      final colorTargetSize = tester.getSize(
        find.byKey(const ValueKey('mobile-guide-color-cyan')),
      );
      expect(
        colorTargetSize.shortestSide,
        greaterThanOrEqualTo(AppDimensions.mobileTouchTarget),
      );

      await tester.tap(find.byKey(const ValueKey('mobile-guide-color-cyan')));
      await tester.pump();
      expect(controller.color, CompositionGuideColor.cyan);

      await tester.tap(find.byKey(const ValueKey('mobile-guide-none')));
      await tester.pump();
      expect(controller.guide, CompositionGuideType.none);
      expect(find.byKey(const ValueKey('mobile-guide-opacity')), findsNothing);
    },
  );
}
