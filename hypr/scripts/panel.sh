#!/usr/bin/env bash
# Toggle a settings panel as an applet-style dropdown under the bar
# (clicking its bar icon again, or focusing anything else, dismisses it —
# see lua/rules.lua for placement and lua/applets.lua for the dismissal).
#
#   panel.sh audio       mixer (pwvucontrol, pavucontrol fallback)
#   panel.sh network     connection editor (nm-connection-editor)
#   panel.sh bluetooth   device manager (blueman-manager)
set -u

here="$(cd -P "$(dirname "$0")" && pwd)"

case "${1:-audio}" in
    audio)     candidates="pwvucontrol pavucontrol" ;;
    network)   candidates="nm-connection-editor" ;;
    bluetooth) candidates="blueman-manager" ;;
    media)
        # dedicated media popup (album art + transport controls)
        if pgrep -f "media-panel.py" >/dev/null 2>&1; then
            pkill -f "media-panel.py"
        else
            exec python3 "$here/media-panel.py"
        fi
        exit 0 ;;
    *) echo "usage: panel.sh audio|network|bluetooth|media" >&2; exit 2 ;;
esac

BIN=""
for bin in $candidates; do
    if command -v "$bin" >/dev/null 2>&1; then BIN="$bin"; break; fi
done
if [ -z "$BIN" ]; then
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -a Panel "Not installed" "none of: $candidates"
    exit 1
fi

# match on the full command line: -x compares against the 15-char comm
# field and silently never matches longer names (nm-connection-editor)
if pgrep -f "(^|/)$BIN( |\$)" >/dev/null 2>&1; then
    pkill -f "(^|/)$BIN( |\$)"
else
    exec "$BIN"
fi
