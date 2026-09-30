import 'dart:math' as math;

import '../domain/image_adjustments.dart';
import '../domain/tone_curves.dart';
import 'tone_curve_lut.dart';

/// CPU counterpart of `shaders/editor_tonal.frag` used by full-resolution
/// export.
///
/// Keep the operation order and constants in sync with the preview shader so
/// exported color follows the same edit model instead of the simpler fallback
/// color matrix.
class ExportTonalProcessor {
  ExportTonalProcessor(this.adjustments, {ToneCurves? toneCurves})
    : toneCurveLut = ToneCurveLut.fromToneCurves(
        toneCurves ?? ToneCurves.initial,
      );

  static const double _redLuminance = 0.2126;
  static const double _greenLuminance = 0.7152;
  static const double _blueLuminance = 0.0722;

  final ImageAdjustments adjustments;
  final ToneCurveLut toneCurveLut;

  (double, double, double) apply(
    double r,
    double g,
    double b, {
    double normalizedX = 0.5,
    double normalizedY = 0.5,
    double aspectRatio = 1.0,
  }) {
    final exposureMultiplier = math.pow(2.0, adjustments.exposure).toDouble();

    r *= exposureMultiplier;
    g *= exposureMultiplier;
    b *= exposureMultiplier;

    final tonalLuminance = _luminance(r, g, b).clamp(0.0, 1.0).toDouble();

    final shadowMask = 1.0 - _smoothstep(0.05, 0.65, tonalLuminance);
    final highlightMask = _smoothstep(0.35, 0.95, tonalLuminance);
    final blackMask = 1.0 - _smoothstep(0.0, 0.28, tonalLuminance);
    final whiteMask = _smoothstep(0.72, 1.0, tonalLuminance);

    final tonalDelta =
        (adjustments.shadows / 100.0) * shadowMask * 0.28 +
        (adjustments.highlights / 100.0) * highlightMask * 0.28 +
        (adjustments.blacks / 100.0) * blackMask * 0.18 +
        (adjustments.whites / 100.0) * whiteMask * 0.18;

    r += tonalDelta;
    g += tonalDelta;
    b += tonalDelta;

    final contrastFactor = 1.0 + (adjustments.contrast / 100.0);
    r = ((r - 0.5) * contrastFactor) + 0.5;
    g = ((g - 0.5) * contrastFactor) + 0.5;
    b = ((b - 0.5) * contrastFactor) + 0.5;

    final normalizedTemperature = adjustments.temperature / 100.0;
    final normalizedTint = adjustments.tint / 100.0;

    r *= 1.0 + (normalizedTemperature * 0.12) + (normalizedTint * 0.05);
    g *= 1.0 + (normalizedTemperature * 0.02) - (normalizedTint * 0.08);
    b *= 1.0 - (normalizedTemperature * 0.12) + (normalizedTint * 0.05);

    if (adjustments.vibrance != 0.0) {
      final luminance = _luminance(r, g, b);
      final maximum = math.max(r, math.max(g, b));
      final minimum = math.min(r, math.min(g, b));
      final chroma = (maximum - minimum).clamp(0.0, 1.0).toDouble();
      final normalizedVibrance = adjustments.vibrance / 100.0;
      final factor = normalizedVibrance >= 0.0
          ? 1.0 + (normalizedVibrance * (1.0 - chroma) * 0.85)
          : 1.0 + (normalizedVibrance * 0.85);

      r = _mix(luminance, r, factor);
      g = _mix(luminance, g, factor);
      b = _mix(luminance, b, factor);
    }

    final saturationFactor = 1.0 + (adjustments.saturation / 100.0);
    final saturationLuminance = _luminance(r, g, b);

    r = _mix(saturationLuminance, r, saturationFactor);
    g = _mix(saturationLuminance, g, saturationFactor);
    b = _mix(saturationLuminance, b, saturationFactor);

    r = ToneCurveLut.sample(toneCurveLut.red, r);
    g = ToneCurveLut.sample(toneCurveLut.green, g);
    b = ToneCurveLut.sample(toneCurveLut.blue, b);

    if (adjustments.vignetteAmount != 0.0) {
      final centeredX = (normalizedX - 0.5) * aspectRatio;
      final centeredY = normalizedY - 0.5;
      final maxRadius = math.sqrt(
        (0.5 * aspectRatio) * (0.5 * aspectRatio) + 0.25,
      );
      final radius =
          math.sqrt(centeredX * centeredX + centeredY * centeredY) / maxRadius;
      final feather = (adjustments.vignetteFeather / 100.0)
          .clamp(0.0, 1.0)
          .toDouble();
      final start = _mix(0.78, 0.18, feather);
      final mask = _smoothstep(start, 1.0, radius);
      final strength =
          (adjustments.vignetteAmount / 100.0).clamp(-1.0, 1.0).toDouble() *
          0.85;

      if (strength >= 0.0) {
        final factor = 1.0 - strength * mask;
        r *= factor;
        g *= factor;
        b *= factor;
      } else {
        final lift = -strength * mask;
        r += (1.0 - r) * lift;
        g += (1.0 - g) * lift;
        b += (1.0 - b) * lift;
      }
    }

    return (
      r.clamp(0.0, 1.0).toDouble(),
      g.clamp(0.0, 1.0).toDouble(),
      b.clamp(0.0, 1.0).toDouble(),
    );
  }

  static double _luminance(double r, double g, double b) {
    return (r * _redLuminance) + (g * _greenLuminance) + (b * _blueLuminance);
  }

  static double _smoothstep(double edge0, double edge1, double value) {
    final t = ((value - edge0) / (edge1 - edge0)).clamp(0.0, 1.0).toDouble();

    return t * t * (3.0 - (2.0 * t));
  }

  static double _mix(double left, double right, double amount) {
    return left * (1.0 - amount) + right * amount;
  }
}
