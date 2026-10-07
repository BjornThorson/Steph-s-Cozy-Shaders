#version 330 compatibility

in vec2 texcoord;
in vec4 vertexColor;

uniform sampler2D texture;
uniform float rainStrength;
uniform float thunderStrength;
uniform int worldTime;
uniform int worldDay;

float weatherHash(float n) {
    return fract(sin(n * 127.1 + 311.7) * 43758.5453123);
}

float chooseIntensity(float r) {
    if      (r < 0.20) return 0.12;
    else if (r < 0.45) return 0.25;
    else if (r < 0.70) return 0.43;
    else if (r < 0.88) return 0.62;
    else if (r < 0.97) return 0.80;
    return 1.00;
}

float weatherIntensity() {
    float absoluteTicks = float(worldDay) * 24000.0 + float(worldTime);
    float cellLength = 3600.0;
    float cell = floor(absoluteTicks / cellLength);
    float phase = fract(absoluteTicks / cellLength);

    float current = chooseIntensity(weatherHash(cell));
    float next = chooseIntensity(weatherHash(cell + 1.0));
    float transition = smoothstep(0.76, 1.0, phase);

    float intensity = mix(current, next, transition);
    intensity = max(intensity, thunderStrength * 0.72);
    return intensity * rainStrength;
}

out vec4 fragColor;

void main() {
    vec4 weather = texture(texture, texcoord) * vertexColor;
    float intensity = weatherIntensity();

    // Preserve Minecraft's rain/snow geometry but vary how strongly it reads.
    // Mist is sparse/soft; torrential weather approaches full vanilla density.
    weather.a *= mix(0.18, 1.0, intensity);
    weather.rgb *= mix(1.08, 0.78, intensity);

    fragColor = weather;
}
