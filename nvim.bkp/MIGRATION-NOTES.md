# Migration Notes - Kickstart.nvim Restructure

## What Changed

Your Neovim configuration has been restructured to follow kickstart.nvim best practices.

### Before
- Single `init.lua` with all customizations mixed with kickstart code
- Hard to update from upstream without merge conflicts
- Difficult to identify your customizations vs. base config

### After
- Clean `init.lua` that tracks kickstart.nvim upstream
- All customizations isolated in `lua/custom/` directory
- Easy to update from upstream - just review and merge changes
- Your customizations preserved in modular files

## File Mapping

| Old Location | New Location | Purpose |
|--------------|--------------|---------|
| `init.lua` lines 94 | `lua/custom/options.lua` | Nerd font setting |
| `init.lua` lines 105 | `lua/custom/options.lua` | Relative line numbers |
| `init.lua` lines 108 | `lua/custom/options.lua` | Mouse disabled |
| `init.lua` lines 161 | `lua/custom/options.lua` | Search highlighting |
| `init.lua` lines 165-167 | `lua/custom/keymaps.lua` | Diagnostic keymaps |
| `init.lua` lines 179-182 | `lua/custom/keymaps.lua` | Arrow key disable |
| `init.lua` lines 197-203 | `lua/custom/keymaps.lua` | Relative number toggle |
| `init.lua` lines 842-849 | Still in `init.lua` | Catppuccin colorscheme |
| `lua/custom/plugins/init.lua` | `lua/custom/plugins/init.lua` | Your plugins (unchanged) |

## Preserved Customizations

✓ Nerd Font icons enabled
✓ Relative line numbers enabled  
✓ Mouse disabled
✓ Search highlighting enabled
✓ Additional diagnostic keymaps ([d, ]d, <leader>e)
✓ Arrow keys disabled to enforce hjkl
✓ Toggle relative line numbers (<leader>n)
✓ Oil.nvim file manager
✓ Yazi.nvim integration
✓ Catppuccin Latte colorscheme
✓ Which-key groups (Code, Document, Oil, Rename, Workspace)

## Backup

Your original config is saved as:
- `init.lua.custom.bkp` - Your old customized init.lua

## Next Steps

1. Test your config: `nvim`
2. If everything works, you can delete `init.lua.custom.bkp`
3. Update from kickstart.nvim anytime with the process in README-CUSTOM.md
4. Add more customizations to `lua/custom/` files as needed

## Rollback

If needed, you can rollback:
```bash
cd ~/git/dotfiles/nvim
mv init.lua init.lua.new
mv init.lua.custom.bkp init.lua
```
