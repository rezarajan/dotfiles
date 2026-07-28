return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown' },
  cmd = { 'RenderMarkdown' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-mini/mini.nvim',
  },
  opts = {
    enabled = false,
    file_types = { 'markdown' },
    pipe_table = {
      style = 'full',
    },
    code = {
      border = 'thin',
      language_icon = true,
      language_name = true,
    },
  },
  keys = {
    {
      '<leader>Mr',
      function()
        require('render-markdown').buf_toggle()
      end,
      desc = '[M]arkdown [R]ender toggle',
    },
    {
      '<leader>Mp',
      function()
        require('render-markdown').preview()
      end,
      desc = '[M]arkdown [P]review split',
    },
  },
}
