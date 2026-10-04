#version 120
varying vec4 starColor;
void main() {
    gl_Position = ftransform();
    starColor = gl_Color;
}
