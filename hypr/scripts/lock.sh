#!/usr/bin/env bash
# Lock screen wrapper.
#
# Primary: hyprlock (wallpaper blur, clock, themed input field).
# Fallback: swaylock — used where hyprlock cannot init GL (VMs / software
# rendering, detected via LIBGL_ALWAYS_SOFTWARE, forced with
# GRUVBOX_LOCK_FALLBACK=1). To avoid a blank colored wall, the fallback
# composes a lock image from the current wallpaper: blurred, dimmed, with
# clock/date/hint baked in, plus a themed indicator while typing.
set -u
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
[ -f "$CONF/hypr/theme/hyprlock-colors.conf" ] || \
    cp -f "$CONF/hypr/theme/hyprlock-dark.conf" "$CONF/hypr/theme/hyprlock-colors.conf"

use_fallback=0
command -v hyprlock >/dev/null 2>&1 || use_fallback=1
[ -n "${GRUVBOX_LOCK_FALLBACK:-}" ] && use_fallback=1
[ -n "${LIBGL_ALWAYS_SOFTWARE:-}" ] && use_fallback=1

if [ "$use_fallback" = 1 ] && command -v swaylock >/dev/null 2>&1; then
    tok() { sed -n "s/^\$$1 = rgb(\(.*\))/\1/p" "$CONF/hypr/theme/hyprlock-colors.conf"; }
    bg="$(tok bg)"; accent="$(tok accent)"; fg="$(tok fg_bright)"
    muted="$(tok fg_muted)"; err="$(tok negative)"

    wall="$CONF/hypr/wallpaper.jpg"
    lockimg="${XDG_RUNTIME_DIR:-/tmp}/gruvbox-lock.png"
    imgargs=(-c "${bg:-181616}")
    if command -v magick >/dev/null 2>&1 && [ -f "$wall" ]; then
        res="$(command -v hyprctl >/dev/null 2>&1 \
            && hyprctl -j monitors 2>/dev/null \
               | jq -r '.[0] | "\(.width)x\(.height)"' 2>/dev/null)"
        res="${res:-1920x1080}"
        font="$(fc-match -f '%{file}' 'Inter:weight=medium' 2>/dev/null)"
        if magick "$wall" -resize "${res}^" -gravity center -extent "$res" \
            -blur 0x10 -fill black -colorize 45% \
            ${font:+-font "$font"} \
            -fill "#${fg:-fbf1c7}" -gravity center \
            -pointsize 110 -annotate +0-160 "$(date +%H:%M)" \
            -pointsize 26 -annotate +0-70 "$(date +'%A, %B %-d')" \
            -fill "#${muted:-928374}" -pointsize 17 \
            -annotate +0+240 "type password to unlock" \
            "$lockimg" 2>"${XDG_RUNTIME_DIR:-/tmp}/gruvbox-lock-compose.log"; then
            imgargs=(-i "$lockimg" -s fill)
        fi
    fi

    exec swaylock -f "${imgargs[@]}" \
        --font Inter --indicator-radius 85 --indicator-thickness 9 \
        --key-hl-color "${accent:-689d6a}" --bs-hl-color "${err:-da4453}" \
        --ring-color "${muted:-928374}88" --line-color 00000000 \
        --inside-color "${bg:-181616}99" --separator-color 00000000 \
        --text-color "${fg:-fbf1c7}" \
        --ring-ver-color "${accent:-689d6a}" --inside-ver-color "${bg:-181616}CC" \
        --text-ver-color "${fg:-fbf1c7}" \
        --ring-wrong-color "${err:-da4453}" --inside-wrong-color "${err:-da4453}44" \
        --text-wrong-color "${fg:-fbf1c7}" \
        --ring-clear-color "${accent:-689d6a}" --inside-clear-color "${bg:-181616}99" \
        --text-clear-color "${fg:-fbf1c7}"
fi
exec hyprlock
