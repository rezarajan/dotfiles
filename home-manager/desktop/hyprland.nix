{ config, pkgs, lib, ... }:

# Hyprland session (Lua config, Hyprland >= 0.55) — companion to the KDE
# module. The configs themselves live at the repo top level (hypr/, waybar/,
# rofi/, swaync/, wlogout/) and are linked out-of-store so edits apply
# without a home-manager switch; Hyprland hot-reloads on save.
#
# Hyprland itself comes from the distro (Arch: `pacman -S hyprland`) —
# a nix-built compositor needs working GL, which nixGL makes painful for a
# session. Everything else (bar, launcher, tools) can come from nixpkgs by
# enabling `cascadura.hyprland.packages`.

let
  cfg = config.cascadura.hyprland;
  dotfiles = "${config.home.homeDirectory}/git/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  options.cascadura.hyprland = {
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

    home.packages = lib.mkIf cfg.packages (with pkgs; [
      waybar
      swaynotificationcenter
      rofi-wayland
      wlogout
      swww # animated wallpaper transitions (scripts/wallpaper.sh)
      hyprpaper
      swaybg # wallpaper fallback where hyprpaper's GL init fails (VMs)
      swaylock # lock fallback where hyprlock's GL init fails
      imagemagick # composes the swaylock wallpaper/clock lock image
      (python3.withPackages (p: [ p.pygobject3 ])) # media popup applet
      hypridle
      hyprlock
      grim
      slurp
      swappy
      wf-recorder
      cliphist
      wl-clipboard
      brightnessctl
      playerctl
      pwvucontrol # audio mixer, shown as a bar dropdown applet
      pavucontrol # fallback mixer
      libnotify
      jq
      kdePackages.plasma-integration # Qt reads kdeglobals like under KDE
      qt6ct # fallback platform theme for machines without the above
      networkmanagerapplet # nm-connection-editor + tray applet
      blueman
      psmisc # fuser, for the camera-in-use indicator
    ]);
  };
}
