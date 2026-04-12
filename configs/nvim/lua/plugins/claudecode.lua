-- Claude Code 集成 (coder/claudecode.nvim)
-- ============================================================
--
-- 作用:
--   把 Claude Code CLI 接入 Neovim，实现双向联动：
--   1. Claude 在终端里打开/修改文件时，直接在当前 nvim buffer 呈现
--   2. 可把 visual selection / 当前 buffer / 文件树选中项作为上下文发给 Claude
--   3. Claude 产生的 diff 可直接在 nvim 中 review (接受 / 拒绝)
--   4. 纯 Lua WebSocket 实现 VS Code 扩展协议，无需额外 MCP 进程
--
-- 依赖 (运行时):
--   - claude CLI (Claude Code)
--     安装: npm install -g @anthropic-ai/claude-code
--     或:   scripts/install-deps.sh 已自动处理 (见 install_claude_cli)
--   - folke/snacks.nvim  — LazyVim 默认自带，用于 diff 展示和终端
--
-- 网络:
--   安装时需要外网 (git clone)
--   运行时与 Claude 对话时需要外网 (Anthropic API)
-- ============================================================

return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSend",
      "ClaudeCodeAdd",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeSelectModel",
    },
    keys = {
      -- which-key 分组标题
      { "<leader>a", nil, desc = "AI / Claude Code" },

      -- 会话控制
      { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "切换 Claude 面板" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "聚焦 Claude 面板" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "恢复历史会话" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "继续上次会话" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "选择 Claude 模型" },

      -- 发送上下文
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "把当前 buffer 发给 Claude" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "把选中内容发给 Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "把文件树选中项发给 Claude",
        ft = { "neo-tree", "NvimTree", "oil", "minifiles" },
      },

      -- diff 审阅
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",  desc = "接受 Claude diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    desc = "拒绝 Claude diff" },
    },
  },
}
