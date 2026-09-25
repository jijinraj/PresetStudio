import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:presetstudio/features/editor/domain/editor_session.dart';
import 'package:presetstudio/features/editor/rendering/export_background_renderer.dart';

void main() {
  test('background export renderer returns encoded image bytes', () async {
    final source = img.Image(width: 4, height: 3);
    source.setPixelRgba(0, 0, 255, 0, 0, 255);

    final result = await renderExportInBackground(
      sourceBytes: Uint8List.fromList(img.encodePng(source)),
      session: const EditorSession(sourceImagePath: 'test.png'),
    );

    final decoded = img.decodeImage(result.bytes);

    expect(decoded, isNotNull);
    expect(decoded!.width, 4);
    expect(decoded.height, 3);
  });
}
