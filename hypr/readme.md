# Hyprland — Gruvbox Dragon

Lua configuration for Hyprland ≥ 0.55 (the release that replaced hyprlang
with the typed `hl` Lua API). Designed to feel like the KDE session this
repo also ships: same palette, fonts, radii, animation speed and keybinding
muscle memory, generated from the same single source of truth.

## Layout

```
hypr/
├── hyprland.lua        entry point — requires the modules below, in order
├── lua/
│   ├── palette.lua     GENERATED color tokens (do not edit — see below)
│   ├── theme.lua       design tokens + active dark/light variant
│   ├── apps.lua        default applications, script paths
│   ├── env.lua         environment variables
│   ├── monitors.lua    catch-all monitor default
│   ├── options.lua     general / decoration / input / layouts
│   ├── animations.lua  curves + animation tree
│   ├── rules.lua       window / layer / workspace rules
│   ├── binds.lua       keybindings
│   ├── autostart.lua   session services (hl.on "hyprland.start")
│   └── local.lua.example  per-machine overrides → copy to local.lua (gitignored)
├── theme/              GENERATED hyprlock color tokens (dark/light)
├── scripts/            theme-mode, menu, screenshot, record, audio, …
├── hypridle.conf · hyprlock.conf · hyprpaper.conf
└── readme.md
```

