#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOGGLE_FILE="$HOME/.cache/waybar-disabled"
LAUNCH_SCRIPT="$SCRIPT_DIR/launch.sh"

# Toggle Waybar
if [ -f "$TOGGLE_FILE" ]; then
    rm "$TOGGLE_FILE"
else
    touch "$TOGGLE_FILE"
fi

# Refresh Waybar
$LAUNCH_SCRIPT
