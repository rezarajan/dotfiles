#!/usr/bin/env bash
# Ordered session startup, run once from hl.on("hyprland.start").
# Order matters: the theme tokens and wallpaper must exist before the
# daemons that read them start. Everything optional is guarded so a lean
# install (or the test VM) comes up cleanly.
set -u
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
here="$(cd "$(dirname "$0")" && pwd)"

have() { command -v "$1" >/dev/null 2>&1; }
running() { pgrep -x "$1" >/dev/null 2>&1; }
start() { have "$1" && ! running "$1" && "$@" & }

# 1. make sure the theme assets are reachable (no-op on home-manager
#    machines; links cursors/gtk/kvantum/color-schemes elsewhere), then
#    activate the persisted dark/light mode (writes colors.* copies,
#    broadcasts portal color-scheme, sets cursor + kvantum + kdeglobals)
bash "$here/install-theme-assets.sh" >/dev/null 2>&1
bash "$here/theme-mode.sh" apply

# 2. seed the wallpaper on first boot (hyprpaper + hyprlock read it)
if [ ! -e "$CONF/hypr/wallpaper.jpg" ]; then
    for src in "$HOME/git/dotfiles/wallpapers/default.jpg"; do
        [ -f "$src" ] && cp "$src" "$CONF/hypr/wallpaper.jpg" && break
    done
fi

# 3. authentication agent (ships a systemd user unit)
if have hyprpolkitagent; then
    systemctl --user start hyprpolkitagent.service 2>/dev/null &
fi

# 4. shell daemons — bar, notifications, wallpaper, idle
start waybar
start hypridle

# wallpaper: swww when installed (animated transitions, CPU-rendered —
# powers scripts/wallpaper.sh); otherwise hyprpaper with a swaybg fallback
# for software-rendered environments like VMs, where hyprpaper's GL init
# fails — sometimes leaving the process alive without ever mapping a
# layer, so check for the actual background layer rather than the process
SWWW_DAEMON="$(command -v swww-daemon 2>/dev/null || command -v awww-daemon 2>/dev/null || true)"
if [ -n "$SWWW_DAEMON" ]; then
    if ! running swww-daemon && ! running awww-daemon; then
        "$SWWW_DAEMON" &
    fi
    (sleep 2; bash "$here/wallpaper.sh" restore >/dev/null 2>&1) &
else
    start hyprpaper
    (
        sleep 3
        if ! hyprctl layers 2>/dev/null | grep -qE "namespace: (hyprpaper|wallpaper)"; then
            pkill -x hyprpaper 2>/dev/null
            if have swaybg && ! running swaybg; then
                swaybg -i "$CONF/hypr/wallpaper.jpg" -m fill &
            fi
        fi
    ) &
fi
if have swaync; then
    if running swaync; then
        swaync-client -rs >/dev/null 2>&1   # re-read css now that tokens exist
    else
        swaync &
    fi
fi

# 5. clipboard history for Super+V
if have wl-paste && have cliphist; then
    if ! pgrep -f "wl-paste.*cliphist" >/dev/null; then
        wl-paste --type text --watch cliphist store &
        wl-paste --type image --watch cliphist store &
    fi
fi

# 6. tray niceties (skipped when absent)
start nm-applet
start blueman-applet

# 7. captive-portal / connectivity watcher (KDE-style sign-in notification)
if command -v nmcli >/dev/null 2>&1; then
    pgrep -f "net-watch.sh" >/dev/null 2>&1 || bash "$here/net-watch.sh" &
fi

# re-run the theme apply once the session has settled: at the very first
# seconds of a session dconf/dbus may not be ready for gsettings writes
(sleep 4; bash "$here/theme-mode.sh" apply) &

exit 0
