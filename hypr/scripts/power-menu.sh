#!/usr/bin/env bash
# Session/power menu (rofi): lock, logout, suspend, hibernate, reboot,
# shutdown. Destructive actions ask for confirmation. Bound to
# Super+Backspace and the bar's power button.
set -u
here="$(cd -P "$(dirname "$0")" && pwd)"

confirm() {
    choice="$(printf 'No\nYes' | rofi -dmenu -i -p "$1?")" || return 1
    [ "$choice" = "Yes" ]
}

choice="$(printf '%s\n' \
    "󰌾  Lock" \
    "󰍃  Log out" \
    "󰒲  Suspend" \
    "󰋊  Hibernate" \
    "󰜉  Restart" \
    "󰐥  Shut down" \
    | rofi -dmenu -i -p "Session" -select "󰌾  Lock")" || exit 0

case "$choice" in
    *Lock)      exec bash "$here/lock.sh" ;;
    *"Log out") confirm "Log out" && hyprctl dispatch 'hl.dsp.exit()' ;;
    *Suspend)   systemctl suspend ;;
    *Hibernate) systemctl hibernate ;;
    *Restart)   confirm "Restart" && systemctl reboot ;;
    *"Shut down") confirm "Shut down" && systemctl poweroff ;;
esac
