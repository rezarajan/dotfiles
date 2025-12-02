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
