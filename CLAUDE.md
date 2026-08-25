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
   Commits are GPG-signed via jj's own `signing.*` config (backend `gpg`,
   key `070B6AA734C19166`, behavior `own`) — jj does NOT read git's
   `commit.gpgsign`/`user.signingkey`, so a machine with git signing set
   up can still commit unsigned through jj. `behavior = "own"` signs on
   commit; `jj sign -r 'main..@'` backfills existing ones. gpg-agent
   normally has the passphrase cached and neither prompts, but after a
   fresh login or a cache expiry the user must be present to unlock.

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
- `hyprctl keyword` is dead too: it answers "keyword can't work with
  non-legacy parsers. Use eval." Runtime config changes go through
  `hyprctl eval 'hl.monitor({...})'`. This is why **nwg-displays cannot
  be used** for monitor management (it applies via `hyprctl keyword
  monitor`) — wdisplays drives `zwlr_output_manager_v1` instead and works,
  but leaves no monitor rule behind, so `scripts/monitors.sh save`
  persists the result into `lua/monitors-local.lua`.
- Monitor rules ACCUMULATE. Emit the full field set (`mode`, `position`,
  `scale`, `mirror`, `disabled`) on every `hl.monitor` call: omit `mirror`
  and an earlier mirror stays in force, pinning the output on top of its
  source whatever `position` says. `hl.monitor` validates field names, so
  a typo errors rather than passing silently.
- `mode = "preferred"` takes the EDID's nominated mode, which on
  high-refresh panels is routinely the 60 Hz fallback (an AW3423DW sat at
  59.97 Hz on a 175 Hz screen). Use `highrr`.
- `hyprctl eval` prints only errors — its "ok" is an ack, NOT your return
  value. Never conclude anything from "ok"; a `pcall` inside eval prints
  "ok" whether or not the call failed.
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
- In `gtk-tweaks.css`, tint widgets with `background-color`, never the
  `background` SHORTHAND: it resets `background-clip` to `border-box`.
  Adwaita and Breeze size scrollbar sliders with a fat *transparent*
  border plus `background-clip: padding-box`, so the shorthand paints
  that border too — a 3px overlay indicator became a 19px slab in every
  GTK app (ghostty most visibly). Same reason not to restate
  `min-width`/`min-height` there: the theme owns scrollbar geometry.
- PyGObject initializes GTK **at import**: `GLib.set_prgname()` (the
  Wayland app-id!) must run before `from gi.repository import Gtk`, and
  Gdk/GdkPixbuf need explicit `gi.require_version` or the import crashes.
- KDE apps: with `QT_QPA_PLATFORMTHEME=kde` (plasma-integration) they
  read kdeglobals exactly like under Plasma. kdeglobals *inlines*
  `[Colors:*]` groups which override the scheme name — switching
  schemes means swapping those groups wholesale (see theme-mode.sh awk).
  Broadcast `org.kde.KGlobalSettings.notifyChange` for live restyle.
- **Never put nixpkgs' `plasma-integration` on `QT_PLUGIN_PATH` on a
  non-NixOS host.** `qt.enable` puts the whole profile on that path, so the
  DISTRO's Qt apps load nixpkgs' `KDEPlasmaPlatformTheme6.so` and end up
  with two different libQt6Gui in one process. It stays invisible while
  both Qts match, then the distro moves one point release ahead (Arch
  6.11.2 vs nixpkgs 6.11.1) and **every Plasma login segfaults KWin** in
  `QKdeTheme::createKdeTheme()`. plasmashell/powerdevil/kaccess then abort
  with "no Qt platform plugin could be initialized" — a red herring, they
  only fail because no compositor came up. Needs BOTH
  `XDG_CURRENT_DESKTOP=KDE` and the nix path, so Hyprland is unaffected and
  the breakage hides until someone tries KDE. The distro ships its own
  plasma-integration built against its own Qt — use that.
  Reproduce WITHOUT logging out (nested, takes 10s):
  `env XDG_CURRENT_DESKTOP=KDE QT_QPA_PLATFORMTHEME=kde QT_PLUGIN_PATH=~/.nix-profile/lib/qt-6/plugins
   timeout 10 kwin_wayland --socket=t --width 600 --height 400; echo $?`
  (139 = broken, 124 = fine). Bisect by symlinking one plugin subdir at a
  time into a scratch dir and pointing QT_PLUGIN_PATH at it.
