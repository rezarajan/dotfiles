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
    platformTheme = {
      name = "kde";
      package = [
        pkgs.kdePackages.kio
        pkgs.kdePackages.plasma-integration
      ];
    };
    style.name = "kvantum";

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

  home.packages = [
    pkgs.kdePackages.qtstyleplugin-kvantum
  ];

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
  };
}
