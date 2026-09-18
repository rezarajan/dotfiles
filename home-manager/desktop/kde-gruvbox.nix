{ config, lib, pkgs, ... }:

# Custom gruvbox acrylic theme, light + dark.
#
# The Kvantum themes (./kvantum/Gruvbox, ./kvantum/GruvboxDark) are generated
# artifacts: edit ./kvantum/tools/acrylic_gen.py (widget art, palettes,
# shadows) or patch_kvconfig.py (geometry/behavior keys) and rerun them, then
# `home-manager switch`. Kvantum pairs the themes by naming convention:
# widget style "kvantum" uses Gruvbox (light), "kvantum-dark" uses GruvboxDark,
# which is how the Plasma light/dark toggle switches Qt app styling.
#
# The look-and-feel packages wire the toggle itself: kdeglobals
# [KDE] DefaultLightLookAndFeel / DefaultDarkLookAndFeel select gruvbox-light /
# gruvbox, and each package's defaults file applies color scheme, icons, and
# widget style. Mutable Plasma state (kwinrc Round-Corners radius, panel
# translucency in plasmashellrc, gtk.css import lines) is snapshotted in
# ../../kde/ by the backup script rather than managed here, because Plasma
# rewrites those files at runtime.

let
  gruvboxPlusIcons = pkgs.stdenvNoCC.mkDerivation {
    pname = "gruvbox-plus-icons";
    version = "6.5.0";
    dontFixup = true;

    src = pkgs.fetchFromGitHub {
      owner = "SylEleuth";
      repo = "gruvbox-plus-icon-pack";
      rev = "a9b19b95ec653fa80574fbd7ffefc2d03abfc991";
      hash = "sha256-EG8AmnLqqml7oGeeNqLLpnmMj6/KVAJOKuTjCUoor4s=";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/icons"
      cp -a Gruvbox-Plus-Dark "$out/share/icons/"
      cp -a Gruvbox-Plus-Light "$out/share/icons/"
      runHook postInstall
    '';
  };
in
{
  # Back up pre-existing unmanaged files/dirs before home-manager links over them
  home.activation.moveManualGruvboxThemeDirs =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      for target in \
        "${config.xdg.configHome}/Kvantum/Gruvbox" \
        "${config.xdg.configHome}/Kvantum/GruvboxDark" \
        "${config.xdg.dataHome}/icons/Gruvbox-Plus-Dark" \
        "${config.xdg.dataHome}/icons/Gruvbox-Plus-Light" \
        "${config.xdg.dataHome}/plasma/look-and-feel/gruvbox" \
        "${config.xdg.dataHome}/plasma/look-and-feel/gruvbox-light" \
        "${config.xdg.dataHome}/plasma/desktoptheme/gruvbox-acrylic"
      do
        if [ -e "$target" ] && [ ! -L "$target" ]; then
          backup="$target.hm-backup"
          index=0
          while [ -e "$backup" ]; do
            index=$((index + 1))
            backup="$target.hm-backup-$index"
          done

          run mv "$target" "$backup"
        fi
      done
    '';

  # Chromium-family browsers and Electron shells spawn bubble UI (share
  # hub, cast picker …) as plain Wayland toplevels, which KWin decorates
  # with a full titlebar. This rule strips decorations from exactly those:
  # bubble windows are titled bare product names, real windows are always
  # "Page - Product". kwinrulesrc stays mutable (the user edits rules in
  # the KCM), so the rule is enforced idempotently by UUID on each switch
  # and other rules are left alone.
  home.activation.gruvboxKwinRules =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rid="8019db3d-d55d-4b1c-9752-56534b2d28e7"
      w() {
        run /usr/bin/kwriteconfig6 --file kwinrulesrc --group "$rid" --key "$1" "$2"
      }
      w Description "Browser/Electron bubbles: undecorated"
      w wmclass "chromium|chrome|thorium|brave|vivaldi|opera|edge|electron"
      w wmclassmatch 3
      w title "^(Chromium|Google Chrome|Chrome|Thorium|Brave|Vivaldi|Opera|Microsoft Edge|Electron)$"
      w titlematch 3
      w types 3
      w noborder true
      w noborderrule 2
      cur="$(/usr/bin/kreadconfig6 --file kwinrulesrc --group General --key rules)"
      case ",$cur," in
        *",$rid,"*) ;;
        *) run /usr/bin/kwriteconfig6 --file kwinrulesrc --group General \
             --key rules "''${cur:+$cur,}$rid" ;;
      esac
      /usr/bin/qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    '';

  # kde-gtk-config owns the mutable GTK configs (settings.ini, ~/.gtkrc-2.0,
  # xsettingsd.conf). Icons, cursors, and fonts are auto-synced into them
  # from KDE settings by the gtkconfig KDED module, but the GTK theme NAME
  # has no KDE-side source of truth — it is only written when a theme is
  # picked in the Application Style KCM, so a fresh machine keeps showing
  # Breeze even though the Gruvbox-Dragon themes are deployed. Converge it
  # here: in a running session ask the GtkConfig service (rewrites every
  # GTK config incl. xsettingsd and live-notifies apps); headless, seed the
  # files directly so the first login starts themed (the next in-session
  # switch then takes the service path and completes the rest).
  #
  # And it is one of the two, not always the dark one: GTK3/4 read their
  # colors at runtime so either theme would do there, but gtk-2.0/gtkrc has
  # no runtime mechanism and BAKES the palette, so the wrong variant leaves
  # GTK2 apps dark in a light session. The look-and-feel packages cannot set
  # this (there is no GTK key in a KDE defaults file), so pick it from the
  # active color scheme here and let sync-gnome-portal-settings keep it in
  # step on every later toggle.
  home.activation.gruvboxGtkTheme =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      case "$(/usr/bin/kreadconfig6 --file kdeglobals --group General \
                --key ColorScheme 2>/dev/null || true)" in
        *Light) theme="Gruvbox-Dragon-Light" ;;
        *)      theme="Gruvbox-Dragon" ;;
      esac
      cur="$(/usr/bin/qdbus6 org.kde.GtkConfig /GtkConfig org.kde.GtkConfig.gtkTheme 2>/dev/null || true)"
      if [ "$cur" = "$theme" ]; then
        : # already selected
      elif [ -n "$cur" ]; then
        run /usr/bin/qdbus6 org.kde.GtkConfig /GtkConfig org.kde.GtkConfig.setGtkTheme "$theme"
      else
        for ver in gtk-3.0 gtk-4.0; do
          ini="${config.xdg.configHome}/$ver/settings.ini"
          grep -qs "^gtk-theme-name=$theme\$" "$ini" || \
            run /usr/bin/kwriteconfig6 --file "$ini" --group Settings --key gtk-theme-name "$theme"
        done
        rc2="$HOME/.gtkrc-2.0"
        if ! grep -qs "^gtk-theme-name=\"$theme\"\$" "$rc2"; then
          [ -f "$rc2" ] && run sed -i "/^gtk-theme-name=/d" "$rc2"
          run bash -c 'printf "gtk-theme-name=\"%s\"\n" "$0" >> "$1"' "$theme" "$rc2"
        fi
      fi
    '';

  # Plasma INLINES the scheme's [Colors:*] / [ColorEffects:*] / [WM] groups
  # into kdeglobals when a scheme is applied, and those inlined values are
  # what every Qt app and kde-gtk-config's generated GTK colors.css read —
  # the ColorScheme *name* alone decides nothing. So shipping an edited
  # .colors file (a palette.py change regenerated by colorscheme_gen.py)
  # changes precisely nothing on its own, and `plasma-apply-colorscheme` is
  # no help: asked for the scheme that is already named in kdeglobals it
  # prints "already set", exits 0 and re-inlines nothing. Splice the groups
  # in ourselves — the same swap hypr/scripts/theme-mode.sh does — and
  # broadcast the palette change so running KDE apps restyle live.
  #
  # Only when actually stale: every key the scheme file defines in those
  # groups must already be inlined verbatim. One-way comparison on purpose,
  # since Plasma adds keys of its own (ChangeSelectionColor, Enable) that
  # the scheme file never carries.
  home.activation.gruvboxColorScheme =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      kg="$HOME/.config/kdeglobals"
      scheme="$(/usr/bin/kreadconfig6 --file kdeglobals --group General \
        --key ColorScheme 2>/dev/null || true)"
      file=""
      for dir in "${config.xdg.dataHome}/color-schemes" /usr/share/color-schemes; do
        [ -f "$dir/$scheme.colors" ] && file="$dir/$scheme.colors" && break
      done
      if [ -n "$file" ] && [ -f "$kg" ] && ! ${pkgs.gawk}/bin/awk -v kg="$kg" '
            /^\[/   { grp = $0; keep = (grp ~ /^\[(Colors:|ColorEffects:|WM\])/); next }
            keep && /=/ { want[grp "\034" $0] = 1 }
            END {
              while ((getline line < kg) > 0) {
                if (line ~ /^\[/) { g = line; continue }
                if (line ~ /=/) have[g "\034" line] = 1
              }
              for (k in want) if (!(k in have)) exit 1
              exit 0
            }' "$file"; then
        ${pkgs.gawk}/bin/awk 'BEGIN{skip=0} /^\[/{skip=($0~/^\[(Colors:|ColorEffects:|WM\])/)?1:0} !skip' \
          "$kg" > "$kg.hm-tmp"
        ${pkgs.gawk}/bin/awk 'BEGIN{keep=0} /^\[/{keep=($0~/^\[(Colors:|ColorEffects:|WM\])/)?1:0} keep' \
          "$file" >> "$kg.hm-tmp"
        run mv -f "$kg.hm-tmp" "$kg"
        # Editing the file behind KConfig's back tells nobody: kde-gtk-config
        # (which owns ~/.config/gtk-{3,4}.0/colors.css, where GTK apps get
        # these colors from) listens on KConfigWatcher, and that only fires
        # for a write KConfig itself made and marked dirty — an unchanged
        # rewrite is skipped, so delete the key and put it back to guarantee
        # one. The inlined [Colors:*] apps actually read stay correct across
        # the gap. GtkConfig's own setGtkTheme is no substitute: it rewrites
        # settings.ini and leaves colors.css alone.
        kw() { timeout 5 /usr/bin/kwriteconfig6 --notify --file kdeglobals \
                 --group General --key ColorScheme "$@" 2>/dev/null || true; }
        kw --delete
        kw "$scheme"
        # and the legacy broadcast, for Qt apps that only watch this one
        # (0 = PaletteChanged)
        if [ -x /usr/bin/dbus-send ]; then
          timeout 5 /usr/bin/dbus-send --session --type=signal /KGlobalSettings \
            org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true
        fi
      fi
    '';

  # The Gruvbox-Dragon GTK themes are a thin shim over the distro's Breeze
  # widget css, imported by a path RELATIVE to the themes directory. Park a
  # mirror of Breeze there for it to resolve against. Why not just point at
  # /usr/share/themes/Breeze: a flatpak has its own /usr with no Breeze in
  # it, so the absolute import died and every flatpak GTK app silently fell
  # back to Adwaita — LibreOffice rendered Adwaita-grey with square
  # scrollbars over our colors.css. Dot-prefixed so no theme picker offers
  # the mirror as a theme and it never shadows the distro's own Breeze.
  #
  # BOTH variants, under their own names, side by side — because Breeze's
  # gtk-dark.css is a 50-byte shim that does
  # `@import url("../../Breeze-Dark/gtk-3.0/gtk.css")`. Mirror Breeze alone
  # and that sibling is missing, dark mode imports nothing, and GTK renders
  # raw unstyled white while the (KWin-drawn) titlebar stays correctly dark.
  # Whole directories, so Breeze's own ../assets/ urls keep resolving too.
  home.activation.gruvboxBreezeMirror =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dst="${config.xdg.dataHome}/themes/.breeze-base"
      if [ -d /usr/share/themes/Breeze/gtk-3.0 ] \
         && [ -d /usr/share/themes/Breeze-Dark/gtk-3.0 ]; then
        run rm -rf "$dst.new"
        run mkdir -p "$dst.new"
        for variant in Breeze Breeze-Dark; do
          run cp -aL "/usr/share/themes/$variant" "$dst.new/$variant"
        done
        run rm -rf "$dst"
        run mv "$dst.new" "$dst"
      else
        echo "kde-gruvbox: /usr/share/themes/Breeze{,-Dark} missing — GTK" \
             "apps will fall back to Adwaita; install the distro's" \
             "breeze-gtk" >&2
      fi
    '';

  # Flatpak apps see neither the themes directory nor the GTK config dir by
  # default: XDG_DATA_HOME is per-app inside the sandbox, so ~/.local/share
  # /themes is simply absent (the host's icons ARE re-exported via
  # /run/host/user-share, themes are not). Hand every flatpak read-only
  # access to both, which is what makes the mirror above reachable. Global
  # (no app id) and idempotent; `flatpak override --user --reset` undoes it.
  home.activation.gruvboxFlatpakTheming =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # absolute path: home-manager activation runs without /usr/bin on PATH
      if [ -x /usr/bin/flatpak ]; then
        run /usr/bin/flatpak override --user \
          --filesystem=xdg-data/themes:ro \
          --filesystem=xdg-data/icons:ro \
          --filesystem=xdg-config/gtk-3.0:ro \
          --filesystem=xdg-config/gtk-4.0:ro || true
      fi
    '';

  # kde-gtk-config owns gtk.css but preserves user content; make sure our
  # acrylic stylesheet stays imported (idempotent).
  home.activation.gruvboxGtkCssImports =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for ver in gtk-3.0 gtk-4.0; do
        css="${config.xdg.configHome}/$ver/gtk.css"
        if [ ! -L "$css" ]; then
          touch "$css"
          grep -qF "gruvbox-acrylic.css" "$css" || \
            run printf "%s\n" "@import 'gruvbox-acrylic.css';" >> "$css"
        fi
      done
    '';

  qt = {
    enable = true;
    # NOTE: deliberately NO platformTheme here. Setting it makes
    # home-manager export QT_PLUGIN_PATH=<this profile>, putting nixpkgs'
    # Qt plugins AHEAD of the distro's for every Qt app on the host — and
    # nixpkgs' Qt is almost never the distro's exact build. Qt accepts a
    # plugin whose major.minor matches (6.11.1 vs 6.11.2 passes), loads it,
    # and drags a second libQt6Gui into the process. That segfaulted KWin in
    # QKdeTheme::createKdeTheme() on every Plasma login (plasma-integration)
    # and silently lost pinentry's Kvantum widget style (qtstyleplugin-kvantum).
    # On a non-NixOS host the distro owns the Qt plugin stack — kio and
    # plasma-integration both come from pacman; QT_QPA_PLATFORMTHEME is set
    # as a plain session variable below so the DISTRO's plasma-integration
    # is what answers to "kde".
    # NOTE: no qt.style.name here — it would export QT_STYLE_OVERRIDE=kvantum,
    # which forces every Qt app onto the plain (light) Kvantum style at login
    # regardless of the active mode's widgetStyle (kvantum-dark). The widget
    # style is owned by kdeglobals via the look-and-feel packages.

    kde.settings = {
      # NOTE: do not pin ColorScheme/Icons/widgetStyle here — the light/dark
      # toggle owns them via the kdedefaults layer (the look-and-feel
      # packages' defaults), and user-layer pins would override whichever
      # mode is active at switch time. On a fresh machine, apply once with:
      #   plasma-apply-lookandfeel -a gruvbox
      kdeglobals = {
        KDE = {
          DefaultDarkLookAndFeel = "gruvbox";
          DefaultLightLookAndFeel = "gruvbox-light";
          # never auto-apply a variant at login/time-of-day; the manually
          # chosen mode persists (KNightTime defaults to "day" without
          # location data, which used to flip sessions to light at login)
          AutomaticLookAndFeel = false;
        };
      };

      # base theme; the kvantum-dark widget style picks GruvboxDark from it
      "Kvantum/kvantum.kvconfig".General.theme = "Gruvbox";
    };
  };

  home.sessionVariables.QT_QPA_PLATFORMTHEME = "kde";

  # qt.enable exports QT_PLUGIN_PATH and QML2_IMPORT_PATH into both the
  # shell profile and the systemd user manager regardless of platformTheme.
  # qt.enable is kept only for qt.kde.settings above, so force both empty:
  # the distro owns the Qt plugin and QML stacks (pacman -S kvantum kio
  # plasma-integration). Empty is safe — Qt falls back to its built-in path.
  home.sessionSearchVariables = {
    QT_PLUGIN_PATH = lib.mkForce [ ];
    QML2_IMPORT_PATH = lib.mkForce [ ];
  };
  systemd.user.sessionVariables = {
    QT_PLUGIN_PATH = lib.mkForce "";
    QML2_IMPORT_PATH = lib.mkForce "";
  };

  # This repo supplies only the Kvantum *themes* under ~/.config/Kvantum —
  # plain data, no ABI. Adding a nixpkgs Qt plugin here re-arms the footgun.
  home.packages = [
    # build tool for ./kvantum/tools/cursor_gen.py (generate_all skips
    # cursor regeneration when it is absent)
    pkgs.xcursorgen
  ];

  # A stale QT_STYLE_OVERRIDE=kvantum persists in the systemd user manager:
  # at logout, startplasma restores the manager environment to a snapshot
  # taken at session start (cleanupPlasmaEnvironment), so a var that was in
  # the environment once keeps resurrecting across logins for as long as the
  # user manager lives. Purge it at login, after Plasma's environment import
  # and before any graphical service starts.
  # kwin is spawned directly by startplasma (not a systemd unit), inheriting
  # the manager environment before any user unit can run — so the purge must
  # happen in the idle gap between logout (snapshot restore) and the next
  # login (startplasma import). A recurring timer in the persistent user
  # manager closes that gap; once one login starts clean, the session's
  # snapshot is clean and the cycle self-heals.
  systemd.user.services.purge-qt-style-override = {
    Unit = {
      Description = "Purge stale QT_STYLE_OVERRIDE from the session environment";
      Before = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "/usr/bin/systemctl --user unset-environment QT_STYLE_OVERRIDE";
    };
    Install.WantedBy = [ "graphical-session-pre.target" ];
  };

  systemd.user.timers.purge-qt-style-override = {
    Unit.Description = "Continuously purge stale QT_STYLE_OVERRIDE between sessions";
    Timer = {
      OnStartupSec = "10";
      OnUnitInactiveSec = "10";
      AccuracySec = "5";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # xdg-desktop-portal consults the kde and gtk Settings backends in order,
  # but the KDE backend does not serve the org.gnome.desktop.interface
  # namespace — those keys come from the gtk backend, i.e. dconf, which
  # nothing on the KDE side ever updates. Stale dconf values made
  # portal-reading GTK apps (ghostty's titlebar icon, GNOME apps, flatpaks)
  # resolve the dark icon theme and prefer-dark while the session was
  # light. Mirror what kde-gtk-config writes into gtk-3.0/settings.ini
  # (rewritten on every light/dark toggle) into dconf: a path unit watches
  # the file, and the service also runs once per login.
  systemd.user.services.sync-gnome-portal-settings =
    let
      syncScript = pkgs.writeShellScript "sync-gnome-portal-settings" ''
        ini="$HOME/.config/gtk-3.0/settings.ini"
        [ -r "$ini" ] || exit 0
        get() { sed -n "s/^$1=//p" "$ini" | head -n1; }
        put() {
          v="$(get "$2")"
          [ -n "$v" ] && /usr/bin/gsettings set org.gnome.desktop.interface "$1" "$v"
        }
        case "$(get gtk-application-prefer-dark-theme)" in
          true|1) scheme=prefer-dark; want=Gruvbox-Dragon ;;
          *) scheme=prefer-light; want=Gruvbox-Dragon-Light ;;
        esac

        # The GTK theme name has to follow the toggle too, for gtk-2.0's
        # baked palette (see gruvboxGtkTheme). Ask the GtkConfig service
        # rather than editing settings.ini, so kde-gtk-config rewrites every
        # GTK config consistently and notifies running apps. That rewrite
        # re-triggers this unit's path watch — harmless, because the second
        # run finds the theme already correct and changes nothing, so it
        # settles after exactly one extra pass.
        if [ "$(get gtk-theme-name)" != "$want" ]; then
          timeout 5 /usr/bin/qdbus6 org.kde.GtkConfig /GtkConfig \
            org.kde.GtkConfig.setGtkTheme "$want" 2>/dev/null || true
        fi

        put icon-theme gtk-icon-theme-name
        put cursor-theme gtk-cursor-theme-name
        put gtk-theme gtk-theme-name
        /usr/bin/gsettings set org.gnome.desktop.interface color-scheme "$scheme"
      '';
    in
    {
      Unit.Description = "Mirror KDE GTK settings into dconf for the portal's GNOME namespace";
      Service = {
        Type = "oneshot";
        ExecStart = "${syncScript}";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

  systemd.user.paths.sync-gnome-portal-settings = {
    Unit.Description = "Watch kde-gtk-config settings.ini for light/dark toggles";
    Path = {
      PathChanged = "%h/.config/gtk-3.0/settings.ini";
      PathModified = "%h/.config/gtk-3.0/settings.ini";
    };
    Install.WantedBy = [ "paths.target" ];
  };

  xdg.desktopEntries.systemsettings = {
    name = "System Settings";
    genericName = "System Settings";
    exec = "/usr/bin/systemsettings";
    icon = "preferences-system";
    categories = [
      "Qt"
      "KDE"
      "Settings"
    ];
    startupNotify = true;
    settings = {
      OnlyShowIn = "KDE;";
      SingleMainWindow = "true";
      X-DocPath = "systemsettings/index.html";
      X-KDE-Shortcuts = "Tools,Meta+I";
    };
  };

  xdg.configFile = {
    "Kvantum/Gruvbox" = {
      force = true;
      source = ./kvantum/Gruvbox;
    };

    "Kvantum/GruvboxDark" = {
      force = true;
      source = ./kvantum/GruvboxDark;
    };

    "gtk-3.0/gruvbox-acrylic.css" = {
      force = true;
      source = ./gtk/gruvbox-acrylic-gtk3.css;
    };

    "gtk-4.0/gruvbox-acrylic.css" = {
      force = true;
      source = ./gtk/gruvbox-acrylic-gtk4.css;
    };
  };

  xdg.dataFile = {
    "color-schemes/GruvboxDragon.colors" = {
      force = true;
      source = ./color-schemes/GruvboxDragon.colors;
    };

    "color-schemes/GruvboxDragonLight.colors" = {
      force = true;
      source = ./color-schemes/GruvboxDragonLight.colors;
    };

    "icons/Gruvbox-Plus-Dark" = {
      force = true;
      source = "${gruvboxPlusIcons}/share/icons/Gruvbox-Plus-Dark";
    };

    "icons/Gruvbox-Plus-Light" = {
      force = true;
      source = "${gruvboxPlusIcons}/share/icons/Gruvbox-Plus-Light";
    };

    "plasma/look-and-feel/gruvbox" = {
      force = true;
      source = ./look-and-feel/gruvbox;
    };

    "plasma/look-and-feel/gruvbox-light" = {
      force = true;
      source = ./look-and-feel/gruvbox-light;
    };

    # generated by ./kvantum/tools/plasma_theme_gen.py — acrylic plasmashell
    # dialogs/panel/tooltips; selected via [plasmarc][Theme] in the
    # look-and-feel defaults and follows the active color scheme
    "plasma/desktoptheme/gruvbox-acrylic" = {
      force = true;
      source = ./plasma-theme/gruvbox-acrylic;
    };

    # generated by ./kvantum/tools/gtk_theme_gen.py — gtk2 carries baked
    # palette colors (no runtime sync exists for gtk2); gtk3/4 import
    # Breeze's widget css and take colors from kde-gtk-config's runtime
    # colors.css sync, so one theme follows the light/dark toggle.
    # Selected via kde-gtk-config (GtkConfig dbus / Application Style KCM).
    "themes/Gruvbox-Dragon" = {
      force = true;
      source = ./gtk/themes/Gruvbox-Dragon;
    };

    "themes/Gruvbox-Dragon-Light" = {
      force = true;
      source = ./gtk/themes/Gruvbox-Dragon-Light;
    };

    # generated by ./kvantum/tools/cursor_gen.py — palette-driven cursor
    # pair (xcursor format, animated wait/progress); each look-and-feel
    # package selects its variant via [kcminputrc][Mouse] cursorTheme,
    # so the light/dark toggle switches cursors through kdedefaults
    "icons/Gruvbox-Dragon-Cursors" = {
      force = true;
      source = ./cursors/Gruvbox-Dragon-Cursors;
    };

    "icons/Gruvbox-Dragon-Cursors-Light" = {
      force = true;
      source = ./cursors/Gruvbox-Dragon-Cursors-Light;
    };
  };
}
