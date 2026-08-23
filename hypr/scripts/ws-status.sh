#!/usr/bin/env bash
# State of one workspace pill for waybar (custom/wsN). Event-driven:
# lua/bar.lua pokes waybar (RTMIN+7) whenever workspaces/windows change.
# Classes: active | occupied | empty | hidden (does not exist, N > 3).
set -u
n="${1:?usage: ws-status.sh <workspace-number>}"

windows="$(timeout 3 hyprctl -j workspaces 2>/dev/null \
    | jq -r --argjson n "$n" '.[] | select(.id == $n) | .windows' 2>/dev/null)"
active="$(timeout 3 hyprctl -j activeworkspace 2>/dev/null | jq -r .id 2>/dev/null)"

cls="empty"
if [ -z "$windows" ]; then
    # workspace doesn't exist right now; 1-3 are persistent, others hide
    [ "$n" -gt 3 ] && cls="hidden"
elif [ "$windows" -gt 0 ]; then
    cls="occupied"
fi
[ "$active" = "$n" ] && cls="active"

if [ "$cls" = hidden ]; then
    printf '{"text":"","class":"hidden"}\n'
else
    printf '{"text":"%s","class":"%s","tooltip":"Workspace %s"}\n' "$n" "$cls" "$n"
fi