Each module runs in its own scope (Hyprland's patched `require`), so a
runtime error in one file leaves the rest of the session working. The
config hot-reloads on save; `hyprctl configerrors` shows problems.

## Theming — one source of truth

Colors are **generated**, never hand-written. Palettes are swappable
modules in `home-manager/desktop/kvantum/tools/palettes/`; switching the
whole desktop to a new one is three steps:

1. copy `palettes/gruvbox_dragon.py` to `palettes/<name>.py` and edit the
   hex tables (dark + light variants, accents, opacities)
2. set `ACTIVE_PALETTE = "<name>"` in `tools/palette.py`
3. run `tools/generate_all.py`, then `theme-mode.sh apply` (Hyprland) or
   `home-manager switch` (KDE machines)

`generate_all.py` re-emits every palette-derived artifact, including:

- `hypr/lua/palette.lua` (borders, groupbar, misc colors)
- `waybar/colors-{dark,light}.css`, `rofi/colors-{dark,light}.rasi`,
  `swaync/colors-{dark,light}.css`, `wlogout/colors-{dark,light}.css`
- `hypr/theme/hyprlock-{dark,light}.conf`

`scripts/theme-mode.sh toggle|set|apply` switches dark/light: it writes
`~/.local/state/gruvbox/mode`, copies the matching token files over the
gitignored `colors.*` active copies, broadcasts the portal color-scheme via
gsettings (GTK apps + ghostty follow instantly), switches the Kvantum theme
(Qt apps) and cursor, then reloads Hyprland, waybar and swaync in place.
Bound to **Super+Shift+W**.

## Daily driving

- **Super+/** — searchable keybinding cheatsheet (live from `hyprctl binds`).
- **Video calls**: screen sharing runs through xdg-desktop-portal-hyprland
  (window/output picker). **Super+A / Super+Shift+A** switch speaker /
  microphone mid-call (streams migrate immediately). A privacy chip
  appears in the bar whenever an app holds the microphone or camera
  (tooltip names the apps; click opens the mixer on the live streams).
- **Bar applets**: the volume and bluetooth icons drop their settings
  panel down from the bar (dismissed on focus loss or click-outside, like
  plasma popups); the network icon opens a plasma-nm-style rofi menu
  (Wi-Fi list with signal strength, one-click connect with password
  prompt, Wi-Fi toggle, VPN activation — right-click for the connection
  editor). A watcher raises a KDE-style "Sign-in required" notification
  with an "Open sign-in page" button on captive-portal networks. The
  sun/moon button toggles light/dark.
- **Super+Shift+R** toggles screen recording (wf-recorder); the bar shows a
  red ● REC chip while active.
- **Super+V** clipboard history, **Super+Shift+S** region screenshot.

## Packages (Arch names)

```
hyprland waybar swaync rofi-wayland swww swaybg hypridle hyprlock swaylock
hyprpolkitagent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
pipewire wireplumber pipewire-pulse pavucontrol
grim slurp swappy wf-recorder cliphist wl-clipboard libnotify
brightnessctl playerctl jq psmisc imagemagick python-gobject
networkmanager nm-connection-editor network-manager-applet blueman
inter-font ttf-jetbrains-mono ttf-nerd-fonts-symbols
qt6-wayland plasma-integration qt6ct kvantum breeze breeze-gtk breeze-icons polkit
```

Application theming without KDE: `scripts/install-theme-assets.sh` links
the repo's cursors, GTK theme pair, Kvantum themes and KDE color schemes
into `~/.local/share` / `~/.config/Kvantum` (add `--icons` to fetch the
Gruvbox-Plus icon pack); `theme-mode.sh` then maintains the pieces KDE
used to own — the GTK `colors.css` named-color sheet, `qt6ct.conf`
(Kvantum style + icons) and the `kdeglobals` color scheme (edited via
`kwriteconfig6 --notify` when the file is KDE-managed, installed from a
generated template otherwise). GTK apps, Chromium, ghostty, and Qt/KDE
apps like Dolphin all follow the same palette and the light/dark toggle.

The audio applet prefers `pwvucontrol` when present (AUR on Arch,
`pwvucontrol` in nixpkgs) and falls back to `pavucontrol`.
The session menu (lock/logout/power) is rofi-based (`scripts/power-menu.sh`,
Super+Backspace or the bar's ⏻ button); the `wlogout/` config remains for
those who prefer it (AUR: `yay -S wlogout`). Tested end-to-end on
Hyprland 0.56.2 in a VirtualBox VM (waybar, rofi, swaync, theming toggle,
screenshots, recording, portals); hyprpaper/hyprlock need a real GPU — in
VMs the session falls back to swaybg automatically, and swaylock can stand
in for hyprlock.

## Install

### With home-manager (NixOS or any distro)

Enable the module in `home-manager/flake.nix` (already imported) and set:

```nix
cascadura.hyprland.enable = true;    # config symlinks
cascadura.hyprland.packages = true;  # companion packages from nixpkgs
```

On non-NixOS hosts every GUI/GL package is wrapped with **nixGL**
(`../nixgl.nix` configures `targets.genericLinux.nixGL`), so hyprlock,
hyprpaper, swww, waybar and friends find the host's GL drivers. Hyprland
itself still comes from the distro (`pacman -S hyprland`) — a nix-built
compositor session under nixGL is fragile.

### Manual install (no Nix)

1. Install the packages from the list above (Arch names; `wlogout` and
   `pwvucontrol` are AUR and optional).
2. Clone this repo to `~/git/dotfiles` and symlink the configs:

   ```sh
   for d in hypr waybar rofi swaync wlogout; do
     ln -sfn ~/git/dotfiles/$d ~/.config/$d
   done
   mkdir -p ~/.config/xdg-desktop-portal
   ln -sf ~/git/dotfiles/xdg-desktop-portal/hyprland-portals.conf \
     ~/.config/xdg-desktop-portal/hyprland-portals.conf
   ```

3. Link the theme assets (cursors, GTK/Kvantum themes, KDE color
   schemes, Dolphin integration) and fetch the icon pack:

   ```sh
   bash ~/git/dotfiles/hypr/scripts/install-theme-assets.sh --icons
   ```

4. Log into Hyprland (via a display manager, `start-hyprland` from a
   tty, or an autologin getty). `session-start.sh` runs everything else:
   theme application, bar, notifications, wallpaper, idle, watchers.
5. Per-machine monitors/env: copy `hypr/lua/local.lua.example` to
   `hypr/lua/local.lua` and edit (gitignored).
