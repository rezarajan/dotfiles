#!/usr/bin/env bash
# rofi wrapper: ensures the active color tokens exist, then launches the
# requested mode (drun by default). All rofi surfaces go through this so
# they always match the current theme.
set -u
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
[ -f "$CONF/rofi/colors.rasi" ] || cp -f "$CONF/rofi/colors-dark.rasi" "$CONF/rofi/colors.rasi"
exec rofi -show "${1:-drun}"
