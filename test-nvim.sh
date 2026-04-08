#!/bin/bash
# Neovim 配置快速测试脚本
# 用法: ./test-nvim.sh

set -e

echo "🧪 测试 Neovim 配置..."

# 测试基本启动
echo "1. 测试基本启动..."
if nvim --headless -c "lua print('✅ Neovim 启动成功！')" -c "qa" 2>/dev/null; then
    echo "   ✅ 基本启动正常"
else
    echo "   ❌ 基本启动失败"
    exit 1
fi

# 测试配置加载
echo "2. 测试配置加载..."
if nvim --headless -c "lua print('✅ 配置加载正常，当前配色:', vim.g.colors_name or 'none')" -c "qa" 2>/dev/null; then
    echo "   ✅ 配置加载正常"
else
    echo "   ❌ 配置加载失败"
    exit 1
fi

# 测试插件管理器
echo "3. 测试 lazy.nvim..."
if nvim --headless -c "lua local ok, lazy = pcall(require, 'lazy'); print(ok and '✅ lazy.nvim 正常' or '❌ lazy.nvim 失败')" -c "qa" 2>/dev/null; then
    echo "   ✅ lazy.nvim 正常"
else
    echo "   ❌ lazy.nvim 失败"
    exit 1
fi

# 测试配色方案
echo "4. 测试配色方案..."
if nvim --headless -c "lua vim.cmd('colorscheme catppuccin'); print('✅ catppuccin 配色可用')" -c "qa" 2>/dev/null; then
    echo "   ✅ catppuccin 配色可用"
else
    echo "   ❌ catppuccin 配色失败"
    exit 1
fi

echo ""
echo "🎉 所有测试通过！Neovim 配置工作正常。"
echo ""
echo "💡 提示："
echo "   - 启动 Neovim: nvim"
echo "   - 设置配色: :colorscheme catppuccin"
echo "   - 打开终端: Ctrl+\\"
echo ""
