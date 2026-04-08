-- 编辑器增强插件
-- ============================================================
--
-- LazyVim 默认已包含:
--   mini.surround  — 括号/引号操作
--   mini.pairs     — 自动配对
--   mini.comment   — 注释 (Neovim 0.10+ 内置)
--   mini.ai        — 文本对象扩展
--   gitsigns.nvim  — Git 标记
--   telescope.nvim — 模糊搜索
--   neo-tree.nvim  — 文件浏览器
--   lualine.nvim   — 状态栏
--
-- 此文件只添加 LazyVim 默认未包含的必要插件
-- ============================================================

return {
  -- tmux 无缝导航: C-h/j/k/l 在 vim split 和 tmux pane 间切换
  -- 运行时不需要外网 | 安装时需要外网 (git clone) | 无外部二进制依赖
  {
    "christoomey/vim-tmux-navigator",
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>",  desc = "切换到左窗格" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>",  desc = "切换到下窗格" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>",    desc = "切换到上窗格" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "切换到右窗格" },
    },
  },

  -- toggleterm: 内嵌终端 (浮动/水平/垂直)
  -- 运行时不需要外网 | 安装时需要外网 (git clone) | 无外部二进制依赖
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<C-\\>",     "<cmd>ToggleTerm direction=float<cr>",            desc = "浮动终端" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal size=15<cr>", desc = "底部终端" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>",   desc = "右侧终端" },
    },
    opts = {
      shade_terminals = false,
    },
  },
}
