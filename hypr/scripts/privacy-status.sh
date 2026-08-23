#!/usr/bin/env bash
# Privacy indicator for waybar (custom/privacy): shows which apps hold the
# microphone or a camera, KDE-panel style. Output is one JSON line.
set -u

mic_icon="󰍬" cam_icon="󰄀"

# microphone: active pipewire recording streams (monitors excluded by
# pactl's source-output listing already representing app captures)
mic_apps=""
if command -v pactl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    mic_apps="$(pactl --format=json list source-outputs 2>/dev/null | jq -r '
        [.[] | .properties["application.name"]
             // .properties["application.process.binary"] // "unknown"]
        | unique | join(", ")')"
fi

# camera: processes holding /dev/video*
cam_apps=""
if command -v fuser >/dev/null 2>&1; then
    for dev in /dev/video*; do
        [ -e "$dev" ] || continue
        for pid in $(fuser "$dev" 2>/dev/null); do
            name="$(ps -o comm= -p "$pid" 2>/dev/null)"
            case " $cam_apps " in *" $name "*) ;; *) cam_apps="$cam_apps $name" ;; esac
        done
    done
    cam_apps="${cam_apps# }"
fi

text=""
tooltip=""
[ -n "$mic_apps" ] && { text="$mic_icon"; tooltip="Microphone: $mic_apps"; }
[ -n "$cam_apps" ] && {
    text="${text:+$text }$cam_icon"
    tooltip="${tooltip:+$tooltip\n}Camera: $cam_apps"
}

if [ -n "$text" ]; then
    printf '{"text":"%s","class":"active","tooltip":"%s\\nClick: mixer · right-click: switch microphone"}\n' \
        "$text" "$tooltip"
else
    printf '{"text":""}\n'
fi
