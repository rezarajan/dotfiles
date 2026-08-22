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

Colors are **generated**, never hand-written. The palette lives in
`home-manager/desktop/kvantum/tools/palette.py`; running `generate_all.py`
(or just `hyprland_gen.py`) re-emits:

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

- **Super+F1** — searchable keybinding cheatsheet (live from `hyprctl binds`).
- **Video calls**: screen sharing runs through xdg-desktop-portal-hyprland
  (window/output picker). **Super+A / Super+Shift+A** switch speaker /
  microphone mid-call (streams migrate immediately); clicking the waybar
  volume module opens pavucontrol.
- **Super+Shift+R** toggles screen recording (wf-recorder); the bar shows a
  red ● REC chip while active.
- **Super+V** clipboard history, **Super+Shift+S** region screenshot.

## Packages (Arch names)

```
hyprland waybar swaync rofi-wayland wlogout hyprpaper swaybg hypridle hyprlock
hyprpolkitagent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
pipewire wireplumber pipewire-pulse pavucontrol
grim slurp swappy wf-recorder cliphist wl-clipboard libnotify
brightnessctl playerctl jq
inter-font ttf-jetbrains-mono ttf-nerd-fonts-symbols
qt6-wayland kvantum polkit
```

`wlogout` is AUR-only on Arch (`yay -S wlogout`). Tested end-to-end on
Hyprland 0.56.2 in a VirtualBox VM (waybar, rofi, swaync, theming toggle,
screenshots, recording, portals); hyprpaper/hyprlock need a real GPU — in
VMs the session falls back to swaybg automatically, and swaylock can stand
in for hyprlock.

Deploy by symlinking this directory to `~/.config/hypr` (plus `waybar`,
`rofi`, `swaync`, `wlogout` similarly), or via the
`home-manager/desktop/hyprland.nix` module.
