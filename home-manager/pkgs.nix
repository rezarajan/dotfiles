# NOTE: make sure to import nixGL in the flake module
{ config, pkgs, nixgl, ... }:

{
  home.packages = 
    let
      # Graphical Packages
      graphical-pkgs = [
        pkgs.calibre
        pkgs.discord-canary
        pkgs.gpu-screen-recorder
        pkgs.localsend
        pkgs.obsidian
        pkgs.thunderbird
        # pkgs.libreoffice-qt6-fresh
        # pkgs.obs-studio
        # pkgs.zed-editor
      ];

      # Dev Tools
      dev-tools = [
        pkgs.binutils
        pkgs.cargo
        pkgs.hugo
        pkgs.k9s
        pkgs.kubectl
        pkgs.kubernetes-helm
        pkgs.gnum4
        pkgs.minikube
        pkgs.neovim
        # pkgs.pandoc
        pkgs.postgresql_17
        pkgs.ripgrep
        pkgs.teleport
        pkgs.uv
        pkgs.zjstatus
      ];

      # Personal Packages
      personal = [
        pkgs.ani-cli
        pkgs.syncplay
        # pkgs.uxplay
      ];
    in
      # Wraps graphical packages with nixGL for non-NixOS systems
      (map config.lib.nixGL.wrap graphical-pkgs) ++ dev-tools ++ personal;

  # programs.mpv = {
  #   enable = true;
  #   package = config.lib.nixGL.wrap pkgs.mpv; # use nixGL
  # };
  programs.ghostty = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.ghostty; # use nixGL
    settings = {
      theme = "catppuccin-mocha";
      command = "${pkgs.zsh.outPath}/bin/zsh";
    };
  };

  programs.zsh.enable = true;
  programs.zsh.initContent = ''
    PATH=$HOME/.local/bin:$PATH
  '';
  programs.zoxide.enable = true;
  programs.starship.enable = true;
  programs.zellij.enable = true;
  programs.go.enable = true;
  programs.yazi.enable = true;
}
