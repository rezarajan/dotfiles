{ nixgl, lib, pkgs, ... }:

let
  nixGLConfig = {
    packages = nixgl.packages;
    # see: https://mynixos.com/home-manager/option/nixGL.defaultWrapper
    # NOTE: for nvidia, the --impure option must be passed to home-manager switch
    defaultWrapper = "nvidia"; # "mesa" | "mesaPrime" | "nvidia" | "nvidiaPrime"
    installScripts = [ "nvidia" ];
  };
in {
  nixpkgs.config.allowUnfree = true;

  targets.genericLinux.nixGL = lib.mkIf pkgs.stdenv.isLinux nixGLConfig;
}
