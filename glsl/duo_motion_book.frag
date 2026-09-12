#version 460 core

// SoloTilt Book-Fold / Foldable Phone 3D Perspective Fragment Shader.
//
// Replicates the authentic foldable phone / dual-panel experience from solotilt.com & user photo:
// - One screen stays completely flat at 0° (crystal clear, perfectly sharp).
// - The adjacent panel lifts/folds in 3D perspective with heavy frosted-glass blur & sheen.
// - Optical depth-of-field blur with Poisson golden-angle disc sampling.
// - Milky frosted-glass physical haze diffusion and specular rim highlights.
// - Symmetrical 3D perspective fold reveals the dark surround backdrop on top and bottom.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform sampler2D uTexture;
uniform float uTiltDegrees;         // float 2
uniform float uLiftDirX;            // float 3
uniform float uLiftDirY;            // float 4
uniform float uEyeDistancePx;       // float 5
uniform float uBlurSpread;          // float 6
uniform float uDarkening;           // float 7
uniform float uSurroundR;           // float 8
uniform float uSurroundG;           // float 9
uniform float uSurroundB;           // float 10
uniform float uHazeR;               // float 11
uniform float uHazeG;               // float 12
uniform float uHazeB;               // float 13
uniform float uBaseBlurPx;          // float 14
uniform float uEdgeStretch;         // float 15
uniform float uHingePosition;       // float 16  (0..1, fraction along lift axis)
uniform float uCausticIntensity;    // float 17
uniform float uShadowIntensity;     // float 18
uniform float uShadowSoftness;      // float 19

out vec4 fragColor;

vec3 surroundColor() { return vec3(uSurroundR, uSurroundG, uSurroundB); }
vec3 hazeColor() { return vec3(uHazeR, uHazeG, uHazeB); }

const float GOLDEN_ANGLE = 2.39996322972865332;
const float TWO_PI = 6.28318530717958648;
const float MAX_TAPS = 32.0;
const float MAX_TILT = 88.5;

vec4 sampleContent(vec2 px) {
  vec2 uv = clamp(px / uSize, vec2(0.0), vec2(1.0));
  return texture(uTexture, uv);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;

  if (uSize.x <= 1.0 || uSize.y <= 1.0) {
    fragColor = sampleContent(fragCoord);
    return;
  }

  float tilt = radians(clamp(uTiltDegrees, 0.0, MAX_TILT));
  if (tilt < 1e-5) {
    fragColor = sampleContent(fragCoord);
    return;
  }

  vec2 uv = fragCoord / uSize;
  float aspect = uSize.x / uSize.y;
  float hingePos = clamp(uHingePosition, 0.05, 0.95);

  bool isLeftPanel = uv.x < hingePos;

  // Determine which panel lifts:
  // When uLiftDirX >= 0.0: left panel folds up, right panel stays flat at 0°.
  // When uLiftDirX < 0.0: right panel folds up, left panel stays flat at 0°.
  bool isLifting = uLiftDirX >= 0.0 ? isLeftPanel : !isLeftPanel;

  // 1. STATIONARY 0° PANEL (stays flat, unblurred, crystal clear)
  if (!isLifting) {
    // Subtle ambient contact shadow cast near the spine hinge by the lifted leaf
    float distToHinge = abs(uv.x - hingePos);
    float hingeShadow = smoothstep(0.12, 0.0, distToHinge) * 0.22 * sin(tilt);
    vec3 baseColor = sampleContent(fragCoord).rgb * (1.0 - hingeShadow);
    fragColor = vec4(baseColor, 1.0);
    return;
  }

  // 2. LIFTING 3D FROSTED-GLASS PANEL
  float fromHinge = isLeftPanel ? (hingePos - uv.x) / hingePos : (uv.x - hingePos) / (1.0 - hingePos);

  float panelTilt = tilt;
  float cosine = max(0.001, cos(panelTilt));
  float sine = sin(panelTilt);

  float eyeDistance = 1.5 * max(aspect, 1.0);
  float depthFactor = min(1.0, aspect * 1.6);
  float depth = fromHinge * depthFactor * sine;
  float perspective = eyeDistance / max(0.001, eyeDistance - depth);

  vec2 imageUv;
  imageUv.x = hingePos + (uv.x - hingePos) * cosine * perspective;
  imageUv.y = 0.5 + (uv.y - 0.5) * perspective;

  // Optical depth-of-field defocus blur (heavy frosted glass look from user photo)
  float blurAngle = pow(smoothstep(0.0, radians(90.0), panelTilt), 0.5);
  float blurSpread = pow(smoothstep(0.0, 0.75, fromHinge), 1.25);
  float defocus = blurAngle * mix(0.20, 1.0, blurSpread);
  float radius = uBlurSpread * 320.0 * defocus + uBaseBlurPx;

  // Symmetrical perspective trapezoid mask
  float marginSoftness = 0.003 + 2.0 * radius / uSize.y;
  float mask = 1.0 - smoothstep(0.5 - marginSoftness, 0.5 + marginSoftness, abs(imageUv.y - 0.5));

  if (uEdgeStretch > 0.5) {
    mask = 1.0;
  }

  if (mask <= 0.0) {
    fragColor = vec4(surroundColor(), 1.0);
    return;
  }

  vec2 hit = clamp(imageUv, vec2(0.0), vec2(1.0)) * uSize;
  vec3 color;

  if (radius < 0.5) {
    color = sampleContent(hit).rgb;
  } else {
    float tapsF = clamp(radius * 1.8, 6.0, MAX_TAPS);
    float rotation =
        fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453) * TWO_PI;

    vec3 sum = vec3(0.0);
    float weightSum = 0.0;
    for (int i = 0; i < 32; i++) {
      float fi = float(i);
      float weight = 1.0 - step(tapsF, fi);
      float r = radius * sqrt((fi + 0.5) / tapsF);
      float a = fi * GOLDEN_ANGLE + rotation;
      sum += sampleContent(hit + r * vec2(cos(a), sin(a))).rgb * weight;
      weightSum += weight;
    }
    color = sum / weightSum;
  }

  // Light attenuation
  float atten = max(1.0 - uDarkening * radius, 0.0);
  color = mix(hazeColor(), color, atten);

  // Milky frosted-glass physical haze diffusion (authentic look from user photo)
  float frostMix = clamp(defocus * 0.28 + (radius / 55.0) * 0.16, 0.0, 0.42);
  vec3 frostColor = mix(hazeColor(), vec3(0.94, 0.96, 1.0), 0.6);
  color = mix(color, frostColor, frostMix);

  // Specular sheen sweep across the glass surface
  float reflection = exp(-pow((fromHinge - 0.65) / 0.35, 2.0)) * sine;
  float causticCoeff = uCausticIntensity > 0.0 ? uCausticIntensity * 0.20 : 0.08;
  color += vec3(0.96, 0.98, 1.0) * reflection * causticCoeff;

  // Specular outer rim highlight on the edge of the glass
  float rim = smoothstep(0.90, 0.99, fromHinge) * sine;
  color += vec3(0.98, 1.0, 1.0) * rim * 0.25;

  // Soft contact drop shadow near hinge
  if (uShadowIntensity > 0.0) {
    float shadow = uShadowIntensity * smoothstep(0.0, uShadowSoftness + 0.01, fromHinge * sine);
    color *= (1.0 - shadow * 0.4);
  }

  // Symmetrical anti-aliased blend with surround color (black)
  fragColor = vec4(mix(surroundColor(), color, mask), 1.0);
}
