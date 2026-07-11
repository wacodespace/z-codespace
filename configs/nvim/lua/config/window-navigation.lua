-- 窗口导航与大小调整快捷键配置
-- 专为 macOS 键盘布局优化
-- 注意：Neo-tree 窗口内用 Leader + Left/Right 进行 resize（见 lua/plugins/neo-tree.lua），
--       避免 Ctrl+箭头 与 macOS 系统冲突

-- 1. 传统 Vim 方式（通用，无需配置）
-- Ctrl + w 然后 h/j/k/l
-- Ctrl + w 然后 > / <  调整宽度（推荐作为备选，macOS 友好）
-- Ctrl + w 然后 + / -  调整高度

-- 2. macOS 友好的快捷键
-- 使用 Command 键（macOS 的主要修饰键）
vim.keymap.set('n', '<D-h>', '<C-w>h', { desc = '切换到左侧窗口' })
vim.keymap.set('n', '<D-j>', '<C-w>j', { desc = '切换到下方窗口' })
vim.keymap.set('n', '<D-k>', '<C-w>k', { desc = '切换到上方窗口' })
vim.keymap.set('n', '<D-l>', '<C-w>l', { desc = '切换到右侧窗口' })

-- 3. 使用 Space (Leader) 键 - 最推荐
vim.keymap.set('n', '<leader>h', '<C-w>h', { desc = '切换到左侧窗口' })
vim.keymap.set('n', '<leader>j', '<C-w>j', { desc = '切换到下方窗口' })
vim.keymap.set('n', '<leader>k', '<C-w>k', { desc = '切换到上方窗口' })
vim.keymap.set('n', '<leader>l', '<C-w>l', { desc = '切换到右侧窗口' })

-- 4. 使用 Tab 键（macOS 用户熟悉）
vim.keymap.set('n', '<Tab>', '<C-w>w', { desc = '循环切换窗口' })
vim.keymap.set('n', '<S-Tab>', '<C-w>W', { desc = '反向循环切换窗口' })

-- 5. 使用 Function 键（F 键在 macOS 上很方便）
vim.keymap.set('n', '<F1>', '<C-w>h', { desc = 'F1: 切换到左侧窗口' })
vim.keymap.set('n', '<F2>', '<C-w>l', { desc = 'F2: 切换到右侧窗口' })
vim.keymap.set('n', '<F3>', '<C-w>j', { desc = 'F3: 切换到下方窗口' })
vim.keymap.set('n', '<F4>', '<C-w>k', { desc = 'F4: 切换到上方窗口' })

-- 6. 窗口操作（使用 macOS 风格的快捷键）
vim.keymap.set('n', '<D-t>', '<C-w>s', { desc = '水平分割窗口 (Cmd+T)' })
vim.keymap.set('n', '<D-d>', '<C-w>v', { desc = '垂直分割窗口 (Cmd+D)' })
vim.keymap.set('n', '<D-w>', '<C-w>q', { desc = '关闭当前窗口 (Cmd+W)' })

-- 7. 使用数字键快速切换（如果窗口不多的话）
vim.keymap.set('n', '<leader>1', '1<C-w>w', { desc = '切换到第1个窗口' })
vim.keymap.set('n', '<leader>2', '2<C-w>w', { desc = '切换到第2个窗口' })
vim.keymap.set('n', '<leader>3', '3<C-w>w', { desc = '切换到第3个窗口' })

-- 窗口大小调整已移至 Neo-tree 专用配置（见 lua/plugins/neo-tree.lua）
-- 这样只在 Neo-tree 窗口内生效，最大程度避免热键冲突。
-- 传统方式仍可用：Ctrl-w 然后 > / < 调整宽度， + / - 调整高度。
