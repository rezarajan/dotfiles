{ pkgs, ... }:

# Terminal layer: fish config + the animated fastfetch greeting system.
#
# fish_greeting (ghostty-only) runs fastfetch-animated: size-adaptive
# logo selection with live resize handling, a continual color wave over
# ascii logos, ascii frame-flipping, and kitty-graphics png frame
# flipping for the animated Oathkeeper keyblade (master vector art with
# SMIL animation in ./fastfetch/oathkeeper.svg; frames regenerate via
# ./fastfetch/tools/keyblade_gen.py). Active logo selection lives in
# fish universal variables (mutable, not managed here) — switch with:
#   fastfetch-logo ~/.config/fastfetch/oathkeeper-frames-png  # keyblade
#   fastfetch-logo oathkeeper                                 # figlet text
#   fastfetch-logo --clear                                    # distro logo
#
# NOTE: config.fish is store-managed now, so tools that append to it
# (e.g. `lms bootstrap`) will fail — add such lines here instead.
{
  home.packages = [
    pkgs.figlet
  ];

  xdg.configFile = {
    "fish/config.fish" = {
      force = true;
      source = ./fish/config.fish;
    };

    "fish/functions/fastfetch-animated.fish" = {
      force = true;
      source = ./fish/functions/fastfetch-animated.fish;
    };

    "fish/functions/fastfetch-logo.fish" = {
      force = true;
      source = ./fish/functions/fastfetch-logo.fish;
    };

    "fastfetch/kitty_transmit.py" = {
      force = true;
      source = ./fastfetch/tools/kitty_transmit.py;
    };

    "fastfetch/cachyos.png" = {
      force = true;
      source = ./fastfetch/cachyos.png;
    };

    "fastfetch/oathkeeper.svg" = {
      force = true;
      source = ./fastfetch/oathkeeper.svg;
    };

    "fastfetch/oathkeeper-frames" = {
      force = true;
      source = ./fastfetch/oathkeeper-frames-ascii;
    };

    "fastfetch/oathkeeper-frames-png" = {
      force = true;
      source = ./fastfetch/oathkeeper-frames-png;
    };
  };
}
