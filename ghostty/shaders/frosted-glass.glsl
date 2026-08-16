// Acrylic surface finish for the translucent background.
//
// Ghostty custom shaders post-process the terminal's own framebuffer only —
// the desktop behind the window is composited later by KWin, so a shader
// cannot blur what's behind it (that needs the compositor blur protocol,
// which ghostty 1.3.x can't speak on Plasma 6.7). What a shader CAN do
// cleanly is the rest of the acrylic recipe: an even glass tint with a
// barely-there micro-texture and a soft top-light sheen, applied to the
// surface color only. The alpha channel is left untouched, so the
// translucency stays perfectly uniform — no grain in what shows through.
//
// Text, the cursor, and cells with explicit backgrounds (statuslines,
// selections) are opaque and pass through untouched. Delete this shader
// (and its config line) once a ghostty with ext-background-effect-v1
// support delivers real compositor blur.

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// smooth value noise — soft blobs, no grain
float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 c = texture(iChannel0, uv);

    // opaque pixels (text, statuslines, selections) stay untouched
    if (c.a >= 0.97) {
        fragColor = c;
        return;
    }

    // fade the finish out near full opacity so glyph antialiasing edges
    // (alpha between the bg value and 1.0) keep their exact color
    float w = smoothstep(0.97, 0.93, c.a);

    // colors are premultiplied; unpremultiply to recover the glass tint
    float a0 = max(c.a, 1e-4);
    vec3 tint = c.rgb / a0;

    // micro-texture: static single-pixel luminance noise at ~2% — the
    // classic acrylic surface finish (additive, so it reads on dark and
    // light variants alike)
    float n = hash12(floor(fragCoord)) - 0.5;

    // frost veil: frosted glass scatters light, so the pane gains a soft
    // milky lift with smooth unevenness — this is what lowers the
    // contrast of whatever bleeds through and makes it read as blurred.
    // The unevenness scales with the window (not fixed pixels), so a
    // fullscreen pane gets a few broad sweeps of haze instead of tiling
    // dozens of blotches; most of the veil is the uniform base lift.
    float frost = vnoise(fragCoord / (iResolution.y * 0.55)) * 0.6
                + vnoise(fragCoord / (iResolution.y * 0.20) + 31.7) * 0.4;
    float veil = 0.048 + (frost - 0.5) * 0.018;

    // soft sheen: the glass catches a little more light at the top
    float sheen = (0.5 - uv.y) * 0.022;

    tint += (veil + sheen + n * 0.022) * w;

    // alpha is deliberately unchanged: uniform translucency, no grain in
    // the see-through
    fragColor = vec4(tint * c.a, c.a);
}
