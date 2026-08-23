#!/usr/bin/env bash
# Volume / brightness OSD — the popup every desktop shows on media keys.
# Uses synchronous, transient notifications with a progress-bar hint
# (rendered by swaync as a slider), replacing in place on repeat presses.
#
#   osd.sh volume-up|volume-down|volume-mute|mic-mute
#   osd.sh brightness-up|brightness-down
set -u

osd() { # osd <icon+title> <value 0..100>
    command -v notify-send >/dev/null 2>&1 || return
    notify-send -a OSD -e \
        -h string:x-canonical-private-synchronous:gruvbox-osd \
        -h "int:value:$2" "$1"
}

vol_state() { # prints "<percent> <muted?1>"
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null \
        | awk '{ v = int($2 * 100 + 0.5); m = /MUTED/ ? 1 : 0; print v, m }'
}

case "${1:-}" in
    volume-up|volume-down)
        [ "$1" = volume-up ] && d="5%+" || d="5%-"
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "$d" 2>/dev/null
        read -r v m < <(vol_state)
        if [ "${m:-0}" = 1 ]; then osd "󰝟  Volume muted" "${v:-0}"
        else osd "󰕾  Volume ${v:-0}%" "${v:-0}"; fi ;;
    volume-mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null
        read -r v m < <(vol_state)
        if [ "${m:-0}" = 1 ]; then osd "󰝟  Muted" "0"
        else osd "󰕾  Volume ${v:-0}%" "${v:-0}"; fi ;;
    mic-mute)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle 2>/dev/null
        if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED; then
            osd "󰍭  Microphone muted" "0"
        else
            osd "󰍬  Microphone on" "100"
        fi ;;
    brightness-up|brightness-down)
        [ "$1" = brightness-up ] && d="5%+" || d="5%-"
        out="$(brightnessctl -m -e4 -n2 set "$d" 2>/dev/null)"
        pct="$(printf '%s' "$out" | awk -F, '{gsub(/%/, "", $4); print $4}')"
        osd "󰃞  Brightness ${pct:-?}%" "${pct:-0}" ;;
    *) echo "usage: osd.sh volume-up|volume-down|volume-mute|mic-mute|brightness-up|brightness-down" >&2; exit 2 ;;
esac
