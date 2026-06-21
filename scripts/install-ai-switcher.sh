#!/usr/bin/env bash
# z-codespace/scripts/install-ai-switcher.sh — 安装 AI 第三方中转切换器
# ============================================================
#
# 按 profile 安装专用的 provider 切换器，统一管理 Claude Code / Codex 的
# 第三方 Base URL / API Key（中转站）。本仓库只负责「装工具」，
# 不保存 key、不放配置模板、不注入环境变量；provider 列表交给切换器自己存。
#
#   macOS (有 GUI)  → CC Switch (桌面 App)
#                     https://github.com/farion1231/cc-switch  (brew cask)
#   Linux (headless) → cc-switch-cli (Rust 二进制，装到 ~/.local/bin/cc-switch)
#                     https://github.com/SaladDay/cc-switch-cli
#
# 两者都把 provider 写进各 CLI 的原生 config（~/.claude/settings.json、
# Codex config.toml），所以 ai-cli.sh 里的 cc/cx 等启动器保持裸调即可生效，
# 新增中转站永远不用改本仓库。
#
# 非致命：任何失败只输出警告并给出手动安装提示，不中断整个安装流程。
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

OS="$(detect_os)"

CC_SWITCH_CLI_INSTALL="https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh"

# ============================================================
# macOS：CC Switch 桌面 App（brew cask）
# ============================================================
install_cc_switch_macos() {
    if has_cmd cc-switch || ls /Applications 2>/dev/null | grep -qi 'CC.Switch'; then
        log_ok "CC Switch 已安装"
        return 0
    fi

    if ! has_cmd brew; then
        log_warn "未找到 Homebrew，跳过 CC Switch 安装"
        log_warn "手动安装: brew install --cask cc-switch  或  https://ccswitch.io 下载"
        return 0
    fi

    log_step "安装 CC Switch (桌面 provider 切换器)..."
    if brew install --cask cc-switch; then
        log_ok "CC Switch 安装完成（在 GUI 里添加中转 provider，无需改仓库）"
    else
        log_warn "CC Switch 安装失败"
        log_warn "手动安装: brew install --cask cc-switch  或  https://ccswitch.io"
    fi
}

# ============================================================
# Linux headless：cc-switch-cli（Rust 二进制 → ~/.local/bin/cc-switch）
# ============================================================
install_cc_switch_cli_linux() {
    if has_cmd cc-switch; then
        log_ok "cc-switch-cli 已安装: $(command -v cc-switch)"
        return 0
    fi

    if ! has_cmd curl; then
        log_warn "未找到 curl，跳过 cc-switch-cli 安装"
        log_warn "手动安装见: https://github.com/SaladDay/cc-switch-cli"
        return 0
    fi

    log_step "安装 cc-switch-cli (headless provider 切换器 → ~/.local/bin)..."
    if curl -fsSL "$CC_SWITCH_CLI_INSTALL" | bash; then
        if has_cmd cc-switch || [ -x "$HOME/.local/bin/cc-switch" ]; then
            log_ok "cc-switch-cli 安装完成（用 cc-switch 子命令添加中转 provider）"
            log_info "确保 ~/.local/bin 在 PATH 中"
        else
            log_warn "cc-switch-cli 安装脚本执行完毕，但未找到 cc-switch 命令"
            log_warn "请确认 ~/.local/bin 在 PATH 中，或见 https://github.com/SaladDay/cc-switch-cli"
        fi
    else
        log_warn "cc-switch-cli 安装失败"
        log_warn "手动安装见: https://github.com/SaladDay/cc-switch-cli"
    fi
}

# ============================================================
# 主入口
# ============================================================
main() {
    log_step "=========================================="
    log_step "安装 AI 第三方中转切换器"
    log_step "系统: $OS"
    log_step "=========================================="
    echo ""

    case "$OS" in
        macos) install_cc_switch_macos ;;
        linux) install_cc_switch_cli_linux ;;
        *)
            log_warn "不支持的操作系统: $OS，跳过 AI 切换器安装"
            return 0
            ;;
    esac

    echo ""
    log_info "provider / Base URL / API Key 由切换器自己管理；本仓库不保存。"
    log_info "新增中转站请在切换器内操作，cc / cx 启动器会自动读取其写入的原生 config。"
}

main "$@"
