#version 460 core

// SoloTilt / iPhone Duo Single-Hinge 3D Fold Fragment Shader.
//
// Replicates the authentic interactive perspective illusion from solotilt.com:
// - Physical display acts as a viewing portal into a 3D perspective fold plane.
// - The hinge line anchors rigidly to the screen edge (left, right, top, or bottom).
// - As the panel rotates into 3D space, the opposite edge recedes with realistic
//   depth foreshortening (cosine * perspective divider).
// - Optical depth-of-field defocus blur increases smoothly with distance from hinge.
// - Dynamic specular sheen band sweeps across the glass as angle changes.
// - Clean edge handling: zero black lines, zero texture bleeding, and customizable surround color.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;            // engine: float 0, 1
uniform sampler2D uTexture;    // engine: sampler 0
uniform float uTiltDegrees;    // float 2
uniform float uLiftDirX;       // float 3
uniform float uLiftDirY;       // float 4
uniform float uEyeDistancePx;  // float 5
uniform float uBlurSpread;     // float 6
uniform float uDarkening;      // float 7
uniform float uSurroundR;      // float 8
uniform float uSurroundG;      // float 9
uniform float uSurroundB;      // float 10
uniform float uHazeR;          // float 11
uniform float uHazeG;          // float 12
uniform float uHazeB;          // float 13
uniform float uBaseBlurPx;     // float 14
uniform float uEdgeStretch;    // float 15
uniform float uCausticIntensity;    // float 16
uniform float uShadowIntensity;     // float 17
uniform float uShadowSoftness;      // float 18

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

  // Determine fold orientation (horizontal card/screen flip vs vertical calendar flip)
  bool isHorizontal = abs(uLiftDirX) >= abs(uLiftDirY);

  // Hinge position:
  // For horizontal: uLiftDirX > 0 lifts towards right -> hinged on left (0.0).
  //                 uLiftDirX < 0 lifts towards left  -> hinged on right (1.0).
  // For vertical:   uLiftDirY > 0 lifts towards bottom -> hinged on top (0.0).
  //                 uLiftDirY < 0 lifts towards top    -> hinged on bottom (1.0).
  float hinge = isHorizontal ? (uLiftDirX > 0.0 ? 0.0 : 1.0) : (uLiftDirY > 0.0 ? 0.0 : 1.0);
  float fromHinge = isHorizontal ? abs(uv.x - hinge) : abs(uv.y - hinge);

  float cosine = max(0.001, cos(tilt));
  float sine = sin(tilt);

  // Observer distance aligned with hinge center (authentic SoloTilt / iPhone Duo 3D formulation)
  float eyeDistance = 2.4 * max(aspect, 1.0);
  float depth = isHorizontal ? (fromHinge * aspect * sine) : (fromHinge * sine);
  float perspective = eyeDistance / max(0.001, eyeDistance - depth);

  vec2 imageUv;
  if (isHorizontal) {
    imageUv.x = hinge + (uv.x - hinge) * cosine * perspective;
    imageUv.y = 0.5 + (uv.y - 0.5) * perspective;
  } else {
    imageUv.x = 0.5 + (uv.x - 0.5) * perspective;
    imageUv.y = hinge + (uv.y - hinge) * cosine * perspective;
  }

  // Defocus optical depth-of-field blur:
  // Increases non-linearly with physical tilt angle and distance from stationary hinge.
  float blurAngle = pow(smoothstep(0.0, radians(90.0), tilt), 0.50);
  float blurSpread = pow(smoothstep(0.0, 0.70, fromHinge), 1.45);
  float defocus = blurAngle * mix(0.18, 1.0, blurSpread);
  float radius = uBlurSpread * 320.0 * defocus + uBaseBlurPx;

  // Subpixel anti-aliasing for the perspective trapezoid boundaries
  float perpSpan = isHorizontal ? uSize.y : uSize.x;
  float marginSoftness = 0.002 + 2.0 * radius / perpSpan;
  float perpDist = isHorizontal ? abs(imageUv.y - 0.5) : abs(imageUv.x - 0.5);
  float mask = 1.0 - smoothstep(0.5 - marginSoftness, 0.5 + marginSoftness, perpDist);

  // When edge stretch / clean bleed is requested, eliminate cut-off lines
  if (uEdgeStretch > 0.5) {
    mask = 1.0;
  }

  // If outside the perspective trapezoid, immediately show the clean surround color
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

  // Glass light transmission and subtle absorption away from hinge
  float outer = hinge > 0.5 ? 0.0 : 1.0;
  float glass = sine * pow(fromHinge, 1.6);
  color *= (1.0 - mix(0.28, 0.06, outer) * glass);

  // Dynamic specular reflection band (authentic SoloTilt glass sheen)
  float reflection = exp(-pow((fromHinge - 0.70) / 0.30, 2.0)) * sine;
  float causticCoeff = uCausticIntensity > 0.0 ? uCausticIntensity * 0.15 : 0.05;
  color += vec3(0.84, 0.88, 0.92) * reflection * causticCoeff;

  // Linear dark falloff towards the receding blurred edge
  float blackFade = clamp((fromHinge - 0.26) / 0.74, 0.0, 1.0);
  color *= (1.0 - 0.65 * blurAngle * blackFade);

  // Soft contact drop shadow near hinge / gap if configured
  if (uShadowIntensity > 0.0) {
    float shadow = uShadowIntensity * smoothstep(0.0, uShadowSoftness + 0.01, fromHinge * sine);
    color *= (1.0 - shadow * 0.35);
  }

  // Smooth anti-aliased composition with surround background
  fragColor = vec4(mix(surroundColor(), color, mask), 1.0);
}
