{ config, lib, pkgs, nixgl, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Configure nixGL
  nixGL.packages = nixgl.packages;
  # see: https://mynixos.com/home-manager/option/nixGL.defaultWrapper
  # NOTE: for nvidia, the --impure option must be passed to home-manager switch
  nixGL.defaultWrapper = "nvidia"; # options one of "mesa", "mesaPrime", "nvidia", "nvidiaPrime"
  nixGL.installScripts = [ "nvidia" ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cascadura";
  home.homeDirectory = "/home/cascadura";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # pkgs.nerd-fonts.fira-code
    # pkgs.nerd-fonts.fira-mono

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    pkgs.ani-cli
    pkgs.binutils
    pkgs.cargo
    (config.lib.nixGL.wrap pkgs.discord-canary)
    (config.lib.nixGL.wrap pkgs.foliate)
    pkgs.hugo
    pkgs.k9s
    pkgs.kubectl
    pkgs.kubernetes-helm
    (config.lib.nixGL.wrap pkgs.gpu-screen-recorder)
    pkgs.gnum4
    # (config.lib.nixGL.wrap pkgs.libreoffice-qt6-fresh) # use nixGL
    (config.lib.nixGL.wrap pkgs.localsend)
    pkgs.minikube
    pkgs.neovim
    (config.lib.nixGL.wrap pkgs.obsidian)
    # (config.lib.nixGL.wrap pkgs.obs-studio)
    pkgs.pandoc
    pkgs.postgresql_17
    pkgs.ripgrep
    pkgs.rofi-wayland
    pkgs.syncplay
    pkgs.teleport
    # (pkgs.python312.withPackages (python-pkgs: with python-pkgs; [
    #   # select Python packages here
    #   pandas
    #   numpy
    #   matplotlib
    #   seaborn
    #   notebook
    #   requests
    # ]))
    pkgs.uv
    (config.lib.nixGL.wrap pkgs.zed-editor)
    pkgs.zjstatus
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    # Zellij config
    ".config/zellij/config.kdl".source = dotfiles/zellij/config.kdl;
    ".config/zellij/layouts/default.kdl".source = pkgs.substituteAll {
        src = dotfiles/zellij/layouts/default.kdl;
        zjstatus = "${pkgs.zjstatus}";
      };
    };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/cascadura/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1"; # hint Electron apps to use Wayland
  };

  # These paths get added to the PATH (but only works on .bashrc for now)
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.shellAliases = {
    k = "kubectl";
  };


  # Display Manager
  # wayland.windowManager.hyprland.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  # programs.mpv = {
  #   enable = true;
  #   package = config.lib.nixGL.wrap pkgs.mpv; # use nixGL
  # };
  programs.ghostty = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.ghostty; # use nixGL
    settings = {
      theme = "catppuccin-frappe";
      command = "${pkgs.zsh.outPath}/bin/zsh";
    };
  };

  # Enable some packages. This is a convenience feature
  # They can be installed via pkgs.<pkgname> instead in home.packages
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