- **No nixpkgs Qt plugin may ever reach a distro Qt app.** `qt.enable`
  exports `QT_PLUGIN_PATH` *and* `QML2_IMPORT_PATH` into both the shell
  profile and the systemd user manager, independently of `platformTheme`,
  putting this profile ahead of the distro's for every Qt process on the
  host. Qt accepts a plugin whose major.minor matches (6.11.1 vs 6.11.2
  passes), loads it, and drags a second libQt6Gui into the process — which
  segfaulted KWin on every Plasma login (plasma-integration) and silently
  dropped the Kvantum style in pinentry (qtstyleplugin-kvantum).
  kde-gruvbox.nix keeps `qt.enable` ONLY for `qt.kde.settings` and forces
  both search variables empty; empty is safe, Qt falls back to its built-in
  path. The distro owns the Qt plugin/QML stack: `pacman -S kvantum kio
  plasma-integration` (and `qt6ct` for a fallback theme). This repo supplies
  only the Kvantum *themes* under `~/.config/Kvantum` — plain data, no ABI.
  Audit with `find ~/.nix-profile/lib/qt-* -name '*.so'`; it must be empty.
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
- The GTK applets need an interpreter whose `gi.require_version("Gtk",
  "3.0")` resolves. `python3.withPackages [pygobject3]` ships the
  bindings WITHOUT the typelibs and shadows the distro python in PATH, so
  a bare `python3` breaks every applet ("Namespace Gtk not available").
  `scripts/panel.sh` probes for a working one (`GRUVBOX_PYTHON` overrides).
- Chromium derives its cookie/password key from the detected desktop:
  KDE gets KWallet, `XDG_CURRENT_DESKTOP=Hyprland` is unrecognised and
  falls back to `basic` (a hardcoded key), silently DROPPING everything
  encrypted under the KDE session. Both halves of the fix are required —
  `--password-store=kwallet6` in `chromium-flags.conf`, and
  `org.freedesktop.impl.portal.Secret=kwallet` in
  `hyprland-portals.conf` (xdg-desktop-portal-gtk implements no Secret
  interface at all, and `kwallet.portal` is `UseIn=kde`). Check with
  `os_crypt.portal.prev_init_success` in `Local State` and the `v10`/`v11`
  tag on a fresh cookie.
- A nix-built **lock screen cannot authenticate** on a non-NixOS host:
  the binary links nixpkgs' libpam (whose module dir is the nix store, not
  `/usr/lib/security`) and nixpkgs' `unix_chkpwd` is not setuid root, so
  `pam_unix` never reads `/etc/shadow`. No `/etc/pam.d/hyprlock` exists
  either — only the distro package ships it. Symptom: the lock screen
  renders, the CORRECT password is rejected, and the session is
  unrecoverable without a reboot. hyprlock/swaylock must come from the
  distro (`pacman -S hyprlock swaylock`); they are deliberately absent
  from the nix package set.
- **Screen recording needs `xdg-desktop-portal-hyprland` installed.**
  `hyprland-portals.conf` asks for `default=hyprland;gtk`, but if the
  hyprland backend is not present the request falls through to
  xdg-desktop-portal-gtk, which implements no `ScreenCast` interface off
  GNOME. OBS then shows NO screen-capture source at all (its
  `linux-pipewire.so` plugin has nothing to talk to). The config alone is
  not enough — `pacman -S xdg-desktop-portal-hyprland`.
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
