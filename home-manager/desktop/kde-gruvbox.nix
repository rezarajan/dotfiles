{ config, lib, pkgs, ... }:

let
  gruvboxKvantum = pkgs.stdenvNoCC.mkDerivation {
    pname = "gruvbox-kvantum-theglitchh";
    version = "2024-09-29";

    src = pkgs.fetchFromGitHub {
      owner = "theglitchh";
      repo = "Gruvbox-Kvantum";
      rev = "29ba1f05affba26ef0e718de6ddb96c21ccd182e";
      hash = "sha256-o3EEpd8fsrKPNA6TmiK7KLxy6hld+MpSrtLAKPhtJOE=";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/Kvantum"
      cp -a gruvbox-kvantum "$out/share/Kvantum/"
      runHook postInstall
    '';
  };

  gruvboxPlusDarkIcons = pkgs.stdenvNoCC.mkDerivation {
    pname = "gruvbox-plus-dark-icons";
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
      runHook postInstall
    '';
  };

  gruvboxDragonColors = pkgs.fetchurl {
    url = "https://pastebin.com/raw/vGGE0ZZj";
    hash = "sha256-pBxgQJA6zjq8uBRs9B6KHxaggXl0+J1WPKnGwbG4ArY=";
  };
in
{
  home.activation.moveManualGruvboxThemeDirs =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      for target in \
        "${config.xdg.configHome}/Kvantum/gruvbox-kvantum" \
        "${config.xdg.dataHome}/icons/Gruvbox-Plus-Dark"
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
      kdeglobals = {
        General.ColorScheme = "GruvboxDragon";
        Icons.Theme = "Gruvbox-Plus-Dark";
        KDE.widgetStyle = "kvantum";
      };

      "Kvantum/kvantum.kvconfig".General.theme = "gruvbox-kvantum";
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

  xdg.configFile."Kvantum/gruvbox-kvantum" = {
    force = true;
    source = "${gruvboxKvantum}/share/Kvantum/gruvbox-kvantum";
  };

  xdg.dataFile = {
    "color-schemes/GruvboxDragon.colors" = {
      force = true;
      source = gruvboxDragonColors;
    };

    "icons/Gruvbox-Plus-Dark" = {
      force = true;
      source = "${gruvboxPlusDarkIcons}/share/icons/Gruvbox-Plus-Dark";
    };
  };
}
