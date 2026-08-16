{ pkgs, ... }:

# Terminal greeting extras. The fish greeting (unmanaged, in
# ~/.config/fish) renders custom text logos for fastfetch via figlet:
#   fastfetch-logo oathkeeper
{
  home.packages = [
    pkgs.figlet
  ];
}
