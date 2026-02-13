-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- Load colorscheme from separate file
local colorscheme = require 'custom.colorscheme'

return vim.list_extend(colorscheme, {
  {
    'stevearc/oil.nvim',
    opts = {
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
        -- This function defines what is considered a "hidden" file
        is_hidden_file = function(name, bufnr)
          return vim.startswith(name, '.')
        end,
        -- This function defines what will never be shown, even when `show_hidden` is set
        is_always_hidden = function(name, bufnr)
          return false
        end,
        -- Sort file names in a more intuitive order for humans. Is less performant,
        -- so you may want to set to false if you work with large directories.
        natural_order = true,
        sort = {
          -- sort order can be "asc" or "desc"
          -- see :help oil-columns to see which columns are sortable
          { 'type', 'asc' },
          { 'name', 'asc' },
        },
      },
    },
    -- Optional dependencies
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },
  {
    'mikavilpas/yazi.nvim',
    version = '*',
    event = 'VeryLazy',
    dependencies = {
      { 'nvim-lua/plenary.nvim', lazy = true },
    },
    keys = {
      {
        '<leader>-',
        mode = { 'n', 'v' },
        '<cmd>Yazi<cr>',
        desc = 'Open yazi at the current file',
      },
      {
        '<leader>cw',
        '<cmd>Yazi cwd<cr>',
        desc = "Open yazi at nvim's cwd",
      },
      {
        '<C-Up>',
        '<cmd>Yazi toggle<cr>',
        desc = 'Resume last yazi session',
      },
    },
    ---@type YaziConfig | {}
    opts = {
      open_for_directories = false, -- set to true if you want Yazi to replace netrw/oil
      keymaps = {
        show_help = '<F1>',
      },
    },
    init = function()
      -- If you want Yazi to replace netrw completely,
      -- set `open_for_directories = true` above AND add this:
      vim.g.loaded_netrwPlugin = 1
    end,
  },
})
