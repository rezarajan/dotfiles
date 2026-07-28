{ config, pkgs, lib, ... }:

let
  # Import all dotfile modules
  dotfileModules = [
    ./zellij/default.nix
    ./yazi/default.nix
    ./zed/default.nix
    # ./waybar/default.nix
    # Add more here...
  ];
in
{
  imports = dotfileModules;
}
