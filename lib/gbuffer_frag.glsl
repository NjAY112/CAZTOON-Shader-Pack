#include "/lib/settings.glsl"
#include "/lib/shadow.glsl"

#ifndef OUTLINE_FLAG
#define OUTLINE_FLAG 1.0
#endif
#ifndef ALPHA_CUT
#define ALPHA_CUT 0.1
#endif

uniform sampler2D texture;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
#ifdef SHADOWS
uniform sampler2D shadowtex1;
#endif
#ifdef ENTITY_PROGRAM
uniform vec4 entityColor;
#endif

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 normalView;
varying vec3 worldPos;
varying float faceShade;
#ifdef SHADOWS
varying vec4 shadowPosClip;
#endif
#ifdef WAVE_PROGRAM
varying float blockId;
#endif

float qs(float x, float e) { return smoothstep(e - 0.03, e + 0.03, x); }

float dayFactor() {
    return smoothstep(-0.15, 0.15, dot(normalize(sunPosition), normalize(upPosition)));
}

#ifdef SHADOWS
float shadowFactor(vec4 sp) {
    vec3 sc = sp.xyz / sp.w;
    sc.xy = distortShadow(sc.xy);
    sc = sc * 0.5 + 0.5;
    if (sc.x < 0.0 || sc.x > 1.0 || sc.y < 0.0 || sc.y > 1.0 || sc.z > 1.0) return 1.0;
    float texel = 1.0 / float(shadowMapResolution);
    float bias = 0.0007;
    float s = 0.0;
    s += step(sc.z - bias, texture2D(shadowtex1, sc.xy + vec2( 0.7,  0.7) * texel).r);
    s += step(sc.z - bias, texture2D(shadowtex1, sc.xy + vec2(-0.7,  0.7) * texel).r);
    s += step(sc.z - bias, texture2D(shadowtex1, sc.xy + vec2( 0.7, -0.7) * texel).r);
    s += step(sc.z - bias, texture2D(shadowtex1, sc.xy + vec2(-0.7, -0.7) * texel).r);
    s = smoothstep(0.30, 0.70, s * 0.25);
    float fade = 1.0 - smoothstep(0.80, 1.0, length(sc.xy * 2.0 - 1.0));
    return mix(1.0, s, fade);
}
#endif

vec3 toonLight(vec2 lm, vec3 n, float shadow) {
    float dayF = dayFactor();
    vec3 L = normalize(shadowLightPosition);
    float ndl = dot(n, L);

    float outdoors = smoothstep(0.55, 0.85, lm.y);
    float direct = (0.55 * qs(ndl, 0.02) + 0.45 * qs(ndl, 0.55)) * outdoors * shadow;

    vec3 lightCol = mix(vec3(0.20, 0.24, 0.40), vec3(1.00, 0.93, 0.78), dayF);
    vec3 skyAmb = mix(vec3(0.11, 0.13, 0.24), vec3(0.58, 0.66, 0.82), dayF);
    float skyQ = 0.35 + 0.30 * qs(lm.y, 0.30) + 0.35 * qs(lm.y, 0.75);
    vec3 ambient = skyAmb * skyQ + vec3(0.07, 0.07, 0.10);
    ambient *= mix(vec3(0.84, 0.86, 1.10), vec3(1.0), clamp(direct, 0.0, 1.0));

    float tq = 0.45 * qs(lm.x, 0.20) + 0.35 * qs(lm.x, 0.55) + 0.20 * qs(lm.x, 0.85);
    vec3 torch = vec3(1.00, 0.68, 0.34) * tq * 1.1;

    return ambient + lightCol * direct * 0.62 + torch;
}

void main() {
    vec4 tex = texture2D(texture, texcoord);
    if (tex.a < ALPHA_CUT) discard;

    vec2 lm = clamp((lmcoord - 0.0313) / 0.9375, 0.0, 1.0);

#ifdef UP_NORMAL
    vec3 n = normalize(upPosition);
#else
    vec3 n = normalize(normalView);
#endif

    float shadow = 1.0;
#if defined(SHADOWS) && !defined(UP_NORMAL)
    shadow = shadowFactor(shadowPosClip);
    shadow = mix(1.0, shadow, smoothstep(0.0, 0.12, dot(n, normalize(shadowLightPosition))));
#endif

    vec3 tint = glcolor.rgb;
    vec3 c = tex.rgb;
#ifdef WAVE_PROGRAM
    tint = min(glcolor.rgb / max(faceShade, 0.5), vec3(1.0));
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float lq = floor(lum * 4.0 + 0.5) / 4.0;
    float ratio = clamp(lq / max(lum, 0.04), 0.7, 1.4);
    c = mix(c, c * ratio, TEXTURE_FLATTEN);
#endif

    vec3 albedo = c * tint;
    float alpha = tex.a * glcolor.a;
    float flag = OUTLINE_FLAG;
    vec3 col;

#ifdef WAVE_PROGRAM
    if ((blockId > 10000.5 && blockId < 10003.5) || abs(blockId - 10010.0) < 0.5) flag = 0.6;
#endif

#ifdef WATER_PROGRAM
    if (abs(blockId - 10020.0) < 0.5) {
        n = normalize(upPosition);
        vec3 base = mix(tint, vec3(0.20, 0.65, 0.95), 0.6);
        col = base * toonLight(lm, n, 1.0);
        alpha = 0.80;
        flag = 0.75;
    } else {
        col = albedo * toonLight(lm, n, shadow);
    }
#else
    col = albedo * toonLight(lm, n, shadow);
#endif

#ifdef ENTITY_PROGRAM
    col = mix(col, entityColor.rgb, entityColor.a);
#endif

    gl_FragData[0] = vec4(col, alpha);
    gl_FragData[1] = vec4(n * 0.5 + 0.5, flag);
}
