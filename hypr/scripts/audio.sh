#!/usr/bin/env bash
# On-the-fly audio device switching (Super+A outputs, Super+Shift+A inputs).
# Lists PipeWire devices via pactl, marks the current default, moves existing
# streams over so a mid-call switch takes effect immediately.
set -u
kind="${1:-sink}"   # sink | source

case "$kind" in
    sink)   label="Audio output"; icon=audio-volume-high ;;
    source) label="Microphone";   icon=audio-input-microphone ;;
    *) echo "usage: audio.sh sink|source" >&2; exit 2 ;;
esac

default="$(pactl get-default-$kind)"

# "index<TAB>name<TAB>description" — skip monitor sources
list="$(pactl --format=json list ${kind}s | jq -r \
    '.[] | select(.monitor_source == null or (.name | endswith(".monitor") | not))
         | [.name, (.description // .name)] | @tsv')"
[ -n "$list" ] || { notify-send -a Audio "No ${kind}s found"; exit 1; }

menu=""
while IFS=$'\t' read -r name desc; do
    mark="  "
    [ "$name" = "$default" ] && mark="● "
    menu+="${mark}${desc}"$'\t'"${name}"$'\n'
done <<< "$list"

choice="$(printf '%s' "$menu" | rofi -dmenu -i -p "$label" \
    -display-columns 1 -selected-row 0)" || exit 0
name="${choice##*$'\t'}"
[ -n "$name" ] || exit 0

pactl "set-default-$kind" "$name"

# migrate live streams so calls pick up the new device instantly
if [ "$kind" = sink ]; then
    pactl --format=json list sink-inputs | jq -r '.[].index' | while read -r idx; do
        pactl move-sink-input "$idx" "$name" 2>/dev/null
    done
else
    pactl --format=json list source-outputs | jq -r '.[].index' | while read -r idx; do
        pactl move-source-output "$idx" "$name" 2>/dev/null
    done
fi

desc="${choice#* }"; desc="${desc%%$'\t'*}"
command -v notify-send >/dev/null 2>&1 && \
    notify-send -a Audio -i "$icon" "$label" "$desc"
