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

in vec4 mc_Entity;

void main() {
    vec4 viewVertex = gl_ModelViewMatrix * gl_Vertex;

    materialId = int(mc_Entity.x + 0.5);
    isFluid = int(mc_Entity.y + 0.5);

    // Water gets a tiny vertical displacement only. Horizontal displacement at
    // chunk/block edges can open visible cracks, so the first prototype stays conservative.
    if (materialId == 1001 && isFluid == 1) {
        vec3 playerPos = (gbufferModelViewInverse * viewVertex).xyz;
        vec3 worldPos = playerPos + cameraPosition;

        float waveA = sin(worldPos.x * 0.38 + worldPos.z * 0.24 + frameTimeCounter * 1.10);
        float waveB = sin(worldPos.x * -0.21 + worldPos.z * 0.44 - frameTimeCounter * 0.76);
        float wave = (waveA + waveB) * 0.012;

        viewVertex.y += wave;
    }

    gl_Position = gl_ProjectionMatrix * viewVertex;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    viewPosition = viewVertex.xyz;
    worldPosition = (gbufferModelViewInverse * viewVertex).xyz + cameraPosition;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
}
