-- Aerial.nvim - Code outline sidebar with hierarchical symbol tree
-- Shows class methods, nested functions, and proper object structure

return {
  'stevearc/aerial.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
    'nvim-telescope/telescope.nvim',
  },
  config = function(_, opts)
    require('aerial').setup(opts)
    -- Load Telescope extension
    require('telescope').load_extension('aerial')
  end,
  opts = {
    -- Display settings
    layout = {
      max_width = { 40, 0.2 },
      width = nil,
      min_width = 20,
      default_direction = 'prefer_right',
      placement = 'edge',
    },
    
    -- Show symbols
    show_guides = true,
    guides = {
      mid_item = '├─',
      last_item = '└─',
      nested_top = '│ ',
      whitespace = '  ',
    },
    
    -- Filter which symbols to show
    filter_kind = {
      'Class',
      'Constructor',
      'Enum',
      'Function',
      'Interface',
      'Module',
      'Method',
      'Struct',
    },
    
    -- Highlight the symbol under cursor
    highlight_on_hover = true,
    highlight_on_jump = 300,
    
    -- Automatically open aerial when entering supported buffers
    on_attach = function(bufnr)
      -- Jump forward/backward with '{' and '}'
      vim.keymap.set('n', '{', '<cmd>AerialPrev<CR>', { buffer = bufnr, desc = 'Aerial: Previous symbol' })
      vim.keymap.set('n', '}', '<cmd>AerialNext<CR>', { buffer = bufnr, desc = 'Aerial: Next symbol' })
    end,
  },
  keys = {
    { '<leader>a', '<cmd>AerialToggle!<CR>', desc = '[A]erial outline toggle' },
    { '<leader>oa', '<cmd>Telescope aerial<CR>', desc = '[O]utline [A]erial (Telescope)' },
    { '<leader>on', '<cmd>AerialNavToggle<CR>', desc = '[O]utline [N]avigation float' },
    -- Use Telescope for aerial navigation
    { '<leader>sa', '<cmd>Telescope aerial<CR>', desc = '[S]earch [A]erial symbols' },
  },
}
