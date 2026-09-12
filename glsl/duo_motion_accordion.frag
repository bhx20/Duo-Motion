#version 460 core

// SoloTilt Accordion 3D Perspective Fragment Shader.
//
// Multi-segment alternating paper fold with 3D perspective foreshortening.

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
uniform float uFoldCount;           // float 16  (number of fold segments, 2..16)
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
  vec2 uv = px / uSize;
  if (uEdgeStretch > 0.5) {
    uv = clamp(uv, vec2(0.0), vec2(1.0));
  } else if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
    return vec4(surroundColor(), 1.0);
  }
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
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
  float foldCount = max(uFoldCount, 2.0);
  float panelWidth = 1.0 / foldCount;

  float panelIndex = clamp(floor(uv.x / panelWidth), 0.0, foldCount - 1.0);
  float localUv = (uv.x - panelIndex * panelWidth) / panelWidth;
  bool isEven = mod(panelIndex, 2.0) < 0.5;

  float fromHinge = isEven ? localUv : (1.0 - localUv);
  float panelTilt = (tilt / sqrt(foldCount)) * 0.7;

  float cosine = max(0.001, cos(panelTilt));
  float sine = sin(panelTilt);

  float eyeDistance = 1.5 * max(aspect, 1.0);
  float depthFactor = min(1.0, aspect * 1.6);
  float depth = fromHinge * panelWidth * depthFactor * sine;
  float perspective = eyeDistance / max(0.001, eyeDistance - depth);

  vec2 imageUv;
  float hingeX = (panelIndex + (isEven ? 0.0 : 1.0)) * panelWidth;
  imageUv.x = hingeX + (uv.x - hingeX) * cosine * perspective;
  imageUv.y = 0.5 + (uv.y - 0.5) * perspective;

  float blurAngle = pow(smoothstep(0.0, radians(90.0), panelTilt), 0.5);
  float blurSpread = pow(smoothstep(0.0, 0.7, fromHinge), 1.45);
  float defocus = blurAngle * mix(0.18, 1.0, blurSpread);
  float radius = uBlurSpread * 80.0 * defocus + uBaseBlurPx;

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

  float atten = max(1.0 - uDarkening * radius, 0.0);
  color = mix(hazeColor(), color, atten);

  // Crease shadow at fold seams
  float seamDist = min(localUv, 1.0 - localUv);
  float crease = smoothstep(0.08, 0.0, seamDist) * 0.15;
  color *= (1.0 - crease);

  // Specular sheen
  float reflection = exp(-pow((fromHinge - 0.70) / 0.30, 2.0)) * sine;
  color += vec3(0.92, 0.94, 0.98) * reflection * (uCausticIntensity > 0.0 ? uCausticIntensity * 0.15 : 0.05);

  if (uShadowIntensity > 0.0) {
    float shadow = uShadowIntensity * smoothstep(0.0, uShadowSoftness + 0.01, fromHinge * sine);
    color *= (1.0 - shadow);
  }

  fragColor = vec4(mix(surroundColor(), color, mask), 1.0);
}
