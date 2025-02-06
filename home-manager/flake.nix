{
  description = "Home Manager configuration of cascadura";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zjstatus = {
      url = "github:dj95/zjstatus";
    };
  };

  outputs = { nixpkgs, home-manager, zjstatus, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      overlays = {
        zjstatus = final: prev: {
            zjstatus = zjstatus.packages.${prev.system}.default;
        };
      };
    in {
      homeConfigurations."cascadura" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix, or any overlays.
        modules = [
          ./home.nix
          ({
            nixpkgs.overlays = [ overlays.zjstatus ];
          })
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}
