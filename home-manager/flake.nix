{
  description = "Home Manager configuration of cascadura";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixgl = {
    #   url = "github:nix-community/nixGL";
    # };
    # NOTE: Use this PR for compat with new nvidia-open drivers
    nixgl = {
      url = "github:nix-community/nixGL/pull/187/head";
    };
    zjstatus = {
      url = "github:dj95/zjstatus";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, zjstatus, ghostty, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            zjstatus = zjstatus.packages.${prev.system}.default;
            ghostty = ghostty.packages.${prev.system}.default;
          })
        ];
      };
    in {
      homeConfigurations."cascadura" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = { inherit nixgl; };

        # Specify your home configuration modules here, for example,
        modules = [
          ./home.nix
          ./nixgl.nix
          ./pkgs.nix 
          ./dotfiles/default.nix
        ];
      };
    };
}
