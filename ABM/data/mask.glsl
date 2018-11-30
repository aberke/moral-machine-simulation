#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_COLOR_SHADER

uniform float width;
uniform float height;
uniform sampler2D sampler;

void main() {
  vec2 n = vec2(gl_FragCoord.x / width, gl_FragCoord.y / height);
  gl_FragColor = texture2D(sampler, n).rgba;
}