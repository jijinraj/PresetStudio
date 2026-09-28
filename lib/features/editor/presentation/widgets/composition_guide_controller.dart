import 'package:flutter/foundation.dart';

import 'composition_guide_overlay.dart';

/// Presentation-only composition-guide state shared by mobile Guides mode and
/// the crop workspace.
///
/// Guide settings intentionally live outside EditorSession so changing them
/// never dirties the image, creates History entries, affects presets, or
/// changes export output.
class CompositionGuideController extends ChangeNotifier {
  factory CompositionGuideController({
    CompositionGuideType guide = CompositionGuideType.ruleOfThirds,
    CompositionGuideOrientation orientation =
        const CompositionGuideOrientation(),
    CompositionGuideColor color = CompositionGuideColor.white,
    double opacity = 1.0,
  }) {
    return CompositionGuideController._(
      guide: guide,
      orientation: orientation,
      color: color,
      opacity: opacity.clamp(0.1, 1.0).toDouble(),
    );
  }

  CompositionGuideController._({
    required this._guide,
    required this._orientation,
    required this._color,
    required this._opacity,
  });

  CompositionGuideType _guide;
  CompositionGuideOrientation _orientation;
  CompositionGuideColor _color;
  double _opacity;

  CompositionGuideType get guide => _guide;
  CompositionGuideOrientation get orientation => _orientation;
  CompositionGuideColor get color => _color;
  double get opacity => _opacity;

  bool get hasGuide => _guide != CompositionGuideType.none;
  bool get supportsOrientation => _guide.supportsOrientation;

  void selectGuide(CompositionGuideType guide) {
    if (_guide == guide) {
      return;
    }

    _guide = guide;
    notifyListeners();
  }

  void setColor(CompositionGuideColor color) {
    if (_color == color) {
      return;
    }

    _color = color;
    notifyListeners();
  }

  void setOpacity(double opacity) {
    final next = opacity.clamp(0.1, 1.0).toDouble();
    if (_opacity == next) {
      return;
    }

    _opacity = next;
    notifyListeners();
  }

  void rotateClockwise() {
    if (!supportsOrientation) {
      return;
    }

    _orientation = _orientation.rotateClockwise();
    notifyListeners();
  }

  void flipHorizontal() {
    if (!supportsOrientation) {
      return;
    }

    _orientation = _orientation.flipHorizontal();
    notifyListeners();
  }

  void flipVertical() {
    if (!supportsOrientation) {
      return;
    }

    _orientation = _orientation.flipVertical();
    notifyListeners();
  }
}
