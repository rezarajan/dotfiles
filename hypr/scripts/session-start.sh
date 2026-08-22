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

# 1. activate the persisted dark/light mode (writes colors.* copies,
#    broadcasts portal color-scheme, sets cursor + kvantum)
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

# wallpaper: hyprpaper on real GPUs; swaybg (shm, no GL) as the fallback for
# software-rendered environments like VMs, where hyprpaper's GL init aborts
start hyprpaper
(
    sleep 2
    if ! running hyprpaper && have swaybg && ! running swaybg; then
        swaybg -i "$CONF/hypr/wallpaper.jpg" -m fill &
    fi
) &
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

exit 0
