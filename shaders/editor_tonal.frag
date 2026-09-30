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
