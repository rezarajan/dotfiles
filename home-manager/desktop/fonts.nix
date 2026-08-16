{ pkgs, ... }:

# UI typography: Inter for interface text (screen-first, closest free
# relative of SF Pro), JetBrains Mono for fixed-width. Rendering is grayscale
# antialiasing with slight hinting — crisp and identical on any subpixel
# layout (RGB/BGR/rotated/OLED) and at fractional scales, which per-channel
# subpixel rendering is not.
{
  home.packages = [
    pkgs.inter
    pkgs.jetbrains-mono
  ];

  # required on non-NixOS so fontconfig sees nix-installed fonts
  fonts.fontconfig.enable = true;

  xdg.configFile."fontconfig/conf.d/50-ui-fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <!-- generic family bindings -->
      <alias>
        <family>sans-serif</family>
        <prefer><family>Inter</family></prefer>
      </alias>
      <alias>
        <family>monospace</family>
        <prefer><family>JetBrains Mono</family></prefer>
      </alias>

      <!-- crisp, layout-agnostic rendering -->
      <match target="font">
        <edit name="antialias" mode="assign"><bool>true</bool></edit>
        <edit name="hinting" mode="assign"><bool>true</bool></edit>
        <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
        <edit name="rgba" mode="assign"><const>none</const></edit>
        <edit name="lcdfilter" mode="assign"><const>lcdnone</const></edit>
        <edit name="autohint" mode="assign"><bool>false</bool></edit>
        <edit name="embeddedbitmap" mode="assign"><bool>false</bool></edit>
      </match>
    </fontconfig>
  '';

  # KDE-wide fonts (GTK apps follow via kde-gtk-config's font sync)
  qt.kde.settings.kdeglobals.General = {
    font = "Inter,10.5,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0";
    menuFont = "Inter,10.5,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0";
    toolBarFont = "Inter,10.5,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0";
    smallestReadableFont = "Inter,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0";
    fixed = "JetBrains Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0";
  };

  # window titles slightly heavier, macOS-style
  qt.kde.settings.kdeglobals.WM = {
    activeFont = "Inter,10.5,-1,5,500,0,0,0,0,0,0,0,0,0,0,1,Medium,0,0";
  };
}
