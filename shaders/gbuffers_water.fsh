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

void main() {
    vec4 base = texture(texture, texcoord) * vertexColor;

    // Everything except explicitly identified water keeps essentially vanilla
    // translucent behaviour. This protects glass and modded translucent blocks.
    if (materialId != 1001 || isFluid != 1) {
        vec3 lit = base.rgb * texture(lightmap, lightcoord).rgb;
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
    float transmission = mix(0.34, 0.13, fresnel);
    vec3 transmitted = mix(base.rgb, waterColor, 0.42);
    vec3 reflected = mix(waterColor, ambientSky, 0.72);

    vec3 color = mix(transmitted, reflected, fresnel * 0.68);

    // Warm glints ride only on the highest ripple crests.
    float glint = smoothstep(0.72, 0.98, w) * pow(fresnel, 0.65) * (1.0 - rainStrength);
    color += vec3(1.00, 0.82, 0.52) * glint * 0.12;

    // Keep substantial transparency so the seabed remains visually important.
    float alpha = clamp(base.a * transmission + fresnel * 0.18, 0.10, 0.52);

    fragColor = vec4(color, alpha);
}
