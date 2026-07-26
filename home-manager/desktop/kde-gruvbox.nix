{ pkgs, ... }:

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
  qt = {
    enable = true;
    platformTheme.name = "kde";
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

  xdg.configFile."Kvantum/gruvbox-kvantum".source =
    "${gruvboxKvantum}/share/Kvantum/gruvbox-kvantum";

  xdg.dataFile = {
    "color-schemes/GruvboxDragon.colors".source = gruvboxDragonColors;
    "icons/Gruvbox-Plus-Dark".source =
      "${gruvboxPlusDarkIcons}/share/icons/Gruvbox-Plus-Dark";
  };
}
