-- Treesitter 配置
-- ============================================================
--
-- 策略:
--   1. 只安装必要 parser，不贪多
--   2. auto_install = false，禁止运行时自动下载
--   3. parser 编译需要 C 编译器 (gcc/clang)
--   4. 编译后 parser 为本地 .so 文件，不再需要网络
--
-- parser 存储位置:
--   ~/.local/share/nvim/lazy/nvim-treesitter/parser/
--
-- 离线迁移:
--   将 ~/.local/share/nvim 整体打包到目标机器即可
--   注意: parser 为平台相关的 .so，不能跨平台迁移
--
-- 版本锁定:
--   treesitter parser 版本由 nvim-treesitter 插件版本决定
--   通过 lazy-lock.json 锁定 nvim-treesitter 版本即可间接锁定
-- ============================================================

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- 必须: 日常开发语言
        "python",
        "c",
        "cpp",
        "cuda",
        "lua",
        "bash",
        "json",
        "yaml",
        "toml",
        "markdown",
        "markdown_inline",
        -- 必须: Neovim/Vim 自身
        "vim",
        "vimdoc",
        "regex",
        "query",
        -- 可选: 按需取消注释
        -- "typescript",
        -- "javascript",
        -- "html",
        -- "css",
        -- "dockerfile",
        -- "cmake",
        -- "make",
        -- "rust",
        -- "go",
      },
      -- 禁止自动安装未列出的 parser
      auto_install = false,
      highlight = {
        enable = true,
        -- 大文件禁用高亮（防卡顿）
        disable = function(_, buf)
          local max_filesize = 512 * 1024 -- 512 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
      },
      indent = { enable = true },
    },
  },
}
