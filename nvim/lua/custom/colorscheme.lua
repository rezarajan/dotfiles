-- Custom colorscheme configuration
-- This file is loaded after plugins are set up

return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000, -- Load before other plugins
    config = function()
      -- You can customize catppuccin here if needed
      -- require('catppuccin').setup({
      --   flavour = 'latte', -- latte, frappe, macchiato, mocha
      --   transparent_background = false,
      --   term_colors = true,
      -- })
      
      vim.cmd.colorscheme 'catppuccin-latte'
    end,
  },
  
  -- Alternative themes (commented out)
  -- Uncomment to switch themes
  
  -- {
  --   'folke/tokyonight.nvim',
  --   priority = 1000,
  --   config = function()
  --     require('tokyonight').setup({
  --       style = 'night', -- storm, moon, night, day
  --       styles = {
  --         comments = { italic = false },
  --       },
  --     })
  --     vim.cmd.colorscheme 'tokyonight-night'
  --   end,
  -- },
  
  -- {
  --   'ellisonleao/gruvbox.nvim',
  --   priority = 1000,
  --   config = function()
  --     vim.o.background = 'dark' -- or 'light'
  --     vim.cmd.colorscheme 'gruvbox'
  --   end,
  -- },
}
