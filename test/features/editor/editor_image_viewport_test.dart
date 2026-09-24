import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_image_viewport.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_viewport_controller.dart';

void main() {
  testWidgets('shows empty state when no source image exists', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorImageViewport(
            sourceImagePath: null,
            adjustments: ImageAdjustments.initial,
            transform: ImageTransform.initial,
            onImportImage: () async {},
            isImporting: false,
          ),
        ),
      ),
    );

    expect(find.text('Open an image'), findsOneWidget);

    expect(find.text('Choose image'), findsOneWidget);

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('disables image selection while importing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorImageViewport(
            sourceImagePath: null,
            adjustments: ImageAdjustments.initial,
            transform: ImageTransform.initial,
            onImportImage: () async {},
            isImporting: true,
          ),
        ),
      ),
    );

    expect(find.text('Opening...'), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(button.onPressed, isNull);
  });

  testWidgets('shows zoom controls for a loaded image', (tester) async {
    final viewportController = EditorViewportController();
    addTearDown(viewportController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: EditorImageViewport(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: ImageAdjustments.initial,
              transform: ImageTransform.initial,
              onImportImage: () async {},
              isImporting: false,
              viewportController: viewportController,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('editor-viewport-interactive')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('editor-viewport-zoom-controls')),
      findsOneWidget,
    );
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('desktop zoom controls update and fit the viewport', (
    tester,
  ) async {
    final viewportController = EditorViewportController();
    addTearDown(viewportController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: EditorImageViewport(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: ImageAdjustments.initial,
              transform: ImageTransform.initial,
              onImportImage: () async {},
              isImporting: false,
              viewportController: viewportController,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('editor-viewport-zoom-in')));
    await tester.pump();

    expect(viewportController.scale, closeTo(1.25, 0.000001));
    expect(find.text('125%'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('editor-viewport-fit')));
    await tester.pump();

    expect(viewportController.isFitted, isTrue);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('compact zoom control is used on mobile layout', (tester) async {
    final viewportController = EditorViewportController();
    addTearDown(viewportController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 700,
            child: EditorImageViewport(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: ImageAdjustments.initial,
              transform: ImageTransform.initial,
              onImportImage: () async {},
              isImporting: false,
              viewportController: viewportController,
              compactZoomControls: true,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('editor-viewport-zoom-controls-compact')),
      findsOneWidget,
    );
    expect(find.text('Fit'), findsOneWidget);

    viewportController.setScale(
      2.0,
      focalPoint: const Offset(195, 350),
      viewportSize: const Size(390, 700),
    );
    await tester.pump();

    expect(find.text('200%'), findsOneWidget);
  });

  testWidgets('changing image resets transient viewport camera', (
    tester,
  ) async {
    final viewportController = EditorViewportController();
    addTearDown(viewportController.dispose);

    Widget buildViewport(String path) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: EditorImageViewport(
              sourceImagePath: path,
              adjustments: ImageAdjustments.initial,
              transform: ImageTransform.initial,
              onImportImage: () async {},
              isImporting: false,
              viewportController: viewportController,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildViewport('first-missing-image.jpg'));

    viewportController.setScale(
      2.0,
      focalPoint: const Offset(400, 300),
      viewportSize: const Size(800, 600),
    );
    await tester.pump();

    expect(viewportController.scale, closeTo(2.0, 0.000001));

    await tester.pumpWidget(buildViewport('second-missing-image.jpg'));
    await tester.pump();

    expect(viewportController.isFitted, isTrue);
  });
}
