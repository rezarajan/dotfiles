#!/usr/bin/env bash
# Clipboard history picker (Super+V) — cliphist + rofi.
set -u
selection="$(cliphist list | rofi -dmenu -i -p 'Clipboard' -display-columns 2)" || exit 0
printf '%s' "$selection" | cliphist decode | wl-copy
