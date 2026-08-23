#!/usr/bin/env bash
# Lock screen wrapper: hyprlock themed via the generated color tokens, with
# a swaylock fallback for GPUs hyprlock can't init on (VMs/llvmpipe —
# force it with GRUVBOX_LOCK_FALLBACK=1, e.g. from lua/local.lua).
set -u
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
[ -f "$CONF/hypr/theme/hyprlock-colors.conf" ] || \
    cp -f "$CONF/hypr/theme/hyprlock-dark.conf" "$CONF/hypr/theme/hyprlock-colors.conf"

use_fallback=0
command -v hyprlock >/dev/null 2>&1 || use_fallback=1
[ -n "${GRUVBOX_LOCK_FALLBACK:-}" ] && use_fallback=1

if [ "$use_fallback" = 1 ] && command -v swaylock >/dev/null 2>&1; then
    # pull the palette from the generated tokens: "$bg = rgb(181616)"
    tok() { sed -n "s/^\$$1 = rgb(\(.*\))/\1/p" "$CONF/hypr/theme/hyprlock-colors.conf"; }
    bg="$(tok bg)"; accent="$(tok accent)"; fg="$(tok fg_bright)"; err="$(tok negative)"
    exec swaylock -f -c "${bg:-181616}" \
        --inside-color "${bg:-181616}CC" --ring-color "${accent:-689d6a}" \
        --key-hl-color "${accent:-689d6a}" --text-color "${fg:-fbf1c7}" \
        --inside-wrong-color "${err:-da4453}66" --ring-wrong-color "${err:-da4453}" \
        2>/dev/null || exec swaylock -f -c "${bg:-181616}"
fi
exec hyprlock
