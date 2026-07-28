local M = {}

local function current_win(tab)
  return vim.api.nvim_tabpage_get_win(tab)
end

local function current_buf(tab)
  return vim.api.nvim_win_get_buf(current_win(tab))
end

local function buffer_label(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local buftype = vim.bo[buf].buftype
  local filetype = vim.bo[buf].filetype

  if buftype == 'terminal' then return 'terminal' end
  if filetype == 'help' then return vim.fn.fnamemodify(name, ':t:r') end
  if name == '' then return '[No Name]' end

  return vim.fn.fnamemodify(name, ':t')
end

local function devicon(buf, label)
  if not vim.g.have_nerd_font then return '' end

  local ok, icons = pcall(require, 'nvim-web-devicons')
  if not ok then return '' end

  local name = vim.api.nvim_buf_get_name(buf)
  local extension = vim.fn.fnamemodify(name, ':e')
  local icon = icons.get_icon(label, extension, { default = true })

  return icon and (icon .. ' ') or ''
end

local function modified(tab)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].modified then return ' +' end
  end

  return ''
end

local function tab_label(index, tab)
  local buf = current_buf(tab)
  local label = buffer_label(buf)
  local icon = devicon(buf, label)
  local hl = index == vim.fn.tabpagenr() and '%#TabLineSel#' or '%#TabLine#'

  return table.concat {
    '%',
    index,
    'T',
    hl,
    ' ',
    index,
    ':',
    icon,
    label:gsub('%%', '%%%%'),
    modified(tab),
    ' ',
  }
end

function M.render()
  local tabs = vim.api.nvim_list_tabpages()
  local parts = {}

  for index, tab in ipairs(tabs) do
    table.insert(parts, tab_label(index, tab))
  end

  table.insert(parts, '%#TabLineFill#%T')
  return table.concat(parts)
end

function M.setup()
  vim.o.showtabline = 1
  vim.o.tabline = "%!v:lua.require'custom.tabline'.render()"
end

return M
