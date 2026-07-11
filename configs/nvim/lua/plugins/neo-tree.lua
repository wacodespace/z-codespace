-- Neo-tree 特定配置
-- ============================================================
-- 在 Neo-tree 窗口内添加专用映射，避免全局热键冲突
-- 使用 Leader + 左/右箭头 来调整 Neo-tree 窗口大小（移动分界线）
-- 只有当焦点在 Neo-tree 窗口时这些按键才会生效，其他地方完全不影响。

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      -- 安全合并 mappings，不要覆盖 LazyVim 默认的 Neo-tree 映射
      opts.window = opts.window or {}
      opts.window.mappings = opts.window.mappings or {}

      -- 只在 Neo-tree 窗口内生效的 resize 映射
      -- 往左移分界线 → 缩小 Neo-tree 窗口
      opts.window.mappings["<leader><Left>"] = function()
        vim.cmd("vertical resize -3")
      end
      -- 往右移分界线 → 增大 Neo-tree 窗口
      opts.window.mappings["<leader><Right>"] = function()
        vim.cmd("vertical resize +3")
      end

      return opts
    end,
  },
}
