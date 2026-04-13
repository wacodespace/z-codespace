-- 语言支持 (LSP / 格式化 / Lint)
-- ============================================================
--
-- 通过 lazyvim.json extras 启用的语言支持:
--   extras.lang.python  → pyright + ruff + black
--   extras.lang.clangd  → clangd
--   extras.lang.json    → jsonls + schemastore
--   extras.lang.yaml    → yamlls
--   extras.lang.markdown→ marksman
--
-- 本文件负责:
--   1. 补充 extras 未覆盖的语言 (bash)
--   2. 覆盖 LSP 默认配置
--   3. 配置格式化工具
--
-- LSP 安装方式一览:
-- ┌───────────┬──────────────────┬─────────────────────────────┬──────────┐
-- │ 语言      │ LSP              │ 安装方式                    │ 离线可用 │
-- ├───────────┼──────────────────┼─────────────────────────────┼──────────┤
-- │ Python    │ pyright          │ mason / npm                 │ 是*      │
-- │ C/C++     │ clangd           │ 系统包管理器 (推荐)          .  是       │
-- │ Lua       │ lua_ls           │ mason / GitHub release      │ 是*      │
-- │ Bash      │ bashls           │ mason / npm                 │ 是*      │
-- │ JSON      │ jsonls           │ mason                       │ 是*      │
-- │ YAML      │ yamlls           │ mason                       │ 是*      │
-- │ Markdown  │ marksman         │ mason / GitHub release      │ 是*      │
-- └───────────┴──────────────────┴─────────────────────────────┴──────────┘
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
