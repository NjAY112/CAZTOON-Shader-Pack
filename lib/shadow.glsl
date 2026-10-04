// Cartoon-style shadow distortion, smoother with cleaner silhouettes.
vec2 distortShadow(vec2 p) {
    float f = length(p) * SHADOW_DISTORT + (1.0 - SHADOW_DISTORT);
    return p / f;
}
