return {
  'Vigemus/iron.nvim',
  dependencies = {
    'linux-cultist/venv-selector.nvim',
  },
  config = function()
    local iron = require 'iron.core'

    iron.setup {
      config = {
        -- Whether a repl should be discarded or not
        scratch_repl = true,
        -- Your repl definitions come here
        repl_definition = {
          sh = {
            -- Can be a table or a function that
            -- returns a table (see below)
            command = { 'zsh' },
          },
          python = {
            -- Use function to dynamically get python from venv
            command = function()
              local venv = require('venv-selector').venv()
              if venv then
                -- Try ipython first, fall back to python
                local ipython = venv .. '/bin/ipython'
                if vim.fn.executable(ipython) == 1 then
                  return { ipython, '--no-autoindent' }
                else
                  return { venv .. '/bin/python' }
                end
              else
                -- Try system ipython first
                if vim.fn.executable 'ipython' == 1 then
                  return { 'ipython', '--no-autoindent' }
                else
                  return { 'python3' }
                end
              end
            end,
            format = require('iron.fts.common').bracketed_paste_python,
            block_dividers = { '# %%', '#%%' },
            env = { PYTHON_BASIC_REPL = '1' },
          },
        },
        -- How the repl window will be displayed
        -- Opens in a vertical split on the right side with 40% of screen width
        repl_open_cmd = require('iron.view').right '40%',
      },
      -- Iron doesn't set keymaps by default anymore.
      -- You can set them here or manually add keymaps to the features you want
      keymaps = {
        send_motion = '<space>rc',
        visual_send = '<space>rc',
        send_file = '<space>rf',
        send_line = '<space>rl',
        send_paragraph = '<space>rp',
        send_until_cursor = '<space>ru',
        send_mark = '<space>rm',
        mark_motion = '<space>rmc',
        mark_visual = '<space>rmc',
        remove_mark = '<space>rmd',
        cr = '<space>r<cr>',
        interrupt = '<space>r<space>',
        exit = '<space>rq',
        clear = '<space>rx',
      },
      -- If the highlight is on, you can change how it looks
      -- For the available options, check nvim_set_hl
      highlight = {
        italic = true,
      },
      ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
    }

    -- iron also has a list of commands, see :h iron-commands for all available commands
    vim.keymap.set('n', '<space>rs', '<cmd>IronRepl<cr>', { desc = '[R]EPL [S]tart' })
    vim.keymap.set('n', '<space>rr', '<cmd>IronRestart<cr>', { desc = '[R]EPL [R]estart' })
    vim.keymap.set('n', '<space>rF', '<cmd>IronFocus<cr>', { desc = '[R]EPL [F]ocus' })
    vim.keymap.set('n', '<space>rh', '<cmd>IronHide<cr>', { desc = '[R]EPL [H]ide (minimize)' })
  end,
}
