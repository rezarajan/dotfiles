#!/usr/bin/env bash
# Dark/light mode switch for the Hyprland session — the analogue of KDE's
# look-and-feel toggle. One state file drives everything:
#
#   theme-mode.sh get           print current mode
#   theme-mode.sh set dark      switch to a specific mode
#   theme-mode.sh toggle        flip modes
#   theme-mode.sh apply         re-apply current mode (run at session start)
#
# What a switch does:
#   1. writes $XDG_STATE_HOME/gruvbox/mode (hypr/lua/theme.lua reads it)
#   2. copies the generated colors-<mode>.* tokens over the gitignored
#      active copies (waybar / rofi / swaync / wlogout / hyprlock)
#   3. broadcasts to the GNOME/portal namespace via gsettings — this is what
#      kde-gruvbox.nix's sync-gnome-portal-settings service did under KDE
#   4. switches the Kvantum theme for Qt apps and the cursor theme
#   5. reloads hyprland, waybar and swaync in place

set -u
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/gruvbox"
MODE_FILE="$STATE_DIR/mode"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"

mode_get() { cat "$MODE_FILE" 2>/dev/null || echo dark; }

cmd="${1:-toggle}"
case "$cmd" in
    get) mode_get; exit 0 ;;
    set) MODE="${2:?usage: theme-mode.sh set dark|light}" ;;
    toggle) if [ "$(mode_get)" = dark ]; then MODE=light; else MODE=dark; fi ;;
    apply) MODE="$(mode_get)" ;;
    *) echo "usage: theme-mode.sh get|set|toggle|apply" >&2; exit 2 ;;
esac

mkdir -p "$STATE_DIR"
printf '%s\n' "$MODE" > "$MODE_FILE"

if [ "$MODE" = light ]; then
    CURSOR=Gruvbox-Dragon-Cursors-Light
    GTK_THEME=Gruvbox-Dragon-Light
    ICONS=Gruvbox-Plus-Light
    SCHEME=prefer-light
    KVANTUM=Gruvbox
else
    CURSOR=Gruvbox-Dragon-Cursors
    GTK_THEME=Gruvbox-Dragon
    ICONS=Gruvbox-Plus-Dark
    SCHEME=prefer-dark
    KVANTUM=GruvboxDark
fi

# --- 2. activate the generated per-mode tokens --------------------------------
copy() { [ -f "$1" ] && cp -f "$1" "$2"; }
copy "$CONF/waybar/colors-$MODE.css"        "$CONF/waybar/colors.css"
copy "$CONF/rofi/colors-$MODE.rasi"         "$CONF/rofi/colors.rasi"
copy "$CONF/swaync/colors-$MODE.css"        "$CONF/swaync/colors.css"
# wlogout stays on the dark tokens in both modes (its icons are light SVGs
# over a dark scrim, like KDE's logout overlay)
copy "$CONF/wlogout/colors-dark.css"        "$CONF/wlogout/colors.css"
copy "$CONF/hypr/theme/hyprlock-$MODE.conf" "$CONF/hypr/theme/hyprlock-colors.conf"

# --- 3. portal / GTK broadcast ------------------------------------------------
theme_exists() {
    [ -d "$HOME/.themes/$1" ] || [ -d "$HOME/.local/share/themes/$1" ] \
        || [ -d "/usr/share/themes/$1" ]
}
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme "$SCHEME"
    if theme_exists "$GTK_THEME"; then
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
    fi
    gsettings set org.gnome.desktop.interface icon-theme "$ICONS" 2>/dev/null
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR" 2>/dev/null
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface font-name 'Inter 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
fi

# --- 4. Qt (Kvantum) + cursor -------------------------------------------------
command -v kvantummanager >/dev/null 2>&1 && kvantummanager --set "$KVANTUM" >/dev/null 2>&1
if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl setcursor "$CURSOR" 24 >/dev/null 2>&1
fi

# --- 5. live reloads (skipped on plain `apply` at session start) --------------
if [ "$cmd" != apply ] && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null 2>&1        # theme.lua re-reads the mode file
    pkill -SIGUSR2 waybar 2>/dev/null      # waybar re-parses its stylesheet
    command -v swaync-client >/dev/null 2>&1 && swaync-client -rs >/dev/null 2>&1
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -a "Theme" -i preferences-desktop-theme \
            "Gruvbox $MODE" "Switched to the $MODE variant"
fi
