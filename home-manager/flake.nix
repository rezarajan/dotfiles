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
  };

  outputs = { nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux"; # 🔧 change if needed
      pkgs = import nixpkgs {
        inherit system;

        # NOTE: nixpkgs' cargoSetupHook (cargoUseSystemLibs) makes every
        # buildRustPackage link SYSTEM libraries instead of the copies bundled
        # in -sys crates, by exporting e.g. ZSTD_SYS_USE_PKG_CONFIG=1,
        # AWS_LC_SYS_USE_SYSTEM=1, OPENSSL_NO_VENDOR=1, LIBGIT2_NO_VENDOR=1,
        # LIBSQLITE3_SYS_USE_PKG_CONFIG=1, RUSTONIG_SYSTEM_LIBONIG=1 (full list:
        # pkgs/build-support/rust/hooks/cargo-setup-hook.sh). A package that
        # doesn't declare those libraries in buildInputs then fails in the
        # crate's build script, e.g.
        #   zstd-sys: "The system library `libzstd` ... was not found"
        #   aws-lc-sys: "AWS_LC_SYS_USE_SYSTEM=1 requires a system-installed
        #               AWS-LC, but none was found"
        # This is intended (nixpkgs PR #537108): packages must now declare the
        # system libraries their -sys crates use. Packages not yet migrated
        # break until fixed (tracking: NixOS/nixpkgs#570943); codex 0.167.0
        # was one, 0.167.1 fixed it. Not a host problem — it fails on NixOS too.
        # Prefer `nix flake update nixpkgs` once unstable carries the fix.
        # Until then, add the libraries one crate at a time: fix the first
        # failure, rebuild, repeat (build scripts fail one by one, and nixpkgs
        # master's package.nix usually lists the full set):
        #
        #   codex = prev.codex.overrideAttrs (old: {
        #     buildInputs = old.buildInputs ++ [
        #       final.aws-lc     # aws-lc-sys
        #       final.oniguruma  # onig_sys
        #       final.sqlite     # libsqlite3-sys
        #       final.zstd       # zstd-sys
        #     ];
        #   });
        #
        # Last resort, back to the bundled copies for every crate in the
        # package: `dontCargoUseSystemLibs = true;` in the same overrideAttrs.
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
