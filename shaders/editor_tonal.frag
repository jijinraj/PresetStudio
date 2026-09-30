#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform float u_exposure;
uniform float u_contrast;
uniform float u_highlights;
uniform float u_shadows;
uniform float u_whites;
uniform float u_blacks;
uniform float u_temperature;
uniform float u_tint;
uniform float u_vibrance;
uniform float u_saturation;
uniform float u_vignetteAmount;
uniform float u_vignetteFeather;

uniform vec4 u_curveRed0;
uniform vec4 u_curveRed1;
uniform vec4 u_curveRed2;
uniform vec4 u_curveRed3;
uniform vec4 u_curveGreen0;
uniform vec4 u_curveGreen1;
uniform vec4 u_curveGreen2;
uniform vec4 u_curveGreen3;
uniform vec4 u_curveBlue0;
uniform vec4 u_curveBlue1;
uniform vec4 u_curveBlue2;
uniform vec4 u_curveBlue3;

uniform vec3 u_hslRed;
uniform vec3 u_hslOrange;
uniform vec3 u_hslYellow;
uniform vec3 u_hslGreen;
uniform vec3 u_hslAqua;
uniform vec3 u_hslBlue;
uniform vec3 u_hslPurple;
uniform vec3 u_hslMagenta;

uniform sampler2D u_texture;

out vec4 fragColor;

const vec3 kLuminance = vec3(0.2126, 0.7152, 0.0722);

float curveSample(
  int index,
  vec4 group0,
  vec4 group1,
  vec4 group2,
  vec4 group3
) {
  if (index == 0) return group0.x;
  if (index == 1) return group0.y;
  if (index == 2) return group0.z;
  if (index == 3) return group0.w;
  if (index == 4) return group1.x;
  if (index == 5) return group1.y;
  if (index == 6) return group1.z;
  if (index == 7) return group1.w;
  if (index == 8) return group2.x;
  if (index == 9) return group2.y;
  if (index == 10) return group2.z;
  if (index == 11) return group2.w;
  if (index == 12) return group3.x;
  if (index == 13) return group3.y;
  if (index == 14) return group3.z;
  return group3.w;
}

float applyCurve(
  float value,
  vec4 group0,
  vec4 group1,
  vec4 group2,
  vec4 group3
) {
  float position = clamp(value, 0.0, 1.0) * 15.0;
  int lowerIndex = int(floor(position));
  int upperIndex = lowerIndex < 15 ? lowerIndex + 1 : 15;
  float fraction = position - float(lowerIndex);

  float lower = curveSample(
    lowerIndex,
    group0,
    group1,
    group2,
    group3
  );
  float upper = curveSample(
    upperIndex,
    group0,
    group1,
    group2,
    group3
  );

  return mix(lower, upper, fraction);
}

vec3 applyToneCurves(vec3 rgb) {
  return vec3(
    applyCurve(rgb.r, u_curveRed0, u_curveRed1, u_curveRed2, u_curveRed3),
    applyCurve(
      rgb.g,
      u_curveGreen0,
      u_curveGreen1,
      u_curveGreen2,
      u_curveGreen3
    ),
    applyCurve(
      rgb.b,
      u_curveBlue0,
      u_curveBlue1,
      u_curveBlue2,
      u_curveBlue3
    )
  );
}

vec3 applyTonalRanges(
  vec3 rgb,
  float highlights,
  float shadows,
  float whites,
  float blacks
) {
  float luminance = clamp(dot(rgb, kLuminance), 0.0, 1.0);

  float shadowMask = 1.0 - smoothstep(0.05, 0.65, luminance);
  float highlightMask = smoothstep(0.35, 0.95, luminance);

  float blackMask = 1.0 - smoothstep(0.0, 0.28, luminance);
  float whiteMask = smoothstep(0.72, 1.0, luminance);

  float tonalDelta =
      (shadows / 100.0) * shadowMask * 0.28 +
      (highlights / 100.0) * highlightMask * 0.28 +
      (blacks / 100.0) * blackMask * 0.18 +
      (whites / 100.0) * whiteMask * 0.18;

  return rgb + vec3(tonalDelta);
}

vec3 applyContrast(vec3 rgb, float contrast) {
  float factor = 1.0 + (contrast / 100.0);
  return ((rgb - vec3(0.5)) * factor) + vec3(0.5);
}

