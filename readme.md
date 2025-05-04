# Dotfiles

Welcome to my dotfiles! For the most part, everything is plug-and-play (except Hyprland as of writing). Simply link the respective module to the .config directory of your home folder.

```sh
ln -s /absolute/path/to/module /home/<username>/.config/
```

# Home-Manager

This repo now focuses on using home-manager as the primary way to bootstrap common tools and configurations. Each dotfile module is provided as its own nix module, which then places the configurations in the correct location (usually ~/.config). It also uses the nixpkgs version of the binaries and substitutes the correct paths in the dotfile modules.

```sh
# Bootstrap
nix run home-manager/master -- init --switch
```

## TODO

- [ ] Move all pre-existing modules to home-manager
- [x] Move nixGL configuration to its own module
- [ ] Refactor packages code to include common modules and further customizations
    - *This is useful when deploying to diffent machines for personal or development use*
