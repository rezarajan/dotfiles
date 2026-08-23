#!/usr/bin/env bash
# Keybinding cheatsheet (Super+F1 or the bar's help button): reads the
# live binds from hyprctl and shows a searchable, readable rofi list.
set -u
hyprctl -j binds 2>/dev/null | jq -r '
    def mods($m):
        [ (if ($m / 64 | floor) % 2 == 1 then "Super" else empty end),
          (if ($m / 4  | floor) % 2 == 1 then "Ctrl"  else empty end),
          (if ($m / 8  | floor) % 2 == 1 then "Alt"   else empty end),
          (if ($m      | floor) % 2 == 1 then "Shift" else empty end) ]
        | join("+");
    .[] | select(.description != null and .description != "")
        | (mods(.modmask) as $m
           | (if $m == "" then .key else $m + "+" + .key end)) as $keys
        | "\($keys)\t\(.description)"' \
    | sort -t$'\t' -k2 \
    | column -t -s $'\t' -o "   " \
    | rofi -dmenu -i -p 'Keybindings' >/dev/null
