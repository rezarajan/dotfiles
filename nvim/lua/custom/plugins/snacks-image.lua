return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    image = {
      enabled = true,
      formats = {
        'png',
        'jpg',
        'jpeg',
        'gif',
        'bmp',
        'webp',
        'tiff',
        'heic',
        'avif',
        'mp4',
        'mov',
        'avi',
        'mkv',
        'webm',
        'pdf',
        'icns',
        'svg',
      },
      doc = {
        enabled = true,
        inline = true,
        float = true,
        max_width = 80,
        max_height = 40,
        conceal = false,
      },
      convert = {
        mermaid = function()
          local theme = vim.o.background == 'light' and 'neutral' or 'dark'
          local puppeteer = vim.fn.stdpath 'config' .. '/mermaid-puppeteer.json'

          return { '-p', puppeteer, '-i', '{src}', '-o', '{file}', '-b', 'transparent', '-t', theme, '-s', '{scale}' }
        end,
      },
    },
  },
  keys = {
    {
      '<leader>Mi',
      function()
        Snacks.image.hover()
      end,
      desc = '[M]arkdown [I]mage hover',
    },
  },
}
