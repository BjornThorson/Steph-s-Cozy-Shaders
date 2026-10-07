#version 330 compatibility

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform ivec2 eyeBrightnessSmooth;
uniform int worldTime;
uniform int worldDay;
uniform float thunderStrength;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float wetness;
uniform vec3 cameraPosition;
uniform int isEyeInWater;
uniform bool hasSkylight;

const vec3 CAVE_HAZE = vec3(0.105, 0.135, 0.180);
const vec3 WATER_SHALLOW = vec3(0.075, 0.660, 0.690);
const vec3 WATER_DEEP = vec3(0.025, 0.250, 0.420);

float luminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float nightFactor() {
    float t = float(worldTime);
    float dusk = smoothstep(12500.0, 13800.0, t);
    float dawn = 1.0 - smoothstep(22000.0, 23500.0, t);
    return clamp(max(dusk * dawn, step(13800.0, t) * step(t, 22000.0)), 0.0, 1.0);
}

vec3 reconstructViewPosition(float depth) {
    vec3 ndc = vec3(texcoord, depth) * 2.0 - 1.0;
    vec4 view = gbufferProjectionInverse * vec4(ndc, 1.0);
    return view.xyz / view.w;
}

vec3 reconstructWorldDirection() {
    vec2 ndc = texcoord * 2.0 - 1.0;
    vec4 view = gbufferProjectionInverse * vec4(ndc, 1.0, 1.0);
    vec3 viewDir = normalize(view.xyz / view.w);
    return normalize(mat3(gbufferModelViewInverse) * viewDir);
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 applyAurora(vec3 color, vec3 worldDir, float skyPixel) {
    float night = nightFactor() * (1.0 - rainStrength);
    float aboveHorizon = smoothstep(0.02, 0.22, worldDir.y);
    float zenithFade = 1.0 - smoothstep(0.72, 0.98, worldDir.y);

    float longitude = atan(worldDir.z, worldDir.x);
    float latitude = asin(clamp(worldDir.y, -1.0, 1.0));

    float drift = frameTimeCounter * 0.018;
    float broad = valueNoise(vec2(longitude * 1.7 + drift, latitude * 2.2));
    float fine = valueNoise(vec2(longitude * 4.8 - drift * 1.4, latitude * 5.0 + drift));
    float curtainShape = sin(longitude * 7.0 + broad * 5.0 + drift * 2.0);
    curtainShape = pow(max(0.0, 0.55 + 0.45 * curtainShape), 3.0);

    float vertical = smoothstep(0.08, 0.30, worldDir.y) * zenithFade;
    float aurora = curtainShape * mix(0.45, 1.0, fine) * vertical * aboveHorizon;
    aurora *= night * skyPixel * 0.58;

    vec3 green = vec3(0.22, 1.00, 0.58);
    vec3 teal = vec3(0.12, 0.72, 0.86);
    vec3 violet = vec3(0.48, 0.30, 0.82);
    vec3 auroraColor = mix(green, teal, broad);
    auroraColor = mix(auroraColor, violet, smoothstep(0.72, 1.0, fine) * 0.32);

    return color + auroraColor * aurora;
}



float weatherHash(float n) {
    return fract(sin(n * 127.1 + 311.7) * 43758.5453123);
}

float weatherIntensity() {
    if (rainStrength <= 0.001) return 0.0;

    // Divide Minecraft time into broad, irregular-feeling weather cells.
    // Each cell is deterministic for a given world day/time, so intensity does not
    // flicker when frames change and survives shader reloads predictably.
    float absoluteTicks = float(worldDay) * 24000.0 + float(worldTime);
    float cellLength = 3600.0; // roughly three real minutes at normal tick rate
    float cell = floor(absoluteTicks / cellLength);
    float phase = fract(absoluteTicks / cellLength);

    float r0 = weatherHash(cell);
    float r1 = weatherHash(cell + 1.0);

    // Weighted, non-linear weather states:
    // mist/drizzle are common; heavy rain is occasional; torrential rain is rare.
    float state0;
    if      (r0 < 0.20) state0 = 0.12; // mist / barely-there rain
    else if (r0 < 0.45) state0 = 0.25; // drizzle
    else if (r0 < 0.70) state0 = 0.43; // light shower
    else if (r0 < 0.88) state0 = 0.62; // steady rain
    else if (r0 < 0.97) state0 = 0.80; // heavy shower
    else                state0 = 1.00; // torrential

    float state1;
    if      (r1 < 0.20) state1 = 0.12;
    else if (r1 < 0.45) state1 = 0.25;
    else if (r1 < 0.70) state1 = 0.43;
    else if (r1 < 0.88) state1 = 0.62;
    else if (r1 < 0.97) state1 = 0.80;
    else                state1 = 1.00;

    // Hold each pattern for most of its cell, then transition softly near the end.
    // This avoids constant ramping while also avoiding hard visual jumps.
    float transition = smoothstep(0.76, 1.0, phase);
    float intensity = mix(state0, state1, transition);

    // Thunderstorms should normally feel substantial, but still retain variation.
    intensity = max(intensity, thunderStrength * 0.72);

    return intensity * rainStrength;
}

float puddleNoise(vec2 p) {
    float a = valueNoise(p * 0.065);
    float b = valueNoise(p * 0.135 + vec2(17.3, 4.8));
    return a * 0.68 + b * 0.32;
}

vec3 applyRainWetness(vec3 color, float depth) {
    if (!hasSkylight || isEyeInWater != 0 || depth >= 0.999999) {
        return color;
    }

    vec3 viewPos = reconstructViewPosition(depth);
    vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 worldPos = playerPos + cameraPosition;

    // Estimate a screen-visible surface normal from reconstructed world positions.
    // This lets horizontal surfaces collect far more water than walls.
    vec3 dx = dFdx(worldPos);
    vec3 dy = dFdy(worldPos);
    vec3 normal = normalize(cross(dx, dy));
    if (normal.y < 0.0) normal = -normal;

    float upward = smoothstep(0.72, 0.97, normal.y);
    float skyLight = float(eyeBrightnessSmooth.y) / 240.0;
    float exposed = smoothstep(0.45, 0.92, skyLight);

    // Iris wetness lingers after rain according to wetnessHalflife.
    float surfaceWet = wetness * upward * exposed;

    // Large, soft world-space patches imply shallow depressions and uneven drainage.
    float basin = puddleNoise(worldPos.xz);
    float puddlePatch = smoothstep(0.56, 0.76, basin);
    float puddle = surfaceWet * puddlePatch;

    // Fresh rain makes most exposed ground darker before obvious puddles have formed.
    float dynamicRain = weatherIntensity();
    float darkening = surfaceWet * mix(0.07, 0.27, dynamicRain);
    color *= 1.0 - darkening;

    // Puddles softly borrow the sky tone. This is deliberately diffuse rather than
    // mirror-like until we add a dedicated reflection system.
    vec3 reflectedSky = mix(vec3(0.20, 0.25, 0.32), vec3(0.54, 0.66, 0.74), 1.0 - dynamicRain);
    float fresnel = pow(1.0 - clamp(abs(dot(normalize(-viewPos), normal)), 0.0, 1.0), 3.0);
    float sheen = puddle * mix(0.16, 0.38, fresnel);

    color = mix(color, reflectedSky, sheen);

    // Tiny broad highlight keeps wet stone/soil from reading as merely darkened.
    color += vec3(0.018, 0.020, 0.022) * surfaceWet * (0.35 + 0.65 * fresnel);
    return color;
}

vec3 applyCaveAtmosphere(vec3 color, float depth) {
    float skyLight = float(eyeBrightnessSmooth.y) / 240.0;
    float cave = (1.0 - smoothstep(0.08, 0.34, skyLight));
    cave *= float(isEyeInWater == 0);

    if (cave <= 0.001 || depth >= 0.999999) {
        return color;
    }

    // Lift near-black values while retaining contrast and warm local lights.
    float luma = luminance(color);
    float lift = (1.0 - smoothstep(0.02, 0.30, luma)) * cave;
    vec3 lifted = color + vec3(0.050, 0.055, 0.072) * lift;

    vec3 viewPos = reconstructViewPosition(depth);
    float distanceFromCamera = length(viewPos);
    float haze = smoothstep(18.0, 78.0, distanceFromCamera) * cave * 0.34;

    return mix(lifted, CAVE_HAZE, haze);
}

vec3 applyMediterraneanUnderwater(vec3 color, float depth) {
    if (isEyeInWater != 1) {
        return color;
    }

    float distanceFromCamera = 0.0;
    if (depth < 0.999999) {
        distanceFromCamera = length(reconstructViewPosition(depth));
    } else {
        distanceFromCamera = 96.0;
    }

    float depthMood = smoothstep(5.0, 72.0, distanceFromCamera);
    vec3 sea = mix(WATER_SHALLOW, WATER_DEEP, depthMood);

    // Keep the world readable: colour absorption builds gradually with distance.
    float absorption = mix(0.16, 0.62, depthMood);
    color = mix(color, sea, absorption);

    // Mediterranean shallows retain a little sunlit warmth.
    color += vec3(0.030, 0.024, 0.006) * (1.0 - depthMood);
    return color;
}

vec3 storybookGrade(vec3 color) {
    float luma = luminance(color);

    // Honeyed highlights and cool-violet shadows create the warm fantasy contrast.
    vec3 warmHighlights = vec3(1.045, 1.010, 0.945);
    color *= warmHighlights;

    float shadow = 1.0 - smoothstep(0.08, 0.42, luma);
    color += vec3(0.010, 0.008, 0.020) * shadow;

    // Gentle saturation, deliberately restrained so Minecraft textures stay readable.
    float gradedLuma = luminance(color);
    color = mix(vec3(gradedLuma), color, 1.08);

    // Soft highlight rolloff rather than hard clipping.
    color = color / (vec3(1.0) + max(color - 0.82, 0.0) * 0.32);
    return color;
}

out vec4 fragColor;

void main() {
    vec4 scene = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord).r;

    vec3 color = scene.rgb;

    color = applyRainWetness(color, depth);
    color = applyCaveAtmosphere(color, depth);
    color = applyMediterraneanUnderwater(color, depth);

    if (hasSkylight && depth >= 0.999999 && isEyeInWater == 0) {
        vec3 worldDir = reconstructWorldDirection();
        color = applyAurora(color, worldDir, 1.0);
    }

    color = storybookGrade(color);
    fragColor = vec4(clamp(color, 0.0, 1.0), scene.a);
}
