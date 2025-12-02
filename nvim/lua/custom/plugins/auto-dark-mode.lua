local colors = require 'custom.colorscheme'
return {
  -- Lua
  {
    'f-person/auto-dark-mode.nvim',
    opts = {
      set_dark_mode = function()
        vim.api.nvim_set_option_value('background', 'dark', {})
        colors.apply 'catppuccin-mocha'
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value('background', 'light', {})
        colors.apply 'catppuccin-latte'
      end,
      update_interval = 3000,
      fallback = 'dark',
    },
  },
}
