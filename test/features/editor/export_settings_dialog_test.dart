import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/export_settings.dart';
import 'package:presetstudio/features/editor/presentation/widgets/export_settings_dialog.dart';

void main() {
  testWidgets('export dialog switches format-specific quality control', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExportSettingsDialog(initialSettings: ExportSettings.initial),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('export-quality-slider')), findsOneWidget);

    await tester.tap(find.text('PNG'));
    await tester.pump();

    expect(find.byKey(const ValueKey('export-quality-slider')), findsNothing);

    await tester.tap(find.text('WebP'));
    await tester.pump();

    expect(find.byKey(const ValueKey('export-quality-slider')), findsOneWidget);
  });

  testWidgets('longest-edge mode validates and returns export settings', (
    tester,
  ) async {
    ExportSettings? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await showExportSettingsDialog(
                    context,
                    initialSettings: ExportSettings.initial,
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limit longest edge'));
    await tester.pump();

    final field = find.byKey(const ValueKey('export-max-dimension'));
    expect(field, findsOneWidget);

    await tester.enterText(field, '');
    await tester.pump();

    final disabledButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('export-confirm')),
    );
    expect(disabledButton.onPressed, isNull);

    await tester.enterText(field, '4096');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('export-confirm')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.resolutionMode, ExportResolutionMode.maxDimension);
    expect(result!.maxDimension, 4096);
  });
}
