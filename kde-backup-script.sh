#!/bin/bash
# Backs up only the theme and font settings for KDE

mkdir -p $(pwd)/kde/gtk-3.0

cp ~/.config/kdeglobals $(pwd)/kde/
cp ~/.config/kwinrc $(pwd)/kde/
cp ~/.config/plasmarc $(pwd)/kde/
cp ~/.config/gtkrc-2.0 $(pwd)/kde/
cp ~/.config/gtk-3.0/settings.ini $(pwd)/kde/gtk-3.0

# Optional - commit to git
# git add .
# git commit -m "Update KDE theme & font config: $(date)"
