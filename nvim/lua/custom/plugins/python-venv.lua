-- Python virtual environment support
-- Automatically detect and activate venv for proper LSP/linting

return {
  'linux-cultist/venv-selector.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
    'nvim-telescope/telescope.nvim',
    'mfussenegger/nvim-dap-python',
  },
  opts = {
    -- Auto select venv when entering Python files
    auto_refresh = true,
    
    -- Search patterns for finding venvs
    name = {
      'venv',
      '.venv',
      'env',
      '.env',
      'virtualenv',
    },
    
    -- Path patterns to search for venvs
    path = '.',
    
    -- Parents to check (search up directory tree)
    parents = 2,
    
    -- Enable fd for faster searching
    fd_binary_name = 'fd',
    
    -- Notify when venv is activated
    notify_user_on_activate = true,
  },
  keys = {
    { '<leader>vs', '<cmd>VenvSelect<cr>', desc = '[V]env [S]elect' },
    { '<leader>vc', '<cmd>VenvSelectCached<cr>', desc = '[V]env [C]ached' },
  },
  ft = 'python',
}
