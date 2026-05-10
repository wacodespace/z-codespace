-- 自定义快捷键
-- LazyVim 默认 Leader = Space，此处只做少量补充
-- ============================================================

local map = vim.keymap.set

-- 快速保存/退出
map("n", "<leader>w", "<cmd>w<cr>", { desc = "保存文件" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "退出" })

-- 清除搜索高亮
map("n", "<leader>l", "<cmd>nohlsearch<cr>", { desc = "清除高亮" })

-- 复制当前 buffer 文件路径
map("n", "<leader>yp", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  vim.notify("已复制相对路径: " .. path)
end, { desc = "复制当前文件相对路径" })

map("n", "<leader>yP", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("已复制绝对路径: " .. path)
end, { desc = "复制当前文件绝对路径" })

-- H/L 保留 LazyVim 默认：S-h 上一个 buffer, S-l 下一个 buffer
-- 行首行尾用原生 ^ / $ 或 S-i / S-a

-- 可视模式下移动行
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "下移行" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "上移行" })

-- 粘贴时不覆盖寄存器
map("x", "<leader>p", [["_dP]], { desc = "粘贴（保留寄存器）" })

-- Terminal 模式快速退出
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "退出终端模式" })
