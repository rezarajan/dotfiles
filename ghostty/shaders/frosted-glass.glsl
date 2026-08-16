// Frosted-glass approximation for the translucent background.
//
// Ghostty custom shaders post-process the terminal's own framebuffer only —
// the desktop behind the window is composited later by KWin, so a shader
// cannot truly blur what's behind it (that needs the compositor blur
// protocol, which ghostty 1.3.x can't speak on Plasma 6.7). Instead this
// frosts the glass: fine static dithering of the background alpha and
// brightness scatters whatever shows through, so sharp shapes behind the
// window read as grain rather than legible content.
//
// Only translucent background pixels are touched; text, the cursor, and
// cells with explicit backgrounds (statuslines, selections) are opaque and
// pass through untouched. Delete this shader (and its config line) once a
// ghostty with ext-background-effect-v1 support delivers real blur.

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 c = texture(iChannel0, uv);

    // opaque-ish pixels (text, statuslines, selections) stay crisp
    if (c.a >= 0.97) {
        fragColor = c;
        return;
    }

    // static grain, blotch-dominant: ~5px blobs sized against text stroke
    // width behind the window, plus fine sparkle
    float fine   = hash12(floor(fragCoord));
    float coarse = hash12(floor(fragCoord / 5.0) + 17.0);
    float g01 = mix(fine, coarse, 0.8); // [0, 1]

    // fade the frost out near full opacity so glyph antialiasing edges
    // (alpha between the bg value and 1.0) don't get roughened
    float w = smoothstep(0.97, 0.93, c.a);

    // colors are premultiplied; unpremultiply to recover the bg tint
    float a0 = max(c.a, 1e-4);
    vec3 tint = c.rgb / a0;

    // frost pores: most of the glass transmits nothing, light leaks only
    // through scattered soft pores — per-pixel dimming alone leaves
    // backdrop strokes contiguous enough to read; gating disconnects them
    float pore = smoothstep(0.45, 0.95, g01);
    float t = (1.0 - c.a) * mix(1.0, pore * 2.5, w);
    float a = clamp(1.0 - t, 0.0, 1.0);

    // and shimmer the glass tint itself so the frost has visible texture
    tint *= 1.0 + (pore - 0.35) * 0.08 * w;

    fragColor = vec4(tint * a, a);
}
