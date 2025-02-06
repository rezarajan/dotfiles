{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cascadura";
  home.homeDirectory = "/var/home/cascadura";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
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
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.gnum4
    pkgs.minikube
    pkgs.mpv
    pkgs.neovim
    pkgs.postgresql_17
    pkgs.syncplay
    pkgs.teleport.client
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

    ".config/zellij/layouts/default.kdl".text = ''
      layout {
          default_tab_template {
              pane split_direction="vertical" {
                pane size="60%"
                pane size="40%" split_direction="horizontal" {
                  children
                }
              }
              pane size=1 borderless=true {
                  plugin location="file:${pkgs.zjstatus}/bin/zjstatus.wasm" {
                  // -- Catppuccin Macchiato --
                  color_rosewater "#f4dbd6"
                  color_flamingo "#f0c6c6"
                  color_pink "#f5bde6"
                  color_mauve "#c6a0f6"
                  color_red "#ed8796"
                  color_maroon "#ee99a0"
                  color_peach "#f5a97f"
                  color_yellow "#eed49f"
                  color_green "#a6da95"
                  color_teal "#8bd5ca"
                  color_sky "#91d7e3"
                  color_sapphire "#7dc4e4"
                  color_blue "#8aadf4"
                  color_lavender "#b7bdf8"
                  color_text "#cad3f5"
                  color_subtext1 "#b8c0e0"
                  color_subtext0 "#a5adcb"
                  color_overlay2 "#939ab7"
                  color_overlay1 "#8087a2"
                  color_overlay0 "#6e738d"
                  color_surface2 "#5b6078"
                  color_surface1 "#494d64"
                  color_surface0 "#363a4f"
                  color_base "#24273a"
                  color_mantle "#1e2030"
                  color_crust "#181926"

                 format_left   "#[bg=$surface0,fg=$sapphire]#[bg=$sapphire,fg=$crust,bold] {session} #[bg=$surface0] {mode}#[bg=$surface0] {tabs}"
                 format_center "{notifications}"
                 format_right  "#[bg=$surface0,fg=$flamingo]#[fg=$crust,bg=$flamingo] #[bg=$surface1,fg=$flamingo,bold] {command_user}@{command_host}#[bg=$surface0,fg=$surface1]#[bg=$surface0,fg=$maroon]#[bg=$maroon,fg=$crust]󰃭 #[bg=$surface1,fg=$maroon,bold] {datetime}#[bg=$surface0,fg=$surface1]"
                 format_space  "#[bg=$surface0]"
                 format_hide_on_overlength "true"
                 format_precedence "lrc"

                 border_enabled  "false"
                 border_char     "─"
                 border_format   "#[bg=$surface0]{char}"
                 border_position "top"

                 // hide_frame_for_single_pane "true"

                 mode_normal        "#[bg=$green,fg=$crust,bold] NORMAL#[bg=$surface0,fg=$green]"
                 mode_tmux          "#[bg=$mauve,fg=$crust,bold] TMUX#[bg=$surface0,fg=$mauve]"
                 mode_locked        "#[bg=$red,fg=$crust,bold] LOCKED#[bg=$surface0,fg=$red]"
                 mode_pane          "#[bg=$teal,fg=$crust,bold] PANE#[bg=$surface0,fg=teal]"
                 mode_tab           "#[bg=$teal,fg=$crust,bold] TAB#[bg=$surface0,fg=$teal]"
                 mode_scroll        "#[bg=$flamingo,fg=$crust,bold] SCROLL#[bg=$surface0,fg=$flamingo]"
                 mode_enter_search  "#[bg=$flamingo,fg=$crust,bold] ENT-SEARCH#[bg=$surfaco,fg=$flamingo]"
                 mode_search        "#[bg=$flamingo,fg=$crust,bold] SEARCHARCH#[bg=$surfac0,fg=$flamingo]"
                 mode_resize        "#[bg=$yellow,fg=$crust,bold] RESIZE#[bg=$surfac0,fg=$yellow]"
                 mode_rename_tab    "#[bg=$yellow,fg=$crust,bold] RENAME-TAB#[bg=$surface0,fg=$yellow]"
                 mode_rename_pane   "#[bg=$yellow,fg=$crust,bold] RENAME-PANE#[bg=$surface0,fg=$yellow]"
                 mode_move          "#[bg=$yellow,fg=$crust,bold] MOVE#[bg=$surface0,fg=$yellow]"
                 mode_session       "#[bg=$pink,fg=$crust,bold] SESSION#[bg=$surface0,fg=$pink]"
                 mode_prompt        "#[bg=$pink,fg=$crust,bold] PROMPT#[bg=$surface0,fg=$pink]"

                 tab_normal              "#[bg=$surface0,fg=$blue]#[bg=$blue,fg=$crust,bold]{index} #[bg=$surface1,fg=$blue,bold] {name}{floating_indicator}#[bg=$surface0,fg=$surface1]"
                 tab_normal_fullscreen   "#[bg=$surface0,fg=$blue]#[bg=$blue,fg=$crust,bold]{index} #[bg=$surface1,fg=$blue,bold] {name}{fullscreen_indicator}#[bg=$surface0,fg=$surface1]"
                 tab_normal_sync         "#[bg=$surface0,fg=$blue]#[bg=$blue,fg=$crust,bold]{index} #[bg=$surface1,fg=$blue,bold] {name}{sync_indicator}#[bg=$surface0,fg=$surface1]"
                 tab_active              "#[bg=$surface0,fg=$peach]#[bg=$peach,fg=$crust,bold]{index} #[bg=$surface1,fg=$peach,bold] {name}{floating_indicator}#[bg=$surface0,fg=$surface1]"
                 tab_active_fullscreen   "#[bg=$surface0,fg=$peach]#[bg=$peach,fg=$crust,bold]{index} #[bg=$surface1,fg=$peach,bold] {name}{fullscreen_indicator}#[bg=$surface0,fg=$surface1]"
                 tab_active_sync         "#[bg=$surface0,fg=$peach]#[bg=$peach,fg=$crust,bold]{index} #[bg=$surface1,fg=$peach,bold] {name}{sync_indicator}#[bg=$surface0,fg=$surface1]"
                 tab_separator           "#[bg=$surface0] "

                 tab_sync_indicator       " "
                 tab_fullscreen_indicator " 󰊓"
                 tab_floating_indicator   " 󰹙"

                 notification_format_unread "#[bg=surface0,fg=$yellow]#[bg=$yellow,fg=$crust] #[bg=$surface1,fg=$yellow] {message}#[bg=$surface0,fg=$yellow]"
                 notification_format_no_notifications ""
                 notification_show_interval "10"

                 command_host_command    "uname -n"
                 command_host_format     "{stdout}"
                 command_host_interval   "0"
                 command_host_rendermode "static"

                 command_user_command    "whoami"
                 command_user_format     "{stdout}"
                 command_user_interval   "10"
                 command_user_rendermode "static"

                 datetime          "{format}"
                 datetime_format   "%Y-%m-%d 󰅐 %H:%M"
                 datetime_timezone "America/New_York"
                 }
              }
          }
      }
    '';
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
    # EDITOR = "emacs";
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Enable some packages. This is a convenience feature
  # They can be installed via pkgs.<pkgname> instead in home.packages
  programs.zsh.enable = true;
  programs.zsh.initExtra = ''
   alias k=kubectl
  '';
  programs.zoxide.enable = true;
  # programs.kitty.enable = true;
  # programs.kitty.themeFile = "ayu"; # From kitty-themes github
  # programs.kitty.extraConfig = "shell zsh";
  # programs.kitty.font.package = pkgs.nerd-fonts.fira-code;
  # programs.kitty.font.name = "FiraCode";
  programs.starship.enable = true;
  programs.zellij.enable = true;
  programs.go.enable = true;
  programs.yazi.enable = true;
}
