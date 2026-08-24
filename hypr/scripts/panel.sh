#!/usr/bin/env bash
# Toggle a settings panel as an applet-style dropdown under the bar
# (clicking its bar icon again, or focusing anything else, dismisses it —
# see lua/rules.lua for placement and lua/applets.lua for the dismissal).
#
#   panel.sh audio       mixer (pwvucontrol, pavucontrol fallback)
#   panel.sh network     connection editor (nm-connection-editor)
#   panel.sh bluetooth   device manager (blueman-manager)
#   panel.sh displays    monitor presets (displays-panel.py)
set -u

here="$(cd -P "$(dirname "$0")" && pwd)"

# Pick an interpreter that can actually reach GTK. pygobject3 on its own
# is not enough — gi.require_version("Gtk", "3.0") needs the GTK typelibs
# too, and the nix python3.withPackages(pygobject3) env ships the former
# without the latter while shadowing the distro python in PATH. A bare
# `python3` here therefore dies with "Namespace Gtk not available" on
# exactly the machines the applets are meant to run on. Probe instead,
# and cache the answer for the session: importing gi costs ~100ms and a
# popup should not pay it twice.
gtk_python() {
    local cache="${XDG_RUNTIME_DIR:-/tmp}/gruvbox-gtk-python" py
    if [ -s "$cache" ]; then
        read -r py < "$cache"
        if [ -x "$py" ] || command -v "$py" >/dev/null 2>&1; then
            printf '%s' "$py"; return 0
        fi
    fi
    for py in "${GRUVBOX_PYTHON:-}" python3 /usr/bin/python3; do
        [ -n "$py" ] || continue
        command -v "$py" >/dev/null 2>&1 || continue
        # require_version only resolves the typelib; it does not import
        # GTK, which keeps the probe cheap
        if "$py" -c 'import gi; gi.require_version("Gtk", "3.0")' >/dev/null 2>&1; then
            printf '%s' "$py" > "$cache"
            printf '%s' "$py"; return 0
        fi
    done
    return 1
}

# run_panel <script.py> — toggle a python applet off, or start it
run_panel() {
    local script="$1" py
    if pgrep -f "$script" >/dev/null 2>&1; then
        pkill -f "$script"
        exit 0
    fi
    if ! py="$(gtk_python)"; then
        command -v notify-send >/dev/null 2>&1 && notify-send -a Panel \
            "No GTK-capable python" \
            "Install python-gobject with the GTK 3 typelibs."
        exit 1
    fi
    exec "$py" "$here/$script"
}

case "${1:-audio}" in
    audio)     candidates="pwvucontrol pavucontrol" ;;
    network)   candidates="nm-connection-editor" ;;
    bluetooth) candidates="blueman-manager" ;;
    media)
        # dedicated media popup (album art + transport controls)
        run_panel media-panel.py ;;
    calendar)
        # month-view calendar with Gregorian + Hijri
        run_panel calendar-panel.py ;;
    displays)
        # monitor presets + per-output controls
        run_panel displays-panel.py ;;
    *) echo "usage: panel.sh audio|network|bluetooth|media|calendar|displays" >&2; exit 2 ;;
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
