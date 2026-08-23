#!/usr/bin/env bash
# Link the repo's Gruvbox Dragon theme assets into the home directory for
# machines NOT managed by home-manager (test VMs, fresh installs). On a
# home-manager machine these already exist via the nix profile, and this
# script leaves anything it didn't create alone.
#
#   install-theme-assets.sh          link cursors/gtk/kvantum/color-schemes
#   install-theme-assets.sh --icons  also fetch the Gruvbox-Plus icon pack
set -u
# resolve PHYSICAL paths: ~/.config/hypr is usually a symlink into the
# repo, and the repo root must be computed from the real location
here="$(cd -P "$(dirname "$0")" && pwd)"
repo="$(cd -P "$here/../.." && pwd)"       # <repo>/hypr/scripts -> <repo>
desktop="$repo/home-manager/desktop"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"

link() { # link <src> <dst> — only if dst is absent or already ours
    local src="$1" dst="$2"
    if [ ! -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$(dirname "$dst")"
        ln -sfn "$src" "$dst"
        echo "  $dst -> $src"
    fi
}

echo "cursors:"
# The repo ships the SVG (cursors_scalable) sources; loaders that predate
# SVG cursors — including Hyprland's own xcursor parser — need classic
# rasters, so build them once here when the tools are available.
if [ ! -d "$desktop/cursors/Gruvbox-Dragon-Cursors/cursors" ] \
        && command -v xcursorgen >/dev/null 2>&1 \
        && command -v magick >/dev/null 2>&1 \
        && command -v python3 >/dev/null 2>&1; then
    echo "  building raster cursors (one-time)..."
    (cd "$desktop/kvantum/tools" && python3 cursor_gen.py >/dev/null 2>&1) \
        || echo "  raster build failed — SVG-aware loaders still work" >&2
fi
for theme in Gruvbox-Dragon-Cursors Gruvbox-Dragon-Cursors-Light; do
    link "$desktop/cursors/$theme" "$DATA/icons/$theme"
    link "$desktop/cursors/$theme" "$HOME/.icons/$theme"   # legacy xcursor path
done

echo "gtk themes:"
link "$desktop/gtk/themes/Gruvbox-Dragon" "$DATA/themes/Gruvbox-Dragon"
link "$desktop/gtk/themes/Gruvbox-Dragon-Light" "$DATA/themes/Gruvbox-Dragon-Light"

echo "kvantum:"
link "$desktop/kvantum/Gruvbox" "$CONF/Kvantum/Gruvbox"
link "$desktop/kvantum/GruvboxDark" "$CONF/Kvantum/GruvboxDark"

echo "kde color schemes:"
link "$desktop/color-schemes/GruvboxDragon.colors" "$DATA/color-schemes/GruvboxDragon.colors"
link "$desktop/color-schemes/GruvboxDragonLight.colors" "$DATA/color-schemes/GruvboxDragonLight.colors"

echo "gtk acrylic overlay:"
for v in 3 4; do
    mkdir -p "$CONF/gtk-$v.0"
    cp -f "$desktop/gtk/gruvbox-acrylic-gtk$v.css" "$CONF/gtk-$v.0/gruvbox-acrylic.css"
    echo "  $CONF/gtk-$v.0/gruvbox-acrylic.css"
done

if [ "${1:-}" = "--icons" ] && [ ! -d "$DATA/icons/Gruvbox-Plus-Dark" ]; then
    # pinned to the same revision kde-gruvbox.nix builds from
    rev=a9b19b95ec653fa80574fbd7ffefc2d03abfc991
    echo "fetching Gruvbox-Plus icon pack ($rev)..."
    tmp="$(mktemp -d)"
    if curl -sL "https://github.com/SylEleuth/gruvbox-plus-icon-pack/archive/$rev.tar.gz" \
            | tar -xz -C "$tmp"; then
        mkdir -p "$DATA/icons"
        cp -r "$tmp/gruvbox-plus-icon-pack-$rev/Gruvbox-Plus-Dark" "$DATA/icons/"
        cp -r "$tmp/gruvbox-plus-icon-pack-$rev/Gruvbox-Plus-Light" "$DATA/icons/"
        echo "  installed Gruvbox-Plus-Dark / Gruvbox-Plus-Light"
    else
        echo "  download failed — icon themes skipped" >&2
    fi
    rm -rf "$tmp"
fi

echo "done."
