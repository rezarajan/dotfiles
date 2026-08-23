#!/usr/bin/env bash
# Toggle the audio mixer as an applet-style dropdown (bar volume click).
# The window rules in lua/rules.lua park it under the bar's right edge and
# lua/applets.lua closes it again when it loses focus — Plasma-popup feel.
# Prefers pwvucontrol (modern PipeWire mixer), falls back to pavucontrol.
set -u
MIXER=""
for bin in pwvucontrol pavucontrol; do
    if command -v "$bin" >/dev/null 2>&1; then MIXER="$bin"; break; fi
done
[ -n "$MIXER" ] || exit 1

if pgrep -x "$MIXER" >/dev/null 2>&1; then
    pkill -x "$MIXER"
else
    exec "$MIXER"
fi
