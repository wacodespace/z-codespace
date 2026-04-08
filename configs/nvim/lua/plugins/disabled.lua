-- 明确禁用的插件
-- LazyVim 默认启用的某些插件可按需在此禁用
-- ============================================================
--
-- 禁用方法: { "插件名", enabled = false }
-- 取消注释以禁用对应插件
--
-- 注意: LazyVim 不默认包含 AI 插件，无需显式禁用
-- 如果未来 LazyVim 版本变动引入了不需要的插件，在此处禁用

return {
  -- 禁用 flash.nvim（如果不习惯，可使用默认 / 搜索）
  -- { "folke/flash.nvim", enabled = false },

  -- 禁用 dashboard（保持启动快速、干净）
  -- { "nvimdev/dashboard-nvim", enabled = false },

  -- 禁用 indent scope 动画（减少视觉干扰）
  -- { "echasnovski/mini.indentscope", enabled = false },
}
