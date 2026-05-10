-- 自动命令
-- LazyVim 已提供合理默认 autocmds，此处只做少量补充
-- ============================================================

local autocmd = vim.api.nvim_create_autocmd

-- Python 文件缩进
autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

-- C/C++/CUDA 文件缩进
autocmd("FileType", {
  pattern = { "c", "cpp", "cuda" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

-- Makefile 必须使用 tab
autocmd("FileType", {
  pattern = "make",
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

-- Markdown 阅读体验
autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = ""
  end,
})

-- 大文件优化（>1MB）：禁用语法高亮等耗性能功能
autocmd("BufReadPre", {
  callback = function(args)
    local ok, stats = pcall(vim.loop.fs_stat, args.file)
    if ok and stats and stats.size > 1024 * 1024 then
      vim.b.large_file = true
      vim.opt_local.syntax = "off"
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.undofile = false
      vim.opt_local.swapfile = false
    end
  end,
})
