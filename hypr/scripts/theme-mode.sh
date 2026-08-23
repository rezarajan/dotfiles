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

# GTK named colors — the standalone replacement for what kde-gtk-config
# writes under KDE. The Gruvbox-Dragon theme is Breeze widgets + these
# names + the acrylic overlay, so one theme serves both modes.
for v in 3 4; do
    mkdir -p "$CONF/gtk-$v.0"
    copy "$CONF/hypr/theme/gtk-colors-$MODE.css" "$CONF/gtk-$v.0/colors.css"
    copy "$CONF/hypr/theme/gtk-tweaks.css" "$CONF/gtk-$v.0/gruvbox-tweaks.css"
    gtkcss="$CONF/gtk-$v.0/gtk.css"
    touch "$gtkcss"
    grep -q "colors.css" "$gtkcss" 2>/dev/null || \
        sed -i "1i @import 'colors.css';" "$gtkcss"
    if [ -f "$CONF/gtk-$v.0/gruvbox-acrylic.css" ]; then
        grep -q "gruvbox-acrylic.css" "$gtkcss" 2>/dev/null || \
            printf "@import 'gruvbox-acrylic.css';\n" >> "$gtkcss"
    fi
    grep -q "gruvbox-tweaks.css" "$gtkcss" 2>/dev/null || \
        printf "@import 'gruvbox-tweaks.css';\n" >> "$gtkcss"
done

# GTK settings.ini — what kde-gtk-config writes under KDE. Chromium and
# plain GTK3 apps read the theme name and dark preference from here.
if [ "$MODE" = light ]; then GTK_DARK=false; else GTK_DARK=true; fi
for v in 3 4; do
    cat > "$CONF/gtk-$v.0/settings.ini" <<EOF
# written by theme-mode.sh (hyprland session) — mode: $MODE
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICONS
gtk-cursor-theme-name=$CURSOR
gtk-cursor-theme-size=24
gtk-font-name=Inter,  11
gtk-application-prefer-dark-theme=$GTK_DARK
gtk-decoration-layout=icon:minimize,maximize,close
EOF
done

# Qt outside KDE: qt6ct carries the Kvantum style + icon theme
mkdir -p "$CONF/qt6ct"
copy "$CONF/hypr/theme/qt6ct-$MODE.conf" "$CONF/qt6ct/qt6ct.conf"

# KDE apps (Dolphin & friends) read kdeglobals. On a machine where KDE /
# home-manager manages that file, flip only the three theme keys (with
# change notification so running apps restyle); otherwise install the
# generated minimal kdeglobals.
if [ "$MODE" = light ]; then
    KDE_SCHEME=GruvboxDragonLight; KDE_WIDGET=kvantum
else
    KDE_SCHEME=GruvboxDragon; KDE_WIDGET=kvantum-dark
fi
SCHEME_FILE=""
for dir in "${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes" /usr/share/color-schemes; do
    [ -f "$dir/$KDE_SCHEME.colors" ] && SCHEME_FILE="$dir/$KDE_SCHEME.colors" && break
done
if [ ! -f "$CONF/kdeglobals" ]; then
    copy "$CONF/hypr/theme/kdeglobals-$MODE" "$CONF/kdeglobals"
elif [ -n "$SCHEME_FILE" ]; then
    # kdeglobals inlines [Colors:*] groups (plasma does the same on scheme
    # apply) and those override the ColorScheme name — swap the color and
    # WM groups wholesale, keep every other group untouched
    awk 'BEGIN{skip=0} /^\[/{skip=($0~/^\[(Colors:|ColorEffects:|WM\])/)?1:0} !skip' \
        "$CONF/kdeglobals" > "$CONF/kdeglobals.tmp"
    awk 'BEGIN{keep=0} /^\[/{keep=($0~/^\[(Colors:|ColorEffects:|WM\])/)?1:0} keep' \
        "$SCHEME_FILE" >> "$CONF/kdeglobals.tmp"
    mv -f "$CONF/kdeglobals.tmp" "$CONF/kdeglobals"
fi
# (timeout-guarded: kwriteconfig6 can block when the session bus is odd)
if command -v kwriteconfig6 >/dev/null 2>&1; then
    timeout 5 kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$KDE_SCHEME"
    timeout 5 kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICONS"
    timeout 5 kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "$KDE_WIDGET"
fi
# live palette reload for running KDE apps — the broadcast plasma sends
# (0 = PaletteChanged, 4 = IconChanged, 2 = StyleChanged)
if command -v dbus-send >/dev/null 2>&1; then
    for change in 0 2 4; do
        timeout 5 dbus-send --session --type=signal /KGlobalSettings \
            org.kde.KGlobalSettings.notifyChange int32:$change int32:0 2>/dev/null
    done
fi
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
# write the kvantum selection directly (kvantummanager --set pops its GUI
# on some versions)
mkdir -p "$CONF/Kvantum"
printf '[General]\ntheme=%s\n' "$KVANTUM" > "$CONF/Kvantum/kvantum.kvconfig"
if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl setcursor "$CURSOR" 24 >/dev/null 2>&1
fi

# --- 5. live reloads (skipped on plain `apply` at session start) --------------
if [ "$cmd" != apply ] && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    timeout 10 hyprctl reload >/dev/null 2>&1  # theme.lua re-reads the mode file
    pkill -SIGUSR2 waybar 2>/dev/null      # waybar re-parses its stylesheet
    pkill -SIGRTMIN+9 waybar 2>/dev/null   # refresh the custom/theme button
    command -v swaync-client >/dev/null 2>&1 && swaync-client -rs >/dev/null 2>&1
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -a "Theme" -i preferences-desktop-theme \
            "Gruvbox $MODE" "Switched to the $MODE variant"
fi
