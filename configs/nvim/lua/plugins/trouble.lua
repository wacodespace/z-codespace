-- Trouble 符号/诊断窗口配置
-- 与 Neo-tree 保持一致：只在 Trouble 窗口内用 Leader + 左右箭头调整宽度。

return {
	{
		"folke/trouble.nvim",
		opts = function(_, opts)
			opts.keys = opts.keys or {}

			opts.keys["<leader><Left>"] = {
				action = function()
					vim.cmd("vertical resize -3")
				end,
				desc = "缩小 Trouble 窗口",
			}

			opts.keys["<leader><Right>"] = {
				action = function()
					vim.cmd("vertical resize +3")
				end,
				desc = "增大 Trouble 窗口",
			}

			return opts
		end,
	},
}
