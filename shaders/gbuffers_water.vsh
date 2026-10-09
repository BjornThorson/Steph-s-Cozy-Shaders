#version 330 compatibility

out vec2 texcoord;
out vec2 lightcoord;
out vec4 vertexColor;
out vec3 viewPosition;
out vec3 worldPosition;
out vec3 viewNormal;
flat out int materialId;
flat out int isFluid;

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

// Iris/Oculus supplies material ID and fluid flag as a two-component attribute.
in vec2 mc_Entity;

void main() {
    vec4 viewVertex = gl_ModelViewMatrix * gl_Vertex;

    materialId = int(mc_Entity.x + 0.5);
    isFluid = int(mc_Entity.y + 0.5);

    // Fluids get vertical-only displacement. Water is lively and light; lava
    // moves more slowly and heavily. Avoid horizontal movement so block edges
    // do not open visible cracks.
    if ((materialId == 1001 || materialId == 1002) && isFluid == 1) {
        vec3 playerPos = (gbufferModelViewInverse * viewVertex).xyz;
        vec3 worldPos = playerPos + cameraPosition;

        if (materialId == 1001) {
            float waveA = sin(worldPos.x * 0.38 + worldPos.z * 0.24 + frameTimeCounter * 1.10);
            float waveB = sin(worldPos.x * -0.21 + worldPos.z * 0.44 - frameTimeCounter * 0.76);
            // Displace in world-up, then transform back to view space.
            vec3 offsetView = mat3(gl_ModelViewMatrix) * vec3(0.0, (waveA + waveB) * 0.018, 0.0);
            viewVertex.xyz += offsetView;
        } else {
            float rollA = sin(worldPos.x * 0.22 + worldPos.z * 0.17 + frameTimeCounter * 0.28);
            float rollB = sin(worldPos.x * -0.14 + worldPos.z * 0.29 - frameTimeCounter * 0.19);
            viewVertex.xyz += mat3(gl_ModelViewMatrix) * vec3(0.0, (rollA + rollB) * 0.006, 0.0);
        }
    }

    gl_Position = gl_ProjectionMatrix * viewVertex;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    viewPosition = viewVertex.xyz;
    worldPosition = (gbufferModelViewInverse * viewVertex).xyz + cameraPosition;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
}
