{ config, pkgs, ... }:

{
  home.file.".config/zellij/config.kdl".source = ./config.kdl;
  home.file.".config/zellij/layouts/default.kdl".source = ./layouts/default.kdl;
}
