import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:presetstudio/features/editor/rendering/image_histogram.dart';

void main() {
  test('histogram reports source aspect ratio and normalized channel bins', () {
    final image = img.Image(width: 4, height: 2);
    for (final pixel in image) {
      pixel
        ..r = 255
        ..g = 0
        ..b = 0
        ..a = 255;
    }

    final histogram = ImageHistogram.fromBytes(img.encodePng(image));

    expect(histogram, isNotNull);
    expect(histogram!.aspectRatio, 2);
    expect(histogram.red[255], 1);
    expect(histogram.green[0], 1);
    expect(histogram.blue[0], 1);
    expect(histogram.luminance.any((value) => value == 1), isTrue);
  });
}
