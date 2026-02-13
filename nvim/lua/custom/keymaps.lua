-- Custom keymaps that extend kickstart.nvim defaults
-- This file is loaded after the main init.lua keymaps

-- Additional diagnostic keymaps (kickstart only has <leader>q)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })

-- Disable arrow keys in normal mode (enforce hjkl)
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Toggle relative line numbers
vim.keymap.set('n', '<leader>n', function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = 'Toggle Relative Line [N]umbers' })

-- Commented out Oil keymap (defined in plugin config instead)
-- vim.keymap.set('n', '<leader>o', '<cmd>Oil<CR>', { desc = 'Open Oil' })
