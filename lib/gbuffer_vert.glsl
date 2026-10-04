varying vec2 texcoord;
varying vec4 color;
varying vec2 lmcoord;
varying vec3 normalView;
varying vec3 worldPos;
varying float faceShade;
uniform float frameTimeCounter;
attribute vec4 mc_Entity;
#ifdef SHADOWS
varying vec4 shadowPosClip;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
#endif
#ifdef WAVE_PROGRAM
varying float blockId;
#endif

void main() {
    vec4 position = gl_Vertex;
    
#ifdef WAVE_PROGRAM
    blockId = mc_Entity.x;
    
    // Leaves and small grass: quick bounce
    if (mc_Entity.x == 18.0 || mc_Entity.x == 31.0) {
        float speed = 3.8;
        float waveX = sin(frameTimeCounter * speed + position.x * 0.7 + position.y * 0.5) * 0.06;
        float waveZ = cos(frameTimeCounter * speed * 0.8 + position.z * 0.7) * 0.05;
        position.x += waveX;
        position.z += waveZ;
    }
    
    // Tall plants: wider sway
    if (mc_Entity.x > 10000.5 && mc_Entity.x < 10003.5) {
        float speed = 4.2;
        float sway = sin(frameTimeCounter * speed + position.x * 0.9 + position.z * 0.5) * 0.08;
        position.x += sway;
    }
#endif

    gl_Position = gl_ModelViewProjectionMatrix * position;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
    color = gl_Color;
    normalView = normalize(gl_NormalMatrix * gl_Normal);
    worldPos = gl_Vertex.xyz;
    faceShade = dot(gl_Normal, normalize(gl_LightSource[0].position.xyz));
    
#ifdef SHADOWS
    shadowPosClip = shadowProjection * (shadowModelView * gl_ModelViewMatrix * position);
#endif
}
