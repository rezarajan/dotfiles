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

-- Tab workflow
vim.keymap.set('n', 'gT', '<cmd>tabprevious<CR>', { desc = 'Previous tab' })
vim.keymap.set('n', 'gt', '<cmd>tabnext<CR>', { desc = 'Next tab' })
vim.keymap.set('n', '[t', '<cmd>tabprevious<CR>', { desc = 'Previous tab' })
vim.keymap.set('n', ']t', '<cmd>tabnext<CR>', { desc = 'Next tab' })
vim.keymap.set('n', '<leader>Tn', '<cmd>tabnew<CR>', { desc = '[T]ab [N]ew' })
vim.keymap.set('n', '<leader>Tc', '<cmd>tabclose<CR>', { desc = '[T]ab [C]lose' })
vim.keymap.set('n', '<leader>To', '<cmd>tabonly<CR>', { desc = '[T]ab [O]nly' })
vim.keymap.set('n', '<leader>Tl', '<cmd>tabnext<CR>', { desc = '[T]ab Right' })
vim.keymap.set('n', '<leader>Th', '<cmd>tabprevious<CR>', { desc = '[T]ab Left' })

for i = 1, 9 do
  vim.keymap.set('n', '<leader>T' .. i, '<cmd>tabnext ' .. i .. '<CR>', { desc = 'Go to tab ' .. i })
end

-- Split navigation and resizing. Keeping these outside lazy.nvim plugin specs
-- makes them easy to reload with :luafile lua/custom/keymaps.lua.
vim.keymap.set('n', '<C-h>', function()
  require('smart-splits').move_cursor_left()
end, { desc = 'Move focus left' })
vim.keymap.set('n', '<C-j>', function()
  require('smart-splits').move_cursor_down()
end, { desc = 'Move focus down' })
vim.keymap.set('n', '<C-k>', function()
  require('smart-splits').move_cursor_up()
end, { desc = 'Move focus up' })
vim.keymap.set('n', '<C-l>', function()
  require('smart-splits').move_cursor_right()
end, { desc = 'Move focus right' })
vim.keymap.set('n', '<C-\\>', function()
  require('smart-splits').move_cursor_previous()
end, { desc = 'Move focus previous' })
vim.keymap.set('n', '<A-h>', function()
  require('smart-splits').resize_left()
end, { desc = 'Resize split left' })
vim.keymap.set('n', '<A-j>', function()
  require('smart-splits').resize_down()
end, { desc = 'Resize split down' })
vim.keymap.set('n', '<A-k>', function()
  require('smart-splits').resize_up()
end, { desc = 'Resize split up' })
vim.keymap.set('n', '<A-l>', function()
  require('smart-splits').resize_right()
end, { desc = 'Resize split right' })

-- Commented out Oil keymap (defined in plugin config instead)
-- vim.keymap.set('n', '<leader>o', '<cmd>Oil<CR>', { desc = 'Open Oil' })
