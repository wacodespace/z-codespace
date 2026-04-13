-- lualine 状态栏配置
-- 底部: 只保留 mode + git 分支
-- 顶部 winbar: 显示文件路径面包屑 (类似 VSCode)

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        globalstatus = true,
        disabled_filetypes = {
          statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" },
          winbar = { "dashboard", "alpha", "ministarter", "snacks_dashboard", "neo-tree", "toggleterm", "Trouble" },
        },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          { "branch", icon = "" },
        },
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      winbar = {
        lualine_c = {
          {
            "filename",
            path = 1, -- 显示相对路径
            symbols = { modified = "●", readonly = "", unnamed = "[No Name]" },
          },
          {
            function()
              local ok, navic = pcall(require, "nvim-navic")
              if ok and navic.is_available() then
                return navic.get_location()
              end
              return ""
            end,
            cond = function()
              local ok, navic = pcall(require, "nvim-navic")
              return ok and navic.is_available()
            end,
          },
        },
      },
      inactive_winbar = {
        lualine_c = {
          {
            "filename",
            path = 1,
            symbols = { modified = "●", readonly = "", unnamed = "[No Name]" },
          },
        },
      },
    },
  },
}
