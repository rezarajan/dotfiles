#!/usr/bin/env bash
# Wallpaper switching with animated transitions (swww) and a rofi
# thumbnail-grid picker — the carousel.
#
#   wallpaper.sh pick        rofi grid of every wallpaper, click to apply
#   wallpaper.sh next|prev   cycle through the collection
#   wallpaper.sh random      random pick
#   wallpaper.sh set <path>  apply a specific image
#   wallpaper.sh restore     re-apply the current wallpaper (session start)
#
# Sources: the repo's wallpapers/ plus ~/Pictures/wallpapers if it exists.
# The active image is mirrored to ~/.config/hypr/wallpaper.jpg so hyprlock's
# blurred background always matches.
set -u
here="$(cd -P "$(dirname "$0")" && pwd)"
repo="$(cd -P "$here/../.." && pwd)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/gruvbox"
CURRENT_FILE="$STATE_DIR/wallpaper"
mkdir -p "$STATE_DIR"

collect() {
    for dir in "$repo/wallpapers" "$HOME/Pictures/wallpapers"; do
        [ -d "$dir" ] && find "$dir" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort
    done
}

# swww was renamed upstream to awww; support both
swww_cli() { command -v swww 2>/dev/null || command -v awww 2>/dev/null; }
swww_running() { pgrep -x swww-daemon >/dev/null 2>&1 || pgrep -x awww-daemon >/dev/null 2>&1; }

apply() {
    local img="$1"
    [ -f "$img" ] || return 1
    printf '%s\n' "$img" > "$CURRENT_FILE"
    cp -f "$img" "$CONF/hypr/wallpaper.jpg"
    if swww_running; then
        "$(swww_cli)" img "$img" \
            --transition-type grow --transition-pos center \
            --transition-duration 1.2 --transition-fps 60
    elif pgrep -x swaybg >/dev/null 2>&1 || command -v swaybg >/dev/null 2>&1; then
        pkill -x swaybg 2>/dev/null
        (swaybg -i "$CONF/hypr/wallpaper.jpg" -m fill >/dev/null 2>&1 &)
    elif pgrep -x hyprpaper >/dev/null 2>&1; then
        hyprctl hyprpaper reload ",$CONF/hypr/wallpaper.jpg" >/dev/null 2>&1
    fi
}

current() { cat "$CURRENT_FILE" 2>/dev/null; }

cycle() { # cycle <+1|-1>
    local files cur idx n
    mapfile -t files < <(collect)
    n=${#files[@]}
    [ "$n" -gt 0 ] || exit 1
    cur="$(current)"
    idx=0
    for i in "${!files[@]}"; do
        [ "${files[$i]}" = "$cur" ] && idx=$i && break
    done
    idx=$(( (idx + $1 + n) % n ))
    apply "${files[$idx]}"
}

case "${1:-pick}" in
    pick)
        cur="$(current)"
        chosen="$(collect | while IFS= read -r f; do
            name="$(basename "$f")"
            mark=""
            [ "$f" = "$cur" ] && mark="● "
            printf '%s%s\0icon\x1f%s\n' "$mark" "$name" "$f"
        done | rofi -dmenu -i -p "Wallpaper" -theme wallpaper)" || exit 0
        chosen="${chosen#● }"
        collect | while IFS= read -r f; do
            [ "$(basename "$f")" = "$chosen" ] && { bash "$0" set "$f"; break; }
        done
        ;;
    next) cycle 1 ;;
    prev) cycle -1 ;;
    random)
        mapfile -t files < <(collect)
        [ ${#files[@]} -gt 0 ] && apply "${files[RANDOM % ${#files[@]}]}"
        ;;
    set)
        img="${2:?usage: wallpaper.sh set <path>}"
        img="${img#file://}"   # dolphin service menus may hand over a URL
        if apply "$img"; then
            command -v notify-send >/dev/null 2>&1 && \
                notify-send -a Wallpaper -i preferences-desktop-wallpaper \
                    "Wallpaper updated" "$(basename "$img") — desktop and lock screen"
        else
            command -v notify-send >/dev/null 2>&1 && \
                notify-send -a Wallpaper -u critical "Could not set wallpaper" "$img"
        fi ;;
    restore)
        img="$(current)"
        [ -f "$img" ] || img="$CONF/hypr/wallpaper.jpg"
        [ -f "$img" ] && apply "$img"
        ;;
    *) echo "usage: wallpaper.sh pick|next|prev|random|set <path>|restore" >&2; exit 2 ;;
esac
