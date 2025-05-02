#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if Waybar is running
if pgrep -x "waybar" > /dev/null; then
    # If Waybar is running, kill it
    pkill waybar
else
    # If Waybar is not running, start it with the desired config and style
    waybar -c ~/.config/waybar/themes/catppuccin/config -s ~/.config/waybar/themes/catppuccin/style.css
fi
