#!/usr/bin/env bash
# z-codespace/scripts/install-cmux.sh — 安装 cmux（macOS 专用）
# ============================================================
#
# cmux: 基于 libghostty 的原生 macOS 终端，专为并行管理多个 AI coding
# agent (Claude Code / Codex / Gemini CLI) 会话设计：左侧会话栏 + 会话
# 持久化 + agent 完成/需要输入时通知 + 文件浏览器/内置浏览器面板。
# https://github.com/manaflow-ai/cmux
#
# cmux 直接读取 ~/.config/ghostty/config（本仓库 configs/desktop/macos/
# .config/ghostty/config 软链接的目标），所以字体/配色/透明度/毛玻璃
# 都会自动复用，无需重复配置。
#
# 左侧会话栏/右侧文件面板是 cmux 自己的原生 UI（NSVisualEffectView），
# 不受 Ghostty 配置影响，存在 `defaults ~/Library/Preferences/
# com.cmuxterm.app.plist`。若想让边栏配色跟 Ghostty 深色毛玻璃统一，去
# cmux 设置 (Cmd+,) → Appearance/Sidebar，把预设从 Native Sidebar 切换
# 成 HUD Glass，再把 Tint Color 调成 #272822 对齐 Monokai 配色。
#
# 仅支持 macOS；非 macOS 上直接跳过（非致命）。
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

OS="$(detect_os)"

install_cmux_macos() {
    if has_cmd cmux || [ -d /Applications/cmux.app ]; then
        log_ok "cmux 已安装"
        return 0
    fi

    if ! has_cmd brew; then
        log_warn "未找到 Homebrew，跳过 cmux 安装"
        log_warn "手动安装: https://github.com/manaflow-ai/cmux"
        return 0
    fi

    log_step "安装 cmux (Ghostty 内核、面向并行 AI agent 会话的终端)..."
    if brew tap manaflow-ai/cmux && brew install --cask cmux; then
        log_ok "cmux 安装完成（会自动读取 ~/.config/ghostty/config 的配色/透明度）"
        log_info "左侧会话栏是 cmux 自己的原生 UI，跟 Ghostty 配置无关"
        log_info "统一深色毛玻璃观感：cmux 设置(Cmd+,) → Appearance/Sidebar → 预设选 HUD Glass"
    else
        log_warn "cmux 安装失败"
        log_warn "手动安装: https://github.com/manaflow-ai/cmux"
    fi
}

main() {
    log_step "=========================================="
    log_step "安装 cmux"
    log_step "系统: $OS"
    log_step "=========================================="
    echo ""

    case "$OS" in
        macos) install_cmux_macos ;;
        *)
            log_warn "cmux 仅支持 macOS，跳过（当前: $OS）"
            return 0
            ;;
    esac
}

main "$@"
