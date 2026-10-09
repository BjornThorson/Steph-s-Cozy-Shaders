#version 330 compatibility

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform ivec2 eyeBrightnessSmooth;
uniform int worldTime;
uniform int worldDay;
uniform int moonPhase;
uniform vec3 moonPosition;
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


float moonFullness() {
    // Minecraft phases: 0 full, 1 waning gibbous, 2 third quarter,
    // 3 waning crescent, 4 new, then waxing back toward full.
    float phase = float(moonPhase);
    float distanceFromFull = min(phase, 8.0 - phase);
    return 0.5 + 0.5 * cos(distanceFromFull * 3.14159265 / 4.0);
}

vec3 applyWitchMoonAtmosphere(vec3 color, vec3 worldDir, float skyPixel) {
    float night = nightFactor() * (1.0 - rainStrength) * skyPixel;
    if (night <= 0.001) return color;

    // moonPosition is view-space; rotate it into the same world-relative frame
    // used by our reconstructed sky ray.
    vec3 moonDir = normalize(mat3(gbufferModelViewInverse) * normalize(moonPosition));
    float alignment = max(dot(worldDir, moonDir), 0.0);

    float fullness = moonFullness();

    // A broad silver-lavender halo around the vanilla moon direction.
    float outerHalo = pow(alignment, 42.0);
    float innerHalo = pow(alignment, 180.0);
    vec3 silver = vec3(0.74, 0.78, 0.94);
    vec3 lavender = vec3(0.57, 0.47, 0.82);
    vec3 ivory = vec3(1.00, 0.94, 0.78);

    vec3 halo = mix(lavender, silver, 0.62);
    halo = mix(halo, ivory, innerHalo * (0.35 + 0.45 * fullness));

    float strength = night * (0.22 + 0.58 * fullness);
    color += halo * outerHalo * strength * 0.36;
    color += ivory * innerHalo * strength * 0.28;

    // Full moons softly silver the whole night sky; new moons retreat into indigo.
    vec3 moonlitSky = vec3(0.055, 0.065, 0.115);
    vec3 newMoonSky = vec3(0.020, 0.018, 0.052);
    vec3 phaseTint = mix(newMoonSky, moonlitSky, fullness);
    color += phaseTint * night * (0.18 + 0.24 * fullness);

    return color;
}

vec3 applyAurora(vec3 color, vec3 worldDir, float skyPixel) {
    float night = nightFactor() * (1.0 - rainStrength);
    // Skip expensive trigonometry and procedural noise outside visible night sky.
    if (skyPixel <= 0.001 || night <= 0.001 || worldDir.y <= 0.02 || worldDir.y >= 0.98) return color;
    float aboveHorizon = smoothstep(0.02, 0.22, worldDir.y);
    float zenithFade = 1.0 - smoothstep(0.72, 0.98, worldDir.y);

    // A continuous unit circle replaces the wrapped atan longitude.
    // Its seventh harmonic makes seven wispy curtain bands around the sky.
    vec2 circle = normalize(worldDir.xz);
    vec2 harmonic = circle;
    for (int i = 1; i < 7; ++i) {
        harmonic = vec2(harmonic.x * circle.x - harmonic.y * circle.y,
                        harmonic.x * circle.y + harmonic.y * circle.x);
    }

    float drift = frameTimeCounter * 0.018;
    // Use continuous direction components for noise to eliminate the angular seam.
    float broad = valueNoise(worldDir.xz * 3.5 + vec2(drift, worldDir.y * 2.0));
    float fine = valueNoise(worldDir.xz * 10.0 + vec2(-drift * 1.4, worldDir.y * 3.0 + drift));
    float curtainPhase = broad * 5.0 + drift * 2.0;
    float curtainShape = harmonic.y * cos(curtainPhase) + harmonic.x * sin(curtainPhase);
    curtainShape = pow(max(0.0, 0.55 + 0.45 * curtainShape), 3.0);

    float vertical = smoothstep(0.08, 0.30, worldDir.y) * zenithFade;
    float aurora = curtainShape * mix(0.45, 1.0, fine) * vertical * aboveHorizon;
    aurora *= night * skyPixel * mix(0.72, 0.48, moonFullness());

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

    // On dry frames there is no wetness to shade; avoid reconstruction,
    // derivatives and multi-octave noise on every opaque pixel.
    if (wetness <= 0.001) return color;

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
    if (surfaceWet <= 0.001) return color;

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
    vec3 warmHighlights = vec3(1.095, 1.025, 0.900);
    color *= warmHighlights;

    float shadow = 1.0 - smoothstep(0.08, 0.42, luma);
    color += vec3(0.015, 0.009, 0.019) * shadow;

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
        color = applyWitchMoonAtmosphere(color, worldDir, 1.0);
        color = applyAurora(color, worldDir, 1.0);
    }

    // Darken natural nighttime light while keeping moon/aurora visible.
    // Avoid dimming caves or underwater views based solely on clock time.
    if (hasSkylight && isEyeInWater == 0) {
        float night = nightFactor();
        float skyExposure = smoothstep(0.06, 0.42, float(eyeBrightnessSmooth.y) / 240.0);
        color *= 1.0 - 0.24 * night * skyExposure;
    }
    color = storybookGrade(color);
    fragColor = vec4(clamp(color, 0.0, 1.0), scene.a);
}
