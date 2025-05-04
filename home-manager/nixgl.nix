{ nixgl, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Configure nixGL
  nixGL.packages = nixgl.packages;
  # see: https://mynixos.com/home-manager/option/nixGL.defaultWrapper
  # NOTE: for nvidia, the --impure option must be passed to home-manager switch
  nixGL.defaultWrapper = "nvidia"; # options one of "mesa", "mesaPrime", "nvidia", "nvidiaPrime"
  nixGL.installScripts = [ "nvidia" ];
}
