{ config, pkgs, ... }:

{
  home.file.".config/zellij/config.kdl".source = ./config.kdl;
  home.file.".config/zellij/layouts/default.kdl".source = 
    pkgs.replaceVars ./layouts/default.kdl{
      zjstatus = pkgs.lib.getExe pkgs.zjstatus;
    };
}
