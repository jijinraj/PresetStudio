import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/app/preset_studio_app.dart';

void main() {
  testWidgets('renders desktop PresetStudio editor shell', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const PresetStudioApp());

    expect(find.text('PresetStudio'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Adjustments'), findsOneWidget);

    expect(find.text('Open an image'), findsOneWidget);
    expect(find.text('Choose image'), findsOneWidget);
  });
  testWidgets('renders mobile PresetStudio editor shell', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const PresetStudioApp());

    expect(find.text('PresetStudio'), findsOneWidget);
    expect(find.text('Open an image'), findsOneWidget);
    expect(find.text('Choose image'), findsOneWidget);

    expect(find.byKey(const ValueKey('mobile-tool-presets')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-tool-adjust')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-tool-crop')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-tool-guides')), findsOneWidget);
  });
}
