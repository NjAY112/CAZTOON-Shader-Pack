#version 120
varying vec4 glcolor;
void main() {
    /* DRAWBUFFERS:01 */
    gl_FragData[0] = glcolor;
    gl_FragData[1] = vec4(0.5, 1.0, 0.5, 0.0);
}
