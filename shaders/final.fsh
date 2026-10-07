#version 120

uniform sampler2D colortex0;
varying vec2 texcoord;

void main() {
    vec4 scene = texture2D(colortex0, texcoord);
    scene.rgb *= vec3(1.08, 1.00, 0.88);
    gl_FragColor = scene;
}