vec3 applyColorBalance(vec3 rgb, float temperature, float tint) {
  float normalizedTemperature = temperature / 100.0;
  float normalizedTint = tint / 100.0;

  vec3 channelScale = vec3(
    1.0 + normalizedTemperature * 0.12 + normalizedTint * 0.05,
    1.0 + normalizedTemperature * 0.02 - normalizedTint * 0.08,
    1.0 - normalizedTemperature * 0.12 + normalizedTint * 0.05
  );

  return rgb * channelScale;
}

vec3 applyVibrance(vec3 rgb, float vibrance) {
  if (vibrance == 0.0) {
    return rgb;
  }

  float luminance = dot(rgb, kLuminance);
  float maximum = max(max(rgb.r, rgb.g), rgb.b);
  float minimum = min(min(rgb.r, rgb.g), rgb.b);
  float chroma = clamp(maximum - minimum, 0.0, 1.0);
  float normalizedVibrance = vibrance / 100.0;

  float factor = normalizedVibrance >= 0.0
      ? 1.0 + normalizedVibrance * (1.0 - chroma) * 0.85
      : 1.0 + normalizedVibrance * 0.85;

  return mix(vec3(luminance), rgb, factor);
}

vec3 applySaturation(vec3 rgb, float saturation) {
  float factor = 1.0 + (saturation / 100.0);
  float luminance = dot(rgb, kLuminance);
  return mix(vec3(luminance), rgb, factor);
}


float hueDistance(float a, float b) {
  float distance = abs(a - b);
  return min(distance, 1.0 - distance);
}

float hueWeight(float hue, float center) {
  // 60 degrees of influence on either side. Adjacent ranges overlap and the
  // weighted result is normalized, avoiding hard boundaries between bands.
  return max(0.0, 1.0 - (hueDistance(hue, center) * 6.0));
}

vec3 rgbToHsl(vec3 color) {
  float maximum = max(max(color.r, color.g), color.b);
  float minimum = min(min(color.r, color.g), color.b);
  float chroma = maximum - minimum;
  float lightness = (maximum + minimum) * 0.5;

  if (chroma <= 0.000001) {
    return vec3(0.0, 0.0, lightness);
  }

  float saturation = chroma / max(
    0.000001,
    1.0 - abs((2.0 * lightness) - 1.0)
  );

  float hue;
  if (maximum == color.r) {
    hue = mod((color.g - color.b) / chroma, 6.0);
  } else if (maximum == color.g) {
    hue = ((color.b - color.r) / chroma) + 2.0;
  } else {
    hue = ((color.r - color.g) / chroma) + 4.0;
  }

  hue = mod(hue / 6.0, 1.0);
  if (hue < 0.0) {
    hue += 1.0;
  }

  return vec3(hue, saturation, lightness);
}

float hueToRgb(float p, float q, float t) {
  if (t < 0.0) t += 1.0;
  if (t > 1.0) t -= 1.0;
  if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
  if (t < 1.0 / 2.0) return q;
  if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
  return p;
}

vec3 hslToRgb(vec3 hsl) {
  float hue = mod(hsl.x, 1.0);
  if (hue < 0.0) {
    hue += 1.0;
  }

  float saturation = clamp(hsl.y, 0.0, 1.0);
  float lightness = clamp(hsl.z, 0.0, 1.0);

  if (saturation <= 0.000001) {
    return vec3(lightness);
  }

  float q = lightness < 0.5
      ? lightness * (1.0 + saturation)
      : lightness + saturation - lightness * saturation;
  float p = (2.0 * lightness) - q;

  return vec3(
    hueToRgb(p, q, hue + 1.0 / 3.0),
    hueToRgb(p, q, hue),
    hueToRgb(p, q, hue - 1.0 / 3.0)
  );
}

