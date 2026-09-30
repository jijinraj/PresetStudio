import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageHistogram {
  const ImageHistogram({
    required this.width,
    required this.height,
    required this.luminance,
    required this.red,
    required this.green,
    required this.blue,
  });

  final int width;
  final int height;
  final List<double> luminance;
  final List<double> red;
  final List<double> green;
  final List<double> blue;

  double get aspectRatio => width / height;

  static ImageHistogram? fromBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final source = img.bakeOrientation(decoded);
    final sample = source.width > 512 || source.height > 512
        ? img.copyResize(
            source,
            width: source.width >= source.height ? 512 : null,
            height: source.height > source.width ? 512 : null,
            interpolation: img.Interpolation.average,
          )
        : source;

    final l = List<int>.filled(256, 0);
    final r = List<int>.filled(256, 0);
    final g = List<int>.filled(256, 0);
    final b = List<int>.filled(256, 0);

    for (final pixel in sample) {
      final red = pixel.r.toInt().clamp(0, 255);
      final green = pixel.g.toInt().clamp(0, 255);
      final blue = pixel.b.toInt().clamp(0, 255);
      final luminance = (0.2126 * red + 0.7152 * green + 0.0722 * blue)
          .round()
          .clamp(0, 255);
      r[red] += 1;
      g[green] += 1;
      b[blue] += 1;
      l[luminance] += 1;
    }

    List<double> normalize(List<int> bins) {
      final peak = bins.fold<int>(
        1,
        (current, value) => value > current ? value : current,
      );
      return List<double>.unmodifiable(bins.map((value) => value / peak));
    }

    return ImageHistogram(
      width: source.width,
      height: source.height,
      luminance: normalize(l),
      red: normalize(r),
      green: normalize(g),
      blue: normalize(b),
    );
  }
}
