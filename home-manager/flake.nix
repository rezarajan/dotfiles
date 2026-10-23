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
    # nixGL must follow OUR nixpkgs: its own pin is 2022 (Mesa 22.1.4,
    # libglvnd 1.4.0), and the wrapper PREPENDS those libs to
    # LD_LIBRARY_PATH, so every wrapped app ran a 2022 GL stack under its
    # 2026 libraries. Harmless on an NVIDIA-only box (Mesa finds no device
    # and falls back to llvmpipe), but on an Intel iGPU it drives real
    # hardware with an ancient iris and hung the GPU, taking KWin down.
    nixgl = {
      url = "github:nix-community/nixGL/pull/187/head";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux"; # 🔧 change if needed
      pkgs = import nixpkgs {
        inherit system;

        overlays = [
          (final: prev: {
          })
        ];
      };
    in {
      homeConfigurations."cascadura" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          inherit nixgl;
        };

        # Specify your home configuration modules here, for example,
        modules = [
          ./home.nix
          ./nixgl.nix
          ./pkgs.nix
          ./desktop/kde.nix
          ./desktop/hyprland.nix
          ./desktop/browser.nix
          ./desktop/fonts.nix
          ./desktop/terminal.nix
          ./dotfiles/default.nix
        ];
      };
    };
}
