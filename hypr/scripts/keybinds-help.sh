#!/usr/bin/env bash
# Searchable keybinding cheatsheet (Super+F1): reads live binds from
# hyprctl, shows "keys — description" in rofi.
set -u
hyprctl -j binds | jq -r '
    .[] | select(.description != "") |
    ((if .modmask == 64 then "Super"
      elif .modmask == 65 then "Super+Shift"
      elif .modmask == 68 then "Super+Ctrl"
      elif .modmask == 69 then "Super+Ctrl+Shift"
      elif .modmask == 0 then ""
      else "mod\(.modmask)" end)
     + (if .modmask != 0 then "+" else "" end) + .key)
    + "\t" + .description' \
    | column -t -s $'\t' \
    | rofi -dmenu -i -p 'Keybindings' >/dev/null
