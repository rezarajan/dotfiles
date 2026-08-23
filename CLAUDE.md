# Agent guide — dotfiles (Gruvbox Dragon desktop)

Structured knowledge for AI agents (and humans) developing this repo.
Read this before touching anything; every rule below was earned.

## What this repo is

One design system ("Gruvbox Dragon", acrylic, dark+light) rendered onto
two desktops that must stay visually identical:

- **KDE Plasma** — managed by `home-manager/desktop/kde-gruvbox.nix`
- **Hyprland (≥ 0.55, Lua config)** — `hypr/` + `waybar/` + `rofi/` +
  `swaync/` + `wlogout/`; docs in `hypr/readme.md`

Deployment: home-manager (with nixGL shims on non-NixOS) or plain
symlinks; see `hypr/readme.md` → Install.

## Non-negotiable design rules

1. **Single source of truth for color.** Palettes live in
   `home-manager/desktop/kvantum/tools/palettes/`; `palette.py` selects
   one via `ACTIVE_PALETTE`. NEVER hardcode a hex value in any themed
   file — extend `hyprland_gen.py` (or the other `*_gen.py`) instead and
   run `generate_all.py`.
2. **Light/dark is one switch.** `hypr/scripts/theme-mode.sh` must flip
   *everything* (waybar/rofi/swaync tokens, GTK colors.css +
   settings.ini, kdeglobals color groups, Kvantum, cursor, portal
   gsettings, hyprlock). If you add a themed surface, wire it in there
   and emit per-mode tokens from the generator.
