#!/usr/bin/env bash
# Network menu (rofi) — the plasma-nm applet experience: Wi-Fi list with
# signal strength, one-click connect (password prompt for new secured
# networks), Wi-Fi toggle, wired/VPN status, and the connection editor.
# Bar network icon click opens this; right-click opens the editor applet.
set -u
here="$(cd -P "$(dirname "$0")" && pwd)"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a Network "$@"; }

if ! command -v nmcli >/dev/null 2>&1 || ! nmcli general status >/dev/null 2>&1; then
    notify "NetworkManager unavailable" "Install/enable NetworkManager for the network menu"
    exec bash "$here/panel.sh" network
fi

signal_icon() { # 0..100 -> bars
    if   [ "$1" -ge 90 ]; then printf '󰤨'
    elif [ "$1" -ge 70 ]; then printf '󰤥'
    elif [ "$1" -ge 45 ]; then printf '󰤢'
    elif [ "$1" -ge 20 ]; then printf '󰤟'
    else printf '󰤯'; fi
}

build_menu() {
    local wifi_hw
    wifi_hw="$(nmcli -t -f WIFI radio)"

    # wired + vpn status first, like the plasma applet's top section
    nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null \
        | while IFS=: read -r name type dev; do
            case "$type" in
                *ethernet*) printf '󰈀  %s — connected (%s)\n' "$name" "$dev" ;;
                *vpn*)      printf '󰖂  %s — VPN active ▸ disconnect\n' "$name" ;;
            esac
        done
    nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep ':vpn$' \
        | while IFS=: read -r name _; do
            nmcli -t -f NAME connection show --active | grep -qFx "$name" \
                || printf '󰖂  %s — VPN ▸ connect\n' "$name"
        done

    if [ "$wifi_hw" = enabled ]; then
        printf '󰖩  Wi-Fi: on ▸ turn off\n'
        nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan auto 2>/dev/null \
            | sort -t: -k3 -rn | while IFS=: read -r inuse ssid signal sec; do
                [ -n "$ssid" ] || continue
                mark=""; [ "$inuse" = "*" ] && mark="● "
                lock=""; [ "$sec" != "" ] && [ "$sec" != "--" ] && lock="  󰌾"
                printf '%s%s  %s%s\n' "$mark" "$(signal_icon "${signal:-0}")" "$ssid" "$lock"
            done
    else
        printf '󰖪  Wi-Fi: off ▸ turn on\n'
    fi

    printf '󰑓  Rescan networks\n'
    printf '󰒓  Connection editor…\n'
}

choice="$(build_menu | rofi -dmenu -i -p 'Network')" || exit 0

case "$choice" in
    *"Wi-Fi: on"*)  nmcli radio wifi off; notify -i network-wireless-offline "Wi-Fi disabled" ;;
    *"Wi-Fi: off"*) nmcli radio wifi on; notify -i network-wireless "Wi-Fi enabled" ;;
    *"Rescan"*)     nmcli device wifi rescan 2>/dev/null; exec "$0" ;;
    *"Connection editor"*) exec bash "$here/panel.sh" network ;;
    *"VPN ▸ connect")
        name="${choice#󰖂  }"; name="${name% — VPN ▸ connect}"
        nmcli connection up "$name" >/dev/null 2>&1 \
            && notify -i network-vpn "VPN connected" "$name" \
            || notify -i dialog-error "VPN failed" "$name" ;;
    *"VPN active ▸ disconnect")
        name="${choice#󰖂  }"; name="${name% — VPN active ▸ disconnect}"
        nmcli connection down "$name" >/dev/null 2>&1 \
            && notify "VPN disconnected" "$name" ;;
    *"— connected"*) ;; # wired status row: nothing to do
    *)
        # a Wi-Fi row: strip mark/icon/lock to recover the SSID
        ssid="$(printf '%s' "$choice" | sed -e 's/^● //' -e 's/^[^ ]*  //' -e 's/  󰌾$//')"
        [ -n "$ssid" ] || exit 0
        if nmcli -t -f NAME connection show | grep -qFx "$ssid"; then
            nmcli connection up "$ssid" >/dev/null 2>&1 \
                && notify -i network-wireless "Connected" "$ssid" \
                || notify -i dialog-error "Connection failed" "$ssid"
        else
            secured=""; printf '%s' "$choice" | grep -q '󰌾' && secured=1
            if [ -n "$secured" ]; then
                pw="$(rofi -dmenu -password -p "Password for $ssid")" || exit 0
                nmcli device wifi connect "$ssid" password "$pw" >/dev/null 2>&1 \
                    && notify -i network-wireless "Connected" "$ssid" \
                    || notify -i dialog-error "Connection failed" "$ssid — wrong password?"
            else
                nmcli device wifi connect "$ssid" >/dev/null 2>&1 \
                    && notify -i network-wireless "Connected" "$ssid" \
                    || notify -i dialog-error "Connection failed" "$ssid"
            fi
        fi ;;
esac
