#!/usr/bin/env bash
# Backs up KDE/Plasma theme, font, panel, widget, shortcut, and KWin settings

set -u

BACKUP_DIR="$(pwd)/kde"

mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/gtk-3.0"
mkdir -p "$BACKUP_DIR/config"
mkdir -p "$BACKUP_DIR/local-share"

copy_file() {
  local src="$1"
  local dest="$2"

  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "Copied: $src"
  else
    echo "Skipped missing file: $src"
  fi
}

copy_dir() {
  local src="$1"
  local dest="$2"

  if [[ -d "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    echo "Copied directory: $src"
  else
    echo "Skipped missing directory: $src"
  fi
}

# Core KDE appearance/theme/font settings
copy_file "$HOME/.config/kdeglobals" "$BACKUP_DIR/config/kdeglobals"
copy_file "$HOME/.config/plasmarc" "$BACKUP_DIR/config/plasmarc"
copy_file "$HOME/.config/gtkrc-2.0" "$BACKUP_DIR/config/gtkrc-2.0"
copy_file "$HOME/.config/gtk-3.0/settings.ini" "$BACKUP_DIR/config/gtk-3.0/settings.ini"
copy_file "$HOME/.config/gtk-4.0/settings.ini" "$BACKUP_DIR/config/gtk-4.0/settings.ini"

# KWin: window rules, effects, compositing, borders, tiling-related settings
copy_file "$HOME/.config/kwinrc" "$BACKUP_DIR/config/kwinrc"
copy_file "$HOME/.config/kwinrulesrc" "$BACKUP_DIR/config/kwinrulesrc"

# Global shortcuts, including KWin shortcuts such as close window, tiling, etc.
copy_file "$HOME/.config/kglobalshortcutsrc" "$BACKUP_DIR/config/kglobalshortcutsrc"
copy_file "$HOME/.config/khotkeysrc" "$BACKUP_DIR/config/khotkeysrc"

# Plasma shell: panels, widgets, Global Menu, applets, layout
copy_file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$BACKUP_DIR/config/plasma-org.kde.plasma.desktop-appletsrc"
copy_file "$HOME/.config/plasmashellrc" "$BACKUP_DIR/config/plasmashellrc"
copy_file "$HOME/.config/plasma-localerc" "$BACKUP_DIR/config/plasma-localerc"

# Input and lock-screen settings that often matter in desktop workflows
copy_file "$HOME/.config/kcminputrc" "$BACKUP_DIR/config/kcminputrc"
copy_file "$HOME/.config/kscreenlockerrc" "$BACKUP_DIR/config/kscreenlockerrc"

# User-installed KWin scripts, effects, decorations, and Plasma widgets
copy_dir "$HOME/.local/share/kwin" "$BACKUP_DIR/local-share/kwin"
copy_dir "$HOME/.local/share/plasma" "$BACKUP_DIR/local-share/plasma"
copy_dir "$HOME/.local/share/kpackage" "$BACKUP_DIR/local-share/kpackage"
copy_dir "$HOME/.local/share/kservices5" "$BACKUP_DIR/local-share/kservices5"

# Optional: KDE Store / package metadata used by some widgets and themes
copy_dir "$HOME/.local/share/aurorae" "$BACKUP_DIR/local-share/aurorae"
copy_dir "$HOME/.local/share/color-schemes" "$BACKUP_DIR/local-share/color-schemes"
copy_dir "$HOME/.local/share/icons" "$BACKUP_DIR/local-share/icons"

echo
echo "KDE/Plasma backup complete: $BACKUP_DIR"

# Optional - commit to git
# git add .
# git commit -m "Update KDE/Plasma config: $(date)"