3. **Holistic UX, KDE/GNOME as the bar** (the user's hard requirement):
   hover = brief detail, click = full visual panel; one intent = one
   isolated interface (media at the media chip, never inside the
   notification center); no boxy elements — pills/circles/12px radii; no
   walls of text — icons and hierarchy; every popup on the shared
   acrylic material. Before delivering ask: "what would KDE/GNOME show
   here, and where would a user look for it?"
4. **No function keys in binds** (40% keyboards). XF86 media keys are
   fine (hardware keys).
5. **Icons must be vector.** Notification icons use `-symbolic` names
   only (SVG by definition); bar icons are font glyphs; never let an
   icon lookup land on a small PNG.

## Architecture quick map

- `hypr/hyprland.lua` requires `hypr/lua/*.lua` in order; each file runs
  in an isolated scope (Hyprland's patched `require`).
- Applet system: `scripts/panel.sh <audio|network|bluetooth|media|calendar>`
  toggles panels; `lua/rules.lua` floats them (acrylic opacity 0.92 +
  slide animation) under the bar; `lua/applets.lua` dismisses them on
  focus loss AND click-outside (a non_consuming `mouse:272` bind doing
  cursor-vs-box math; the top 40px bar strip is exempt).
- Custom GTK applets (`media-panel.py`, `calendar-panel.py`) are normal
  windows whose app-id joins the applet class lists.
- Bar: waybar with **custom workspace pill modules** (`ws-status.sh` +
  `lua/bar.lua` event pokes, signal 7) — see pitfalls for why.
- Watchers: `net-watch.sh` (captive portal → actionable notification),
  `privacy-status.sh` (mic/camera chip), `osd.sh` (volume/brightness
  progress notifications).

## Development workflow

1. Edit on the Windows host; validate BEFORE deploying:
   - Lua: run the `hl` stub test (see scratchpad `hl_stub_test.lua`
     pattern: permissive callable/indexable stub + duplicate-bind check)
     or minimally `luac -p`.
   - `bash -n` every touched script. Python: `ast.parse`. JSON(C):
     strip `//` comments then `json.loads`.
2. Deploy to the test VM (`hypr-test` VirtualBox, Arch, user/pass
   `arch`) — ALWAYS via `git archive` from the jj working-copy commit:
   `jj st` (snapshot) → `git -c core.autocrlf=false archive <commit> …`.
   NEVER pscp working-tree files (CRLF) and never forget `-c
   core.autocrlf=false` (git archive smudges EOLs otherwise).
3. Restart the affected component in the VM (waybar needs an explicit
   restart to pick up config — a deploy without it once shipped a
   "fixed" bug that wasn't).
4. **Verify visually**: `VBoxManage controlvm hypr-test screenshotpng` —
   a feature is not done until a screenshot proves it. Interact via
   `hyprctl dispatch 'hl.dsp...'` over SSH and `VBoxManage controlvm
   keyboardputstring`/`keyboardputscancode` (no mouse injection exists).
5. Commit with jj, conventional-commit style, one logical change each.
   GPG signing needs the user present (`jj sign -r 'main..@'` after they
   unlock the key).

## Pitfalls (each of these bit us once)

**Hyprland 0.55+ / Lua**
- Legacy dispatchers are GONE: `hyprctl dispatch workspace 2` errors —
  everything is `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'`.
  Waybar's built-in hyprland workspace module still sends the old
  protocol → its clicks silently no-op (why the pills are custom).
- Bind/event callbacks run on the compositor loop — never block.
- `require("lua/x")` paths are relative to hyprland.lua; missing modules
  throw (pcall the optional `lua/local`).
- Window objects are userdata: fields are `.at.x/.at.y/.size.x/.size.y`,
  `.class`; `pairs()` does not work on them.
- Replacing config files with tar while Hyprland runs fires the
  file-watcher mid-extract → transient "config error" banner. Reload +
  `hyprctl dismissnotify` after every deploy.

**GTK / theming**
- Breeze-GTK ignores standard named colors: it reads `*_breeze` twins
  plus backdrop/insensitive/titlebar variants — the generator emits both
  sets. Without them GTK apps keep stock Breeze colors.
- The user gtk.css loads at USER priority (800) which BEATS application
  CSS (600). App-level styling that must win needs
  `Gtk.STYLE_PROVIDER_PRIORITY_USER + 100`.
- GTK3 CSS rejects `#rrggbbaa` — emit `rgba(r,g,b,a)`.
- PyGObject initializes GTK **at import**: `GLib.set_prgname()` (the
  Wayland app-id!) must run before `from gi.repository import Gtk`, and
  Gdk/GdkPixbuf need explicit `gi.require_version` or the import crashes.
- KDE apps: with `QT_QPA_PLATFORMTHEME=kde` (plasma-integration) they
  read kdeglobals exactly like under Plasma. kdeglobals *inlines*
  `[Colors:*]` groups which override the scheme name — switching
  schemes means swapping those groups wholesale (see theme-mode.sh awk).
  Broadcast `org.kde.KGlobalSettings.notifyChange` for live restyle.
- `kwriteconfig6`/dbus tools can hang on an odd session bus — always
  `timeout 5` them.
- Icon caches: `~/.cache/icon-cache.kcache` makes KDE apps keep stale
  (breeze) icons after installing a theme — delete it.
- `kvantummanager --set` may open its GUI — write
  `~/.config/Kvantum/kvantum.kvconfig` directly.

**Shell / tools**
- `pgrep/pkill -x` silently never matches names > 15 chars
  (nm-connection-editor!) — match full cmdline with anchored `-f`.
- Scripts run from `~/.config/hypr` (a symlink): compute repo paths with
  `cd -P` or asset links point into nothing.
- util-linux `cal -h` prints HELP, not "no highlight"; piped cal is
  already plain.
- Chromium exposes ONE MPRIS player per browser process regardless of
  tab count (tabs aggregate; the browser re-routes on pause). Same for
  plasma/GNOME applets — don't chase per-tab players.
- The generators must run under UTF-8 (`generate_all.py` re-execs with
  PYTHONUTF8=1); a cp1252 Windows run once corrupted em-dashes across
  the committed artifacts.

**VM specifics (llvmpipe / VirtualBox)**
- hyprpaper and hyprlock hard-fail GL init — hyprpaper can stay alive
  WITHOUT ever mapping a layer (check `hyprctl layers`, not the
  process); session-start falls back to swaybg, lock.sh to a composed
  swaylock (auto-armed by LIBGL_ALWAYS_SOFTWARE).
- Sustained video playback can wedge the render loop while IPC stays
  half-alive; reboot the VM. Real GPUs are unaffected.
- Windows' bundled OpenSSH can't KEX with the guest's OpenSSH 10 — use
  plink with a pinned `-hostkey`.
- Killing the active lockscreen leaves Hyprland's crashed-lockscreen
  state: `hyprctl eval 'hl.clear_crashed_lockscreen()'`.

**jj / repo (Windows host)**
- `working-copy.eol-conversion = "input-output"` is set repo-level;
  without it every file shows modified (autocrlf checkout).
- Never commit symlink-bearing artifacts from Windows (cursor raster
  aliases) — they can't round-trip; rasters build on Linux via
  install-theme-assets.sh instead.
- `__pycache__/` is gitignored; don't re-track it.
