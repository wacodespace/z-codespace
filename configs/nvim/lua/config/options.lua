-- Neovim 选项设置
-- LazyVim 已有合理默认值，此处只做覆盖和补充
-- ============================================================

local opt = vim.opt

-- 编码
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.fileformats = "unix,dos,mac"

-- 缩进（默认 4 空格，适合 Python/C++）
opt.shiftwidth = 4
opt.tabstop = 4
opt.expandtab = true
opt.smartindent = true

-- 搜索
opt.ignorecase = true
opt.smartcase = true

-- 显示
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false

-- 分屏
opt.splitbelow = true
opt.splitright = true

-- 性能
opt.updatetime = 200
opt.timeoutlen = 300

-- 持久化撤销
opt.undofile = true

-- 剪贴板：使用系统剪贴板
opt.clipboard = "unnamedplus"

-- 补全
opt.completeopt = "menu,menuone,noselect"

-- 终端真彩色
opt.termguicolors = true

-- 配色方案
vim.cmd.colorscheme("catppuccin")

-- 禁用 swap（持久化撤销已足够）
opt.swapfile = false
