# Custom Neovim Configuration Structure

This configuration follows kickstart.nvim best practices while maintaining your customizations in isolated files.

## Structure

```
nvim/
├── init.lua                    # Clean kickstart.nvim base (tracks upstream)
├── init.lua.custom.bkp         # Your old config (backup)
├── update-from-kickstart.sh    # Script to update from upstream
├── lua/
│   ├── custom/                 # YOUR customizations (never conflicts with upstream)
│   │   ├── options.lua         # Custom vim options
│   │   ├── keymaps.lua         # Custom keybindings
│   │   └── plugins/
│   │       └── init.lua        # Custom plugins (oil.nvim, yazi.nvim)
│   └── kickstart/              # Optional kickstart example plugins
```

**Note:** kickstart.nvim is tracked as a git remote in your dotfiles repo.
No separate folder needed!

## Your Customizations

### Options (`lua/custom/options.lua`)
- ✓ Nerd Font enabled
- ✓ Relative line numbers enabled
- ✓ Mouse disabled (keyboard-only workflow)
- ✓ Search highlighting enabled

### Keymaps (`lua/custom/keymaps.lua`)
- ✓ Diagnostic navigation: `[d`, `]d`, `<leader>e`
- ✓ Arrow keys disabled (enforce hjkl)
- ✓ Toggle relative line numbers: `<leader>n`

### Plugins (`lua/custom/plugins/init.lua`)
- ✓ oil.nvim - File manager
- ✓ yazi.nvim - Terminal file manager integration

### Appearance
- ✓ Catppuccin Latte colorscheme

## Updating from Upstream

To pull in kickstart.nvim updates:

### Easy Way: Use the Update Script

```bash
cd ~/git/dotfiles/nvim
./update-from-kickstart.sh
```

This will:
1. Fetch latest kickstart.nvim changes
2. Show recent commit history
3. Display a diff between upstream and your init.lua
4. Preserve all your customizations in lua/custom/

### Manual Way

```bash
cd ~/git/dotfiles

# Fetch latest kickstart.nvim
git fetch kickstart-nvim

# View recent changes
git log --oneline -10 kickstart-nvim/master

# Compare with your init.lua
git diff kickstart-nvim/master:init.lua nvim/init.lua

# View upstream file directly
git show kickstart-nvim/master:init.lua > /tmp/kickstart-init.lua

# Manually merge important changes to nvim/init.lua
# Then commit
git add nvim/
git commit -m "Update nvim from kickstart.nvim"
```

**Your customizations in lua/custom/ will NEVER conflict!**

## Why This Structure?

1. **Clean upstream tracking**: `init.lua` stays close to kickstart.nvim
2. **Isolated customizations**: All your changes live in `lua/custom/`
3. **No merge conflicts**: kickstart.nvim promises not to modify `lua/custom/`
4. **Easy updates**: Review and cherry-pick upstream improvements
5. **Modular**: Easy to share, version control, and understand

## Loading Order

1. `init.lua` - Base kickstart config
2. `lua/custom/options.lua` - Your option overrides
3. `init.lua` continues - Base keymaps
4. `lua/custom/keymaps.lua` - Your keymap additions
5. Lazy.nvim loads plugins (including `lua/custom/plugins/`)

## Tips

- Keep `init.lua` as close to upstream as possible
- Put ALL personal preferences in `lua/custom/`
- You can add more files: `lua/custom/autocmds.lua`, `lua/custom/commands.lua`, etc.
- The `{ import = 'custom.plugins' }` line automatically loads all plugin files in `lua/custom/plugins/`
