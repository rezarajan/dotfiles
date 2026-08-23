# 🏠 Dotfiles

My personal configuration files for Arch Linux with Wayland, managed through Home Manager and traditional symlinks.

<div align="center">

**Tools & Apps**

[![Neovim](https://img.shields.io/badge/Neovim-57A143?style=flat&logo=neovim&logoColor=white)](nvim/)
[![Hyprland](https://img.shields.io/badge/Hyprland-00B4D8?style=flat&logo=wayland&logoColor=white)](hypr/)
[![Ghostty](https://img.shields.io/badge/Ghostty-282828?style=flat&logoColor=white)](ghostty/)
[![Home Manager](https://img.shields.io/badge/Home_Manager-5277C3?style=flat&logo=nixos&logoColor=white)](home-manager/)

</div>

---

## 📦 What's Inside

### Core Applications
- **[nvim/](nvim/)** - Neovim config based on kickstart.nvim with custom plugins (Oil, Yazi)
- **[ghostty/](ghostty/)** - Terminal emulator (default everywhere: Hyprland, rofi, KDE)
- **[home-manager/](home-manager/)** - Nix-based declarative configuration management

### Wayland Environment (Gruvbox Dragon)
- **[hypr/](hypr/)** - Hyprland compositor, configured in **Lua** (Hyprland ≥ 0.55) — see [hypr/readme.md](hypr/readme.md)
- **[waybar/](waybar/)** - Status bar (flush top panel, KDE-panel layout)
- **[rofi/](rofi/)** - Application launcher + device/clipboard pickers
- **[swaync/](swaync/)** - Notification center (history, DND, volume slider)
- **[wlogout/](wlogout/)** - Session menu
- **[sddm/](sddm/)** - Display manager theme

All Wayland-stack colors are generated from the same
`home-manager/desktop/kvantum/tools/palette.py` that themes KDE/GTK/Qt;
dark/light switching is one command (`hypr/scripts/theme-mode.sh toggle`).

### Desktop Environment
- **[kde/](kde/)** - KDE Plasma configuration
- **[xdg-desktop-portal/](xdg-desktop-portal/)** - Desktop integration

### Other Tools
- **[starship/](starship/)** - Cross-shell prompt
- **[pipewire/](pipewire/)** - Audio configuration
- **[freeze/](freeze/)** - Code screenshot tool
- **[wallpapers/](wallpapers/)** - Background images

---

## 🚀 Quick Start

### Method 1: Home Manager (Recommended)

Home Manager provides declarative configuration management with Nix.

#### Initial Setup

```bash
# Install Nix (if not already installed)
curl -L https://nixos.org/nix/install | sh

# Bootstrap Home Manager
nix run home-manager/master -- init --switch

# Clone this repo
git clone https://github.com/yourusername/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles

# Link your home-manager config
ln -s ~/git/dotfiles/home-manager ~/.config/home-manager

# Apply configuration
home-manager switch
```

#### Update Configuration

```bash
cd ~/git/dotfiles
git pull
home-manager switch
```

### Method 2: Traditional Symlinks

For configs not yet managed by Home Manager, use symlinks:

```bash
# Clone the repo
git clone https://github.com/yourusername/dotfiles.git ~/git/dotfiles

# Link individual configs
ln -sf ~/git/dotfiles/nvim ~/.config/nvim
ln -sf ~/git/dotfiles/ghostty ~/.config/ghostty
ln -sf ~/git/dotfiles/hypr ~/.config/hypr
ln -sf ~/git/dotfiles/waybar ~/.config/waybar
# ... and so on
```

---

## 📝 Neovim Configuration

### Features
- ✨ Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- 🎨 Catppuccin Latte colorscheme
- 📁 Oil.nvim file manager
- 🖼️ Yazi.nvim integration
- ⚡ Custom keybindings and options

### Structure
```
nvim/
├── init.lua              # Base kickstart.nvim config
├── lua/
│   ├── custom/           # Your customizations
│   │   ├── options.lua   # Custom vim options
│   │   ├── keymaps.lua   # Custom keybindings
│   │   └── plugins/      # Custom plugins
│   └── kickstart/        # Optional kickstart plugins
└── README-CUSTOM.md      # Detailed nvim documentation
```

### Setup

```bash
# Link config
ln -sf ~/git/dotfiles/nvim ~/.config/nvim

# Open Neovim (plugins will auto-install)
nvim
```

### Update from Upstream

Pull latest kickstart.nvim changes automatically:

```bash
cd ~/git/dotfiles
git subtree pull --prefix nvim https://github.com/nvim-lua/kickstart.nvim.git master --squash
```

Or use the provided script:

```sh
cd ~/git/dotfiles
./scripts/update-nvim-subtree.sh
``

Your customizations in `lua/custom/` are preserved automatically!

See [nvim/CUSTOMIZING.md](nvim/CUSTOMIZING.md) for detailed information.

---

## 🏗️ Home Manager Integration

### Current Status

Home Manager manages:
- Core utilities and packages
- Shell configuration
- Environment variables
- Session paths

### File Structure

```
home-manager/
├── home.nix          # Main configuration
├── pkgs.nix          # Package definitions (if exists)
├── nixgl.nix         # Graphics-based packages (required for non nix-os installs)
└── dotfiles/         # Customizations to installed packages
```

### Configuration Example

Edit `home-manager/home.nix`:

```nix
{
  home.packages = with pkgs; [
    neovim
    # ... your packages
  ];

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
  };
}
```

### Adding Neovim to Home Manager

Add to `home-manager/home.nix`:

```nix
xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink 
  "${config.home.homeDirectory}/git/dotfiles/nvim";
```

This creates a symlink from `~/.config/nvim` to `~/git/dotfiles/nvim`.

---

## 🔧 Configuration Tips

### Linking Configs to ~/.config

```bash
# Single config
ln -sf ~/git/dotfiles/<config-name> ~/.config/<config-name>

# Multiple configs
for dir in nvim ghostty hypr waybar rofi; do
  ln -sf ~/git/dotfiles/$dir ~/.config/$dir
done
```

### Managing Secrets

Never commit secrets! Use:
- Environment variables
- `~/.config/<app>/local.conf` (add to .gitignore)
- [sops-nix](https://github.com/Mic92/sops-nix) for Home Manager

---

## 📋 TODO

- [ ] Move all pre-existing modules to home-manager
- [x] Move nixGL configuration to its own module
- [x] Restructure Neovim config for upstream tracking
- [ ] Refactor packages code to include common modules and further customizations
  - *Useful when deploying to different machines for personal or development use*
- [x] Document Hyprland setup fully (see [hypr/readme.md](hypr/readme.md))
- [ ] Add screenshots and demos

---

## 📄 License

See [LICENSE](LICENSE) file.

---

## 🙏 Credits

- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) - Neovim configuration base
- [Nix](https://nixos.org/) & [Home Manager](https://github.com/nix-community/home-manager) - Configuration management
- All the amazing open-source projects that make this possible
