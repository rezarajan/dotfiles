#!/usr/bin/env bash
# Screenshots: region | screen | window. Saves to ~/Pictures/Screenshots,
# copies to the clipboard, and offers "Edit" (swappy) from the notification.
set -u
mode="${1:-region}"
dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$mode" in
    region)
        geom="$(slurp -d)" || exit 0
        grim -g "$geom" "$file"
        ;;
    screen)
        output="$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')"
        grim -o "$output" "$file"
        ;;
    window)
        geom="$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
        [ "$geom" = "null,null nullxnull" ] && exit 1
        grim -g "$geom" "$file"
        ;;
    *) echo "usage: screenshot.sh region|screen|window" >&2; exit 2 ;;
esac

wl-copy < "$file"

if command -v notify-send >/dev/null 2>&1; then
    action="$(notify-send -a Screenshot -i "$file" \
        -A edit=Edit -A open=Open "Screenshot saved" "${file##*/} (copied)")"
    case "$action" in
        edit) command -v swappy >/dev/null 2>&1 && swappy -f "$file" ;;
        open) xdg-open "$file" ;;
    esac
fi
