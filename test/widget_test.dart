import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/app/preset_studio_app.dart';

void main() {
  testWidgets('renders PresetStudio application shell', (tester) async {
    await tester.pumpWidget(const PresetStudioApp());

    expect(find.text('PresetStudio'), findsOneWidget);
    expect(find.text('Editor workspace'), findsOneWidget);
  });
}
