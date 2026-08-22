#!/usr/bin/env bash
# Lock screen wrapper: makes sure the active color tokens exist before
# hyprlock sources them.
set -u
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
[ -f "$CONF/hypr/theme/hyprlock-colors.conf" ] || \
    cp -f "$CONF/hypr/theme/hyprlock-dark.conf" "$CONF/hypr/theme/hyprlock-colors.conf"
exec hyprlock
