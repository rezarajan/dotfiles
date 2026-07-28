return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    harpoon:setup {
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    }

    harpoon:extend(require('harpoon.extensions').builtins.highlight_current_file())

    harpoon:extend {
      UI_CREATE = function(cx)
        vim.keymap.set('n', '<C-v>', function()
          harpoon.ui:select_menu_item { vsplit = true }
        end, { buffer = cx.bufnr, desc = 'Open in vertical split' })

        vim.keymap.set('n', '<C-x>', function()
          harpoon.ui:select_menu_item { split = true }
        end, { buffer = cx.bufnr, desc = 'Open in horizontal split' })

        vim.keymap.set('n', '<C-t>', function()
          harpoon.ui:select_menu_item { tabedit = true }
        end, { buffer = cx.bufnr, desc = 'Open in tab' })
      end,
    }
  end,
  keys = {
    {
      '<leader>ma',
      function()
        require('harpoon'):list():add()
      end,
      desc = '[M]ark [A]dd file',
    },
    {
      '<leader>mm',
      function()
        local harpoon = require 'harpoon'
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = '[M]arks menu',
    },
    {
      '<leader>mp',
      function()
        require('harpoon'):list():prev()
      end,
      desc = '[M]ark [P]revious',
    },
    {
      '<leader>mn',
      function()
        require('harpoon'):list():next()
      end,
      desc = '[M]ark [N]ext',
    },
    {
      '<leader>1',
      function()
        require('harpoon'):list():select(1)
      end,
      desc = 'Harpoon file 1',
    },
    {
      '<leader>2',
      function()
        require('harpoon'):list():select(2)
      end,
      desc = 'Harpoon file 2',
    },
    {
      '<leader>3',
      function()
        require('harpoon'):list():select(3)
      end,
      desc = 'Harpoon file 3',
    },
    {
      '<leader>4',
      function()
        require('harpoon'):list():select(4)
      end,
      desc = 'Harpoon file 4',
    },
  },
}
