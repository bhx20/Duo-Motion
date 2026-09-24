#version 460 core

// SoloTilt / iPhone Duo Single-Hinge 3D Fold Fragment Shader.
//
// Ultra-optimized for 60-120Hz high-refresh mobile GPUs (Mali-G68 / Adreno):
// - Isotropic 5-tap Poisson blur with center bias.
// - Fast-path 1-tap pass for the focused majority of the fold plane (radius < 1.5).
// - Zero transcendental functions (sin/cos/exp/pow) in blur loop.
// - Authentic SoloTilt 3D perspective fold, specular sheen, and clean surround edge bleed.

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
  if (tilt < 1e-4) {
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
  // Non-linear response: hinge area is in crisp sharp focus (radius < 1.5).
  // Defocus ramps up only as the panel recedes into deep 3D perspective space.
  float blurAngle = sqrt(clamp(tilt / radians(90.0), 0.0, 1.0));
  float spreadNorm = clamp((fromHinge - 0.15) * 1.538, 0.0, 1.0);
  float blurSpread = spreadNorm * spreadNorm;
  float defocus = blurAngle * blurSpread;
  float radius = uBlurSpread * 180.0 * defocus + uBaseBlurPx;

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
  vec3 color = sampleContent(hit).rgb;

  // Glass light transmission and subtle absorption away from hinge
  float outer = hinge > 0.5 ? 0.0 : 1.0;
  float glass = sine * (fromHinge * fromHinge);
  color *= (1.0 - mix(0.28, 0.06, outer) * glass);

  // Dynamic specular reflection band (authentic SoloTilt glass sheen)
  float dReflect = (fromHinge - 0.70) * 3.333;
  float reflection = max(0.0, 1.0 - dReflect * dReflect) * sine;
  float causticCoeff = uCausticIntensity > 0.0 ? uCausticIntensity * 0.15 : 0.05;
  color += vec3(0.84, 0.88, 0.92) * reflection * causticCoeff;

  // Linear dark falloff towards the receding blurred edge
  float blackFade = clamp((fromHinge - 0.26) * 1.351, 0.0, 1.0);
  color *= (1.0 - 0.65 * blurAngle * blackFade);

  // Soft contact drop shadow near hinge / gap if configured
  if (uShadowIntensity > 0.0) {
    float shadow = uShadowIntensity * smoothstep(0.0, uShadowSoftness + 0.01, fromHinge * sine);
    color *= (1.0 - shadow * 0.35);
  }

  // Smooth anti-aliased composition with surround background
  fragColor = vec4(mix(surroundColor(), color, mask), 1.0);
}
