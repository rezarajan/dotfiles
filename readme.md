# Dotfiles

This project is a modified version of the [dotfiles](https://https://gitlab.com/stephan-raabe/dotfiles) project, originally created by [Stephan Raabe](https://gitlab.com/stephan-raabe). Though the files may diverge greatly from the original repository over time, I would still like to express my gratitude toward Stephan, for providing an intutivie framework from which I was able to bootstrap my own configs.

## Getting Started

Execute the following in a terminal:
```sh
# Clone to the home directory and symlink to ~/.config
git clone https://github.com/rezarajan/dotfiles.git ~/ \
&& cd ~/dotfiles \
&& git submodule update --init --recursive \
&& find ~/dotfiles -type f -exec ln -s {} ~/.config/ \;
```
*Please note that these config files are designed for use with Arch Linux installs with [Hyprland](https://wiki.hyprland.org/).*

## License
See the [LICENSE](LICENSE) file for license rights and limitations (GNU GPLv3).
