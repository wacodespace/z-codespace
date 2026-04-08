-- lazy.nvim 引导与 LazyVim 加载
-- ============================================================

-- 自动安装 lazy.nvim（首次运行时需要网络）
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- LazyVim 核心（稳定版）
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
    },
    -- 用户自定义插件
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    -- 不限制版本标签，由 lazy-lock.json 锁定
    version = false,
  },
  install = {
    -- 首次安装时使用的配色
    colorscheme = { "catppuccin" },
  },
  checker = {
    -- 禁止自动检查插件更新（稳定优先，手动控制升级）
    enabled = false,
  },
  -- 默认 120s：慢网/代理下 clone+checkout 易超时（如 snacks.nvim 报 Process was killed timeout）
  git = {
    timeout = 600,
  },
  change_detection = {
    -- 配置文件变更自动重载
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      -- 禁用不需要的内置插件
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
