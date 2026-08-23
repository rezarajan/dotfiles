#!/usr/bin/env bash
# NetworkManager connectivity watcher (started by session-start.sh).
# The KDE behavior: when a network needs a captive-portal sign-in, raise a
# notification with a clickable "Open sign-in page" button; also announce
# connect/disconnect state changes quietly.
#
#   net-watch.sh          watch nmcli monitor (blocks; one instance)
#   net-watch.sh --test   fire the portal notification once and exit
set -u

PORTAL_URL="http://nmcheck.gnome.org"   # any http page — the portal hijacks it

portal_notify() {
    command -v notify-send >/dev/null 2>&1 || return
    action="$(notify-send -a Network -i network-wireless-hotspot-symbolic \
        -A open="Open sign-in page" -u critical \
        "Sign-in required" \
        "This network requires you to log in before it grants access.")"
    if [ "$action" = open ]; then
        xdg-open "$PORTAL_URL" >/dev/null 2>&1 &
    fi
}

if [ "${1:-}" = "--test" ]; then
    portal_notify
    exit 0
fi

command -v nmcli >/dev/null 2>&1 || exit 0

# initial state can already be behind a portal (e.g. hotel wifi at login)
case "$(nmcli -t -f CONNECTIVITY general status 2>/dev/null)" in
    portal) portal_notify ;;
esac

nmcli monitor 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *"Connectivity is now 'portal'"*)
            portal_notify &  # blocks until clicked/dismissed — keep the loop live
            ;;
        *"Connectivity is now 'full'"*)
            : ;; # back online quietly
        *"disconnected"*)
            case "$line" in
                *device*) ;; # per-device noise
                *) command -v notify-send >/dev/null 2>&1 && \
                    notify-send -a Network -i network-offline-symbolic "Disconnected" \
                        "Network connection lost" ;;
            esac ;;
    esac
done
