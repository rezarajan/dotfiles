return {
  'mrjones2014/smart-splits.nvim',
  version = '>=1.0.0',
  opts = {
    default_amount = 3,
    at_edge = 'stop',
  },
  keys = {
    {
      '<C-h>',
      function()
        require('smart-splits').move_cursor_left()
      end,
      desc = 'Move focus left',
    },
    {
      '<C-j>',
      function()
        require('smart-splits').move_cursor_down()
      end,
      desc = 'Move focus down',
    },
    {
      '<C-k>',
      function()
        require('smart-splits').move_cursor_up()
      end,
      desc = 'Move focus up',
    },
    {
      '<C-l>',
      function()
        require('smart-splits').move_cursor_right()
      end,
      desc = 'Move focus right',
    },
    {
      '<C-\\>',
      function()
        require('smart-splits').move_cursor_previous()
      end,
      desc = 'Move focus previous',
    },
    {
      '<leader>Wh',
      function()
        require('smart-splits').resize_left()
      end,
      desc = '[W]indow resize left',
    },
    {
      '<leader>Wj',
      function()
        require('smart-splits').resize_down()
      end,
      desc = '[W]indow resize down',
    },
    {
      '<leader>Wk',
      function()
        require('smart-splits').resize_up()
      end,
      desc = '[W]indow resize up',
    },
    {
      '<leader>Wl',
      function()
        require('smart-splits').resize_right()
      end,
      desc = '[W]indow resize right',
    },
  },
}
