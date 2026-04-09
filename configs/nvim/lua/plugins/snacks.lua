-- Snacks picker 自定义按键
-- 让 Ctrl-h / Ctrl-l 在 picker 页面中稳定切换左右窗格

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.win = opts.picker.win or {}

      local input = opts.picker.win.input or {}
      input.keys = input.keys or {}
      input.keys["<C-h>"] = { "focus_list", mode = { "i", "n" } }
      input.keys["<C-l>"] = { "focus_preview", mode = { "i", "n" } }
      opts.picker.win.input = input

      local list = opts.picker.win.list or {}
      list.keys = list.keys or {}
      list.keys["<C-h>"] = "focus_list"
      list.keys["<C-l>"] = "focus_preview"
      opts.picker.win.list = list

      local preview = opts.picker.win.preview or {}
      preview.keys = preview.keys or {}
      preview.keys["<C-h>"] = "focus_list"
      preview.keys["<C-l>"] = "focus_preview"
      opts.picker.win.preview = preview
    end,
  },
}
