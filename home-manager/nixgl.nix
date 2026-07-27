{ config, nixgl, lib, pkgs, ... }:

let
  cfg = config.cascadura.nixGL;

  # NOTE (Using PURE eval) Change the version to match the host-installed version;
  # not necessary for --impure eval
  nvidiaVersion = "610.43.03";
  nvidiaHash = "sha256-ReLUwTSiPDXlDyU6SqY+fl6NF+PRhdSgfIpY6WEu05I=";
  nixGLPkgs = import nixgl.inputs.nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  nixGLPackages = import nixgl.outPath {
    pkgs = nixGLPkgs;
    inherit nvidiaVersion nvidiaHash;
    enable32bits = pkgs.stdenv.hostPlatform.isx86_64;
    enableIntelX86Extensions = pkgs.stdenv.hostPlatform.isx86_64;
  };

  withMainProgram = pkg: mainProgram:
    pkg // {
      meta = (pkg.meta or { }) // {
        inherit mainProgram;
      };
    };

  selectedNixGLPackages =
    if cfg.pureNvidia then nixGLPackages else nixgl.packages.${pkgs.stdenv.hostPlatform.system};

  patchedNixGLPackages = nixgl.packages // {
    ${pkgs.stdenv.hostPlatform.system} = selectedNixGLPackages // {
      nixGLIntel = withMainProgram selectedNixGLPackages.nixGLIntel "nixGLIntel";
      nixGLNvidia =
        withMainProgram selectedNixGLPackages.nixGLNvidia selectedNixGLPackages.nixGLNvidia.name;
      nixVulkanIntel = withMainProgram selectedNixGLPackages.nixVulkanIntel "nixVulkanIntel";
      nixVulkanNvidia =
        withMainProgram selectedNixGLPackages.nixVulkanNvidia selectedNixGLPackages.nixVulkanNvidia.name;
    };
  };

  nixGLConfig = {
    packages = patchedNixGLPackages;
    # see: https://mynixos.com/home-manager/option/nixGL.defaultWrapper
    # NOTE: for nvidia, the --impure option must be passed to home-manager switch
    defaultWrapper = "mesa"; # "mesa" | "mesaPrime" | "nvidia" | "nvidiaPrime"
    installScripts = [ "mesa" ];
  };
in {
  options.cascadura.nixGL.pureNvidia = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Use pure nixGL Nvidia wrappers pinned to driver ${nvidiaVersion}.
      When disabled, nixGL auto-detects the host Nvidia driver and Home Manager
      must be run with --impure.
    '';
  };

  config = {
    nixpkgs.config.allowUnfree = true;

    targets.genericLinux.nixGL = lib.mkIf pkgs.stdenv.isLinux nixGLConfig;
  };
}
