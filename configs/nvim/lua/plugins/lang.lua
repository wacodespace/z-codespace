-- 语言支持 (LSP / 格式化)
-- ============================================================
--
-- 当前 lazyvim.json 启用的 extras 只有 editor.snacks_picker；
-- 语言相关的 extras (lang.python / lang.clangd / lang.json 等) 都未启用。
-- 这意味着所有 LSP 配置都来自本文件的 mason ensure_installed +
-- nvim-lspconfig servers = { ... } 自动 mason 检测。
--
-- 实际启用的 LSP:
--   pyright    — servers={pyright=...} 自动 mason 安装
--   clangd     — mason=false，使用系统 clangd（GPU 机自带 LLVM）
--   bashls     — mason ensure_installed: bash-language-server
--   lua_ls     — LazyVim 核心默认（编辑 nvim 配置必备）
--
-- 想要 jsonls / yamlls / marksman / tsserver：
--   编辑 lazyvim.json，在 extras 数组中加入对应的 lazyvim.plugins.extras.lang.*
--
-- LSP 安装方式一览:
-- ┌───────────┬──────────────────────┬─────────────────────────────┬──────────┐
-- │ 语言      │ LSP                  │ 安装方式                    │ 离线可用 │
-- ├───────────┼──────────────────────┼─────────────────────────────┼──────────┤
-- │ Python    │ pyright              │ mason 自动                  │ 是*      │
-- │ C/C++     │ clangd               │ 系统包管理器                │ 是       │
-- │ Bash      │ bash-language-server │ mason ensure_installed      │ 是*      │
-- │ Lua       │ lua_ls               │ LazyVim 核心默认            │ 是*      │
-- └───────────┴──────────────────────┴─────────────────────────────┴──────────┘
-- * = 安装阶段需要网络，安装完成后离线可用
--
-- 离线迁移: 打包 ~/.local/share/nvim/mason/ 目录即可
-- ============================================================

return {
  -- mason: 管理 LSP / 格式化 / Lint 工具安装
  -- 注意: 在无网环境中应使用系统包管理器替代 mason
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- LSP (extras 未覆盖的)
        "bash-language-server",
        -- 格式化工具
        "stylua",
        "shfmt",
        "black",
        "isort",
      },
    },
  },

  -- LSP 配置覆盖
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- C/C++: 优先使用系统 clangd，不依赖 mason
        clangd = {
          mason = false,
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
          },
        },
        -- Bash
        bashls = {},
        -- Python: 覆盖默认配置
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                -- 减少 torch/tensor 常见误报
                diagnosticSeverityOverrides = {
                  reportAttributeAccessIssue = "none",
                  reportOperatorIssue = "none",
                  reportReturnType = "none",
                  reportArgumentType = "warning",
                },
              },
            },
          },
        },
      },
    },
  },

  -- 格式化配置
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "isort", "black" },
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
      },
    },
  },
}
