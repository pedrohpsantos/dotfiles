-- ============================================================================
-- ~/.config/nvim/lua/config/options.lua — Core Options & WSL 2 Clipboard
-- ============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.autoformat = true

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.showmode = false
opt.breakindent = true
opt.undofile = true
opt.undolevels = 10000
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 200
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.inccommand = "nosplit"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.shiftround = true
opt.termguicolors = true
opt.laststatus = 3
opt.smoothscroll = true
opt.virtualedit = "block"
opt.wildmode = "longest:full,full"
opt.completeopt = "menu,menuone,noselect"
opt.confirm = true
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

-- WSL 2 Clipboard Integration (clip.exe / powershell.exe)
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = "clip.exe",
      ["*"] = "clip.exe",
    },
    paste = {
      ["+"] = 'powershell.exe -NoProfile -Command [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ["*"] = 'powershell.exe -NoProfile -Command [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
end

vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = "●", source = "if_many" },
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  float = { border = "rounded", source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN]  = " ",
      [vim.diagnostic.severity.HINT]  = " ",
      [vim.diagnostic.severity.INFO]  = " ",
    },
  },
})
