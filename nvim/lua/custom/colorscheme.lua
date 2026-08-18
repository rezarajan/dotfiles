local M = {}

----------------------------------------------------------------------
-- 1. Plugin specifications (lazy.nvim)
--    These get imported from your "plugins" folder the Kickstart way
----------------------------------------------------------------------

M.plugins = {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        float = {
          transparent = false, -- enable transparent floating windows
          solid = false, -- use solid styling for floating windows, see |winborder|
        },
      }
    end,
  },

  {
    'folke/tokyonight.nvim',
    name = 'tokyonight',
    priority = 1000,
    lazy = true,
    config = function()
      require('tokyonight').setup {}
    end,
  },

  {
    'ellisonleao/gruvbox.nvim',
    name = 'gruvbox',
    priority = 1000,
    lazy = true,
  },
}

----------------------------------------------------------------------
-- Terminal cursor visibility (gruvbox)
--
-- gruvbox.nvim defines Cursor as bare reverse-video with no colors, so
-- the TUI never sets the terminal cursor color (no OSC 12) and the
-- cursor keeps whatever color ghostty last had — after a live
-- light/dark theme switch that can be cream-on-cream (invisible).
-- Give Cursor explicit per-background colors (the Gruvbox Material
-- cursor palette, matching ghostty's themes) so nvim owns the cursor
-- color in both modes and resets it on exit (OSC 112).
----------------------------------------------------------------------

local cursor_colors = {
  dark = { bg = '#d4be98', fg = '#282828' },
  light = { bg = '#654735', fg = '#fbf1c7' },
}

vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = 'gruvbox',
  group = vim.api.nvim_create_augroup('custom-cursor-color', { clear = true }),
  callback = function()
    local c = cursor_colors[vim.o.background] or cursor_colors.dark
    vim.api.nvim_set_hl(0, 'Cursor', { bg = c.bg, fg = c.fg })
    vim.api.nvim_set_hl(0, 'lCursor', { link = 'Cursor' })
  end,
})

-- The default 'guicursor' names no highlight group for normal/insert, so
-- the Cursor colors above would never reach the terminal without this.
vim.o.guicursor = 'n-v-c-sm:block-Cursor/lCursor,i-ci-ve:ver25-Cursor/lCursor,r-cr-o:hor20-Cursor/lCursor,t:block-blinkon500-blinkoff500-TermCursor'

----------------------------------------------------------------------
-- 2. Generic API (works with ANY theme)
----------------------------------------------------------------------

-- Safely apply a colorscheme
function M.apply(name)
  local ok = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify('Colorscheme not found: ' .. name, vim.log.levels.ERROR)
  end
end

-- Convenience loader: vendor + variant
-- Example: M.set("catppuccin", "frappe")
--          M.set("tokyonight", "night")
function M.set(theme, variant)
  local scheme = variant and (theme .. '-' .. variant) or theme
  M.apply(scheme)
end

return M
