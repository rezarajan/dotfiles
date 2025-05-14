{ config, pkgs, ... }:

let
  # Define the source of the script with variables to be replaced
  toggleScript = pkgs.writeShellScriptBin "toggle.sh" (
    pkgs.replaceVars ./toggle.sh {
      theme = "catppuccin";  # Theme to be replaced
      waybar = pkgs.lib.getExe pkgs.waybar;  # Waybar executable path
    });
in
{
  home.file.".config/waybar/themes".source = ./themes;
  home.file.".config/waybar/toggle.sh".source = pkgs.lib.getExe toggleScript;
}
