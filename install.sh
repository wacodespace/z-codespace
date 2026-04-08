#!/usr/bin/env bash
# z-codespace/install.sh — 统一安装入口
# ============================================================
#
# 用法:
#   bash install.sh              # 交互式安装（含基础配置 + 可选 nvim）
#   bash install.sh --all        # 安装所有组件（基础配置 + nvim 环境）
#   bash install.sh --nvim-only  # 仅安装 nvim 环境
#   bash install.sh --force      # 强制覆盖
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 引入共享库
source "$SCRIPT_DIR/scripts/lib.sh"

OS="$(detect_os)"
FORCE=""
INSTALL_NVIM=false
NVIM_ONLY=false

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)       INSTALL_NVIM=true; shift ;;
        --nvim-only) NVIM_ONLY=true; INSTALL_NVIM=true; shift ;;
        --force)     FORCE="--force"; shift ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --all        安装所有组件（基础配置 + Neovim 环境）"
            echo "  --nvim-only  仅安装 Neovim (LazyVim) 环境"
            echo "  --force      强制覆盖，不备份"
            echo "  -h, --help   显示帮助"
            echo ""
            echo "组件:"
            echo "  基础配置     bashrc, vimrc, tmux.conf, 终端配置"
            echo "  Neovim 环境  依赖安装 + LazyVim 配置部署"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

main() {
    log_step "=========================================="
    log_step "z-codespace 开发环境安装"
    log_step "系统: $OS ($(detect_arch))"
    log_step "=========================================="
    echo ""

    # --- 基础配置 ---
    if [ "$NVIM_ONLY" != "true" ]; then
        log_step "安装基础配置..."
        case "$OS" in
            macos)
                bash "$SCRIPT_DIR/macos_install.sh" $FORCE
                ;;
            linux)
                bash "$SCRIPT_DIR/linux_install.sh" $FORCE
                ;;
            *)
                log_error "不支持的操作系统: $OS"
                exit 1
                ;;
        esac
        echo ""
    fi

    # --- Neovim 环境 ---
    if [ "$INSTALL_NVIM" = "true" ]; then
        log_step "安装 Neovim (LazyVim) 环境..."
        echo ""
        bash "$SCRIPT_DIR/scripts/install-deps.sh"
        echo ""
        bash "$SCRIPT_DIR/scripts/install-nvim.sh" $FORCE
    else
        # 交互式询问
        echo ""
        log_info "是否安装 Neovim (LazyVim) 开发环境？"
        log_info "（需要下载 ~200MB 依赖和插件）"
        printf "  输入 y 安装，其他跳过: "
        read -r answer
        if [[ "$answer" =~ ^[Yy] ]]; then
            echo ""
            bash "$SCRIPT_DIR/scripts/install-deps.sh"
            echo ""
            bash "$SCRIPT_DIR/scripts/install-nvim.sh" $FORCE
        else
            log_info "跳过 Neovim 环境安装"
            log_info "后续可运行: bash scripts/install-deps.sh && bash scripts/install-nvim.sh"
        fi
    fi

    echo ""
    log_ok "=========================================="
    log_ok "安装完成！"
    log_ok "=========================================="
    echo ""
    log_info "请执行 'source ~/.bashrc' 或重新打开终端使配置生效"
    log_info "环境检查: bash scripts/doctor.sh"
}

main "$@"
