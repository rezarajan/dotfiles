-- Custom coding keymaps for LSP, symbols, and debugging
-- These are loaded after LSP attaches, complementing the default kickstart mappings

local M = {}

-- Enhanced LSP keymaps that extend kickstart.nvim defaults
function M.setup_lsp_keymaps(event)
  local map = function(keys, func, desc)
    vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
  end

  -- Symbol navigation (non-conflicting with kickstart defaults)
  -- Use <leader>s prefix for LSP symbols
  map('<leader>sy', require('telescope.builtin').lsp_document_symbols, '[S]earch s[Y]mbols in document')
  map('<leader>sY', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[S]earch s[Y]mbols in workspace')
  
  -- Class and function navigation
  map('<leader>sc', function()
    require('telescope.builtin').lsp_document_symbols({ symbols = { 'class', 'struct' } })
  end, '[S]earch [C]lasses')
  
  map('<leader>sm', function()
    require('telescope.builtin').lsp_document_symbols({ symbols = { 'function', 'method' } })
  end, '[S]earch [M]ethods/functions')
  
  map('<leader>si', function()
    require('telescope.builtin').lsp_document_symbols({ symbols = { 'interface', 'enum' } })
  end, '[S]earch [I]nterfaces')

  -- Enhanced diagnostics
  map('<leader>dd', vim.diagnostic.open_float, '[D]iagnostic [D]etails')
  map('<leader>dl', vim.diagnostic.setloclist, '[D]iagnostic [L]ist')
  map('<leader>da', vim.lsp.buf.code_action, '[D]iagnostic [A]ction')
  
  -- Diagnostic severity filtering
  map('<leader>de', function()
    vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.ERROR })
  end, '[D]iagnostic [E]rrors only')
  
  map('<leader>dw', function()
    vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.WARN })
  end, '[D]iagnostic [W]arnings only')

  -- Workspace operations
  map('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd folder')
  map('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove folder')
  map('<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[W]orkspace [L]ist folders')
end

-- Debug/inspection keymaps
function M.setup_debug_keymaps()
  -- LSP info and logs
  vim.keymap.set('n', '<leader>li', '<cmd>LspInfo<cr>', { desc = '[L]SP [I]nfo' })
  vim.keymap.set('n', '<leader>ll', '<cmd>LspLog<cr>', { desc = '[L]SP [L]og' })
  vim.keymap.set('n', '<leader>lr', '<cmd>LspRestart<cr>', { desc = '[L]SP [R]estart' })
  
  -- Inspect element under cursor
  vim.keymap.set('n', '<leader>ui', vim.show_pos, { desc = '[U]I [I]nspect highlight groups' })
  vim.keymap.set('n', '<leader>ut', '<cmd>Inspect<cr>', { desc = '[U]I Inspect [T]reesitter' })
  
  -- Buffer and syntax info
  vim.keymap.set('n', '<leader>ub', function()
    print(string.format('Buffer: %s | FileType: %s | Encoding: %s', 
      vim.fn.expand('%'), vim.bo.filetype, vim.bo.fileencoding))
  end, { desc = '[U]I [B]uffer info' })
end

-- Code navigation helpers
function M.setup_navigation_keymaps()
  -- NOTE: LSP document symbols don't include class hierarchy in symbol names
  -- Use <leader>ss to see all symbols, then filter in Telescope
  -- Or use <leader>sf to see all functions/methods
  
  -- Quick jump to next/previous function
  vim.keymap.set('n', ']f', function()
    require('telescope.builtin').lsp_document_symbols({ 
      symbols = { 'function', 'method' },
      default_text = ':next:',
    })
  end, { desc = 'Next [f]unction' })
  
  vim.keymap.set('n', '[f', function()
    require('telescope.builtin').lsp_document_symbols({ 
      symbols = { 'function', 'method' },
      default_text = ':prev:',
    })
  end, { desc = 'Previous [f]unction' })
  
  -- Jump to next/previous class
  vim.keymap.set('n', ']c', function()
    require('telescope.builtin').lsp_document_symbols({ 
      symbols = { 'class', 'struct' },
      default_text = ':next:',
    })
  end, { desc = 'Next [c]lass' })
  
  vim.keymap.set('n', '[c', function()
    require('telescope.builtin').lsp_document_symbols({ 
      symbols = { 'class', 'struct' },
      default_text = ':prev:',
    })
  end, { desc = 'Previous [c]lass' })
end

-- Auto-setup function to be called from init.lua
function M.setup()
  -- Setup debug and navigation keymaps immediately
  M.setup_debug_keymaps()
  M.setup_navigation_keymaps()
  
  -- Setup LSP keymaps when LSP attaches
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('custom-lsp-attach', { clear = true }),
    callback = function(event)
      M.setup_lsp_keymaps(event)
    end,
  })
end

return M
