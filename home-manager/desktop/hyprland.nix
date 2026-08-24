{ config, pkgs, lib, ... }:

# Hyprland session (Lua config, Hyprland >= 0.55) — companion to the KDE
# module. The configs themselves live at the repo top level (hypr/, waybar/,
# rofi/, swaync/, wlogout/) and are linked out-of-store so edits apply
# without a home-manager switch; Hyprland hot-reloads on save.
#
# Hyprland itself comes from the distro (Arch: `pacman -S hyprland`) —
# a nix-built compositor needs working GL, which nixGL makes painful for a
# session. Everything else (bar, launcher, tools) can come from nixpkgs by
# enabling `dotfiles.hyprland.packages`.

let
  cfg = config.dotfiles.hyprland;
  dotfiles = "${config.home.homeDirectory}/git/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  # On non-NixOS hosts, nix-built GL/GUI programs need the nixGL shim
  # (configured in ../nixgl.nix via targets.genericLinux.nixGL) or they
  # fail to find the host's GL drivers. wrap is a no-op burden for
  # non-GL tools, so every GUI binary gets it for uniformity.
  wrapGL = config.lib.nixGL.wrap;
in
{
  options.dotfiles.hyprland = {
    enable = lib.mkEnableOption "Hyprland session configs (Lua)";
    packages = lib.mkEnableOption "companion packages from nixpkgs";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile = {
      "hypr".source = link "hypr";
      "waybar".source = link "waybar";
      "rofi".source = link "rofi";
      "swaync".source = link "swaync";
      "wlogout".source = link "wlogout";
      "xdg-desktop-portal/hyprland-portals.conf".source =
        link "xdg-desktop-portal/hyprland-portals.conf";
    };

    home.packages = lib.mkIf cfg.packages (
      # GUI / GL programs go through the nixGL shim so they run on
      # non-NixOS hosts (hyprlock, hyprpaper and swww hard-require
      # working GL; GTK4 apps like swaync use the GL renderer too)
      (map wrapGL (with pkgs; [
        waybar
        swaynotificationcenter
        rofi # rofi-wayland was merged into rofi upstream
        wlogout
        swww # animated wallpaper transitions (scripts/wallpaper.sh)
        hyprpaper
        swaybg # wallpaper fallback where hyprpaper's GL init fails (VMs)
        hypridle
        # NOTE: hyprlock and swaylock deliberately come from the distro, not
        # here. A nix-built lock screen cannot authenticate on a non-NixOS
        # host — it links nixpkgs' libpam (module dir = the nix store, not
        # /usr/lib/security) and nixpkgs' unix_chkpwd is not setuid root, so
        # pam_unix never reads /etc/shadow. The distro packages also ship the
        # /etc/pam.d/ service files, which nix cannot install. Installing
        # them here rejects the correct password and strands the session.
        #   Arch: pacman -S hyprlock swaylock
        swappy
        pwvucontrol # audio mixer, shown as a bar dropdown applet
        pavucontrol # fallback mixer
        networkmanagerapplet # nm-connection-editor + tray applet
        blueman
        # NOTE: no qt6ct from nixpkgs — its style plugin lands in this
        # profile's qt-6/plugins/styles and would be found before the
        # distro's. Take a fallback theme from the distro (pacman -S qt6ct).
      ]))
      ++ (with pkgs; [
        # CLI tools — no GL, no wrapping needed
        imagemagick # composes the swaylock wallpaper/clock lock image
        (python3.withPackages (p: [ p.pygobject3 ])) # media/calendar applets
        grim
        slurp
        wf-recorder
        cliphist
        wl-clipboard
        brightnessctl
        playerctl
        libnotify
        jq
        psmisc # fuser, for the camera-in-use indicator
        # NOTE: plasma-integration deliberately NOT from nixpkgs — see the
        # note in kde-gruvbox.nix. The distro package provides the same
        # "kde" platform theme built against the distro's Qt, so KDE apps
        # still read kdeglobals under Hyprland without the ABI mismatch
        # that makes a Plasma login segfault.
      ])
    );
  };
}
