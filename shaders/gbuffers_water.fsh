#version 330 compatibility

in vec2 texcoord;
in vec2 lightcoord;
in vec4 vertexColor;
in vec3 viewPosition;
in vec3 worldPosition;
in vec3 viewNormal;
flat in int materialId;
flat in int isFluid;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform vec3 skyColor;
uniform vec3 fogColor;

layout(location = 0) out vec4 fragColor;

float wavePattern(vec2 p) {
    float a = sin(p.x * 0.52 + p.y * 0.31 + frameTimeCounter * 0.90);
    float b = sin(p.x * -0.29 + p.y * 0.61 - frameTimeCounter * 0.64);
    float c = sin((p.x + p.y) * 0.19 + frameTimeCounter * 0.37);
    return (a + b * 0.65 + c * 0.35) / 2.0;
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float lavaConvection(vec2 p) {
    float t = frameTimeCounter;
    vec2 driftA = vec2(t * 0.045, -t * 0.025);
    vec2 driftB = vec2(-t * 0.022, t * 0.038);

    float broad = smoothNoise(p * 0.34 + driftA);
    float detail = smoothNoise(p * 0.78 + driftB);
    float folds = 0.5 + 0.5 * sin(p.x * 0.31 + p.y * 0.27 + t * 0.22 + broad * 5.0);

    return clamp(broad * 0.52 + detail * 0.25 + folds * 0.23, 0.0, 1.0);
}

vec4 renderLava(vec4 base) {
    vec2 p = worldPosition.xz;
    float convection = lavaConvection(p);

    // Irregular cooling islands sit above a hotter moving body. A second noise
    // octave breaks the boundaries so the crust does not read as simple stripes.
    float breakup = smoothNoise(p * 1.35 + vec2(frameTimeCounter * 0.018, 0.0));
    float crustField = convection * 0.72 + breakup * 0.28;
    float crust = smoothstep(0.57, 0.76, crustField);
    float fissure = 1.0 - smoothstep(0.42, 0.61, crustField);

    vec3 deepEmber = vec3(0.44, 0.055, 0.012);
    vec3 moltenOrange = vec3(1.00, 0.245, 0.018);
    vec3 moltenGold = vec3(1.00, 0.610, 0.075);
    vec3 whiteHot = vec3(1.00, 0.875, 0.430);
    vec3 coolingCrust = vec3(0.155, 0.050, 0.022);

    vec3 molten = mix(deepEmber, moltenOrange, smoothstep(0.18, 0.62, convection));
    molten = mix(molten, moltenGold, fissure * 0.82);
    molten = mix(molten, whiteHot, pow(fissure, 5.0) * 0.42);

    vec3 color = mix(molten, coolingCrust, crust * 0.82);

    // Preserve a little of Minecraft's lava texture so the material still
    // belongs to the world rather than becoming a procedural replacement.
    color = mix(color, color * (0.72 + base.rgb * 0.55), 0.20);

    // Restrained emission: hot fissures remain luminous even in dark caves.
    color += moltenGold * fissure * 0.16;
    color += whiteHot * pow(fissure, 6.0) * 0.10;

    // A tiny optical wobble in brightness suggests rising heat at the surface.
    // True screen-space refraction belongs in a later composite pass.
    float heatPulse = 0.5 + 0.5 * sin(
        worldPosition.x * 0.47 + worldPosition.z * 0.39 + frameTimeCounter * 1.35
    );
    color *= 0.97 + heatPulse * 0.05;

    return vec4(color, max(base.a, 0.94));
}

void main() {
    vec4 base = texture2D(texture, texcoord) * vertexColor;

    if (materialId == 1002 && isFluid == 1) {
        fragColor = renderLava(base);
        return;
    }

    // Everything except explicitly identified water/lava keeps essentially
    // vanilla translucent behaviour. This protects glass and modded materials.
    if (materialId != 1001 || isFluid != 1) {
        vec3 lit = base.rgb * texture2D(lightmap, lightcoord).rgb;
        fragColor = vec4(lit, base.a);
        return;
    }

    vec3 N = normalize(viewNormal);
    vec3 V = normalize(-viewPosition);

    // Calm overlapping ripples perturb the optical normal rather than violently
    // moving the geometry.
    float w = wavePattern(worldPosition.xz);
    float wx = wavePattern(worldPosition.xz + vec2(0.22, 0.0)) - w;
    float wz = wavePattern(worldPosition.xz + vec2(0.0, 0.22)) - w;
    vec3 rippleNormal = normalize(N + vec3(-wx * 0.72, 0.0, -wz * 0.72));

    float facing = clamp(abs(dot(rippleNormal, V)), 0.0, 1.0);
    float fresnel = pow(1.0 - facing, 4.0);

    // Vertex alpha and view angle provide a conservative first approximation of
    // shallow/clear versus visually deeper water until depth refraction is added.
    float depthMood = clamp((1.0 - base.a) * 0.65 + fresnel * 0.20, 0.0, 1.0);

    vec3 shallowTurquoise = vec3(0.075, 0.690, 0.700);
    vec3 sunlitAqua = vec3(0.115, 0.760, 0.720);
    vec3 mediterraneanBlue = vec3(0.025, 0.300, 0.510);

    vec3 waterColor = mix(shallowTurquoise, mediterraneanBlue, depthMood);
    waterColor = mix(waterColor, sunlitAqua, max(0.0, w) * 0.10);

    vec3 ambientSky = mix(fogColor, skyColor, 0.68);
    ambientSky = mix(ambientSky, vec3(0.34, 0.40, 0.47), rainStrength * 0.58);

    // Looking downward: clear and inviting. Grazing angles: increasingly reflective.
    float transmission = mix(0.72, 0.45, fresnel);
    vec3 transmitted = mix(base.rgb, waterColor, 0.66);
    vec3 reflected = mix(waterColor, ambientSky, 0.72);

    vec3 color = mix(transmitted, reflected, fresnel * 0.68);

    // Warm glints ride only on the highest ripple crests.
    float glint = smoothstep(0.72, 0.98, w) * pow(fresnel, 0.65) * (1.0 - rainStrength);
    color += vec3(1.00, 0.82, 0.52) * glint * 0.12;

    // Keep substantial transparency so the seabed remains visually important.
    float alpha = clamp(base.a * transmission + fresnel * 0.25, 0.30, 0.78);

    fragColor = vec4(color, alpha);
}
