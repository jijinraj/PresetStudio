import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_image_viewport.dart';

void main() {
  testWidgets('shows empty state when no source image exists', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorImageViewport(
            sourceImagePath: null,
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
}
