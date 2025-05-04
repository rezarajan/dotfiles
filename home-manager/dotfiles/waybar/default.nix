{ config, pkgs, ... }:

{
  home.file.".config/waybar/themes".source = ./themes;
  home.file.".config/waybar/toggle.sh".source = 
    pkgs.replaceVars ./toggle.sh{
      theme = "catppuccin";
      waybar = pkgs.lib.getExe pkgs.waybar;
    };
}
