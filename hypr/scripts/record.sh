#!/usr/bin/env bash
# Screen recording toggle (wf-recorder). Second invocation stops the
# recording. The waybar `custom/recording` module watches the state file
# (signal RTMIN+8) so the bar shows a red dot while recording.
#
#   record.sh toggle            whole focused output
#   record.sh toggle region     slurp-selected region
#   record.sh toggle audio      whole output + default mic
set -u
STATE="${XDG_RUNTIME_DIR:-/tmp}/gruvbox-recording"
dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"

poke_waybar() { pkill -SIGRTMIN+8 waybar 2>/dev/null; }

if [ -f "$STATE" ]; then
    pkill -INT -x wf-recorder 2>/dev/null
    file="$(cat "$STATE")"
    rm -f "$STATE"
    poke_waybar
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -a Recorder -i media-playback-stop \
            "Recording stopped" "${file##*/}"
    exit 0
fi

mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
args=(-f "$file")

case "${2:-}" in
    region)
        geom="$(slurp -d)" || exit 0
        args+=(-g "$geom")
        ;;
    audio)
        args+=(--audio)
        ;;
esac

printf '%s\n' "$file" > "$STATE"
poke_waybar
command -v notify-send >/dev/null 2>&1 && \
    notify-send -a Recorder -i media-record "Recording started" "${file##*/}"

wf-recorder "${args[@]}"
# wf-recorder exited on its own (error or INT from elsewhere): clear state
rm -f "$STATE"
poke_waybar
