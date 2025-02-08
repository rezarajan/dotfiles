{
  description = "Home Manager configuration of cascadura";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
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
      pkgs = nixpkgs.legacyPackages.${system};
      overlays = {
        pkgs = final: prev: {
            zjstatus = zjstatus.packages.${prev.system}.default;
            ghostty = ghostty.packages.${prev.system}.default;
        };
      };
    in {
      homeConfigurations."cascadura" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit nixgl; };

        # Specify your home configuration modules here, for example,
        modules = [
          ./home.nix
          ({
            nixpkgs.overlays = [ overlays.pkgs ];
          })
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}