vec3 applyHslColorMixer(vec3 rgb) {
  vec3 hsl = rgbToHsl(clamp(rgb, 0.0, 1.0));

  // Near-neutral pixels have no meaningful hue and should not acquire color
  // merely because a selective band is edited.
  if (hsl.y <= 0.000001) {
    return rgb;
  }

  float weights[8];
  weights[0] = hueWeight(hsl.x, 0.0);
  weights[1] = hueWeight(hsl.x, 30.0 / 360.0);
  weights[2] = hueWeight(hsl.x, 60.0 / 360.0);
  weights[3] = hueWeight(hsl.x, 120.0 / 360.0);
  weights[4] = hueWeight(hsl.x, 180.0 / 360.0);
  weights[5] = hueWeight(hsl.x, 240.0 / 360.0);
  weights[6] = hueWeight(hsl.x, 270.0 / 360.0);
  weights[7] = hueWeight(hsl.x, 315.0 / 360.0);

  float weightSum = 0.0;
  vec3 adjustment = vec3(0.0);

  weightSum += weights[0];
  adjustment += u_hslRed * weights[0];
  weightSum += weights[1];
  adjustment += u_hslOrange * weights[1];
  weightSum += weights[2];
  adjustment += u_hslYellow * weights[2];
  weightSum += weights[3];
  adjustment += u_hslGreen * weights[3];
  weightSum += weights[4];
  adjustment += u_hslAqua * weights[4];
  weightSum += weights[5];
  adjustment += u_hslBlue * weights[5];
  weightSum += weights[6];
  adjustment += u_hslPurple * weights[6];
  weightSum += weights[7];
  adjustment += u_hslMagenta * weights[7];

  if (weightSum <= 0.000001) {
    return rgb;
  }

  adjustment /= weightSum;

  // Hue ±100 maps to ±30 degrees. Saturation and luminance use normalized
  // ±1 deltas with headroom-aware positive movement.
  hsl.x = mod(hsl.x + (adjustment.x / 100.0) / 12.0, 1.0);
  if (hsl.x < 0.0) {
    hsl.x += 1.0;
  }

  float saturationDelta = adjustment.y / 100.0;
  hsl.y = saturationDelta >= 0.0
      ? hsl.y + (1.0 - hsl.y) * saturationDelta
      : hsl.y * (1.0 + saturationDelta);

  float luminanceDelta = adjustment.z / 100.0;
  hsl.z = luminanceDelta >= 0.0
      ? hsl.z + (1.0 - hsl.z) * luminanceDelta
      : hsl.z * (1.0 + luminanceDelta);

  return hslToRgb(hsl);
}

vec3 applyVignette(
  vec3 rgb,
  vec2 uv,
  vec2 size,
  float amount,
  float feather
) {
  if (amount == 0.0) {
    return rgb;
  }

  float aspect = size.x / max(size.y, 1.0);
  vec2 centered = vec2((uv.x - 0.5) * aspect, uv.y - 0.5);
  float maxRadius = length(vec2(0.5 * aspect, 0.5));
  float radius = length(centered) / max(maxRadius, 0.0001);
  float featherValue = clamp(feather / 100.0, 0.0, 1.0);
  float start = mix(0.78, 0.18, featherValue);
  float mask = smoothstep(start, 1.0, radius);
  float strength = clamp(amount / 100.0, -1.0, 1.0) * 0.85;

  if (strength >= 0.0) {
    return rgb * (1.0 - strength * mask);
  }

  return rgb + (vec3(1.0) - rgb) * (-strength * mask);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  vec4 sampled = texture(u_texture, uv);

  if (sampled.a <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  vec3 rgb = sampled.rgb / sampled.a;

  rgb *= pow(2.0, u_exposure);
  rgb = applyTonalRanges(
    rgb,
    u_highlights,
    u_shadows,
    u_whites,
    u_blacks
  );
  rgb = applyContrast(rgb, u_contrast);
  rgb = applyColorBalance(rgb, u_temperature, u_tint);
  rgb = applyVibrance(rgb, u_vibrance);
  rgb = applySaturation(rgb, u_saturation);

  // Selective HSL operates after the global color controls and before Curves.
  // Neutral HSL state is an identity operation.
  rgb = applyHslColorMixer(clamp(rgb, 0.0, 1.0));

  // Curves operate on the fully adjusted color result. The LUT already
  // composes Master first and then the per-channel curve.
  rgb = applyToneCurves(clamp(rgb, 0.0, 1.0));

  rgb = applyVignette(
    rgb,
    uv,
    u_size,
    u_vignetteAmount,
    u_vignetteFeather
  );

  rgb = clamp(rgb, 0.0, 1.0);
  fragColor = vec4(rgb * sampled.a, sampled.a);
}
