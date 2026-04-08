-- 自定义快捷键
-- LazyVim 默认 Leader = Space，此处只做少量补充
-- ============================================================

local map = vim.keymap.set

-- 快速保存/退出
map("n", "<leader>w", "<cmd>w<cr>", { desc = "保存文件" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "退出" })

-- 清除搜索高亮
map("n", "<leader>l", "<cmd>nohlsearch<cr>", { desc = "清除高亮" })

-- 快速移动到行首行尾
map({ "n", "v" }, "H", "^", { desc = "行首" })
map({ "n", "v" }, "L", "$", { desc = "行尾" })

-- 可视模式下移动行
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "下移行" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "上移行" })

-- 粘贴时不覆盖寄存器
map("x", "<leader>p", [["_dP]], { desc = "粘贴（保留寄存器）" })

-- Terminal 模式快速退出
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "退出终端模式" })
