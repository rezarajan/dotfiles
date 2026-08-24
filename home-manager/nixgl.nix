{ config, nixgl, lib, pkgs, ... }:

let
  cfg = config.dotfiles.nixGL;

  # NOTE (Using PURE eval) Change the version to match the host-installed version;
  # not necessary for --impure eval
  # Must match the RUNNING kernel module exactly — NVIDIA's userspace GL
  # refuses a version-mismatched driver, and every nixGL-wrapped GL app
  # then dies with "No GL implementation is available" (wdisplays' canvas,
  # hyprlock, hyprpaper/awww). Check with `cat /proc/driver/nvidia/version`
  # after every driver update; get the hash with
  #   nix-prefetch-url https://download.nvidia.com/XFree86/Linux-x86_64/$V/NVIDIA-Linux-x86_64-$V.run
  #   nix hash convert --hash-algo sha256 --to sri <base32>
  nvidiaVersion = "610.57.04";
  nvidiaHash = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
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
    defaultWrapper = "nvidia"; # "mesa" | "mesaPrime" | "nvidia" | "nvidiaPrime"
    installScripts = [ "nvidia" ];
  };
in {
  options.dotfiles.nixGL.pureNvidia = lib.mkOption {
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
