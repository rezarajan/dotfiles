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
        # pkgs.thunderbird
        # pkgs.libreoffice-qt6-fresh
        # pkgs.obs-studio
        # pkgs.zed-editor
      ];

      # Dev Tools
      dev-tools = [
        pkgs.binutils
        pkgs.cargo
        pkgs.crane
        pkgs.dive
        pkgs.charm-freeze
	pkgs.fluxcd
        # pkgs.glow
        pkgs.hugo
        pkgs.k9s
        pkgs.kubectl
        pkgs.kubernetes-helm
        pkgs.gnum4
        pkgs.jq
        pkgs.minikube
        pkgs.neovim
        pkgs.nixd
        pkgs.nodejs_24
        # pkgs.pandoc
        pkgs.postgresql_17
        pkgs.ripgrep
        # pkgs.tailscale
        pkgs.teleport
        pkgs.uv
        pkgs.vhs
      ];

      # Personal Packages
      personal = [
        pkgs.ani-cli
        pkgs.imagemagick
        pkgs.syncplay
        pkgs.whipper # cd audio ripper
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
    # package = config.lib.nixGL.wrap pkgs.ghostty; # use nixGL
    package = pkgs.writeShellScriptBin "ghostty" '' # use locally installed ghostty, but with autoconfigured settings
      exec /usr/bin/ghostty "$@"
    '';
    settings = {
      theme = "catppuccin-latte";
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
