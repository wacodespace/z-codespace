#!/usr/bin/env bash
# z-codespace/install.sh — 统一安装入口（按 profile dispatch）
# ============================================================
#
# Profile 分类（决定装哪些 layer）:
#   macos-desktop    common + desktop/shared + desktop/macos
#   ubuntu-desktop   common + desktop/shared + desktop/linux
#   ubuntu-server    common + server
#
# 用法:
#   bash install.sh                            # 自动检测 profile，交互式询问 nvim/claude-hud
#   bash install.sh --profile=ubuntu-server    # 显式指定 profile
#   bash install.sh --server                   # 语法糖 = --profile=ubuntu-server
#   bash install.sh --desktop                  # mac → macos-desktop, linux → ubuntu-desktop
#   bash install.sh --all                      # profile + nvim + claude-hud + ai-switch
#   bash install.sh --nvim-only                # 仅 Neovim 环境
#   bash install.sh --claude-hud               # 仅 Claude HUD
#   bash install.sh --ai-switch                # 仅 AI 中转切换器
#   bash install.sh --force                    # 强制覆盖
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

source "$SCRIPT_DIR/scripts/lib.sh"
source "$SCRIPT_DIR/scripts/profile-common.sh"
source "$SCRIPT_DIR/scripts/profile-desktop.sh"
source "$SCRIPT_DIR/scripts/profile-server.sh"
source "$SCRIPT_DIR/scripts/profile-packages.sh"

PROFILE=""
FORCE="false"
INSTALL_NVIM=false
NVIM_ONLY=false
INSTALL_CLAUDE_HUD=false
CLAUDE_HUD_ONLY=false
INSTALL_AI_SWITCH=false
AI_SWITCH_ONLY=false

# --- 自动检测 profile ---
detect_profile() {
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "macos-desktop"
    elif [ -n "${SSH_CLIENT:-}${SSH_TTY:-}" ]; then
        echo "ubuntu-server"
    else
        echo "ubuntu-desktop"
    fi
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile=*)      PROFILE="${1#--profile=}"; shift ;;
        --profile)        PROFILE="$2"; shift 2 ;;
        --server)         PROFILE="ubuntu-server"; shift ;;
        --desktop)
            if [ "$(uname -s)" = "Darwin" ]; then
                PROFILE="macos-desktop"
            else
                PROFILE="ubuntu-desktop"
            fi
            shift ;;
        --all)            INSTALL_NVIM=true; INSTALL_CLAUDE_HUD=true; INSTALL_AI_SWITCH=true; shift ;;
        --nvim-only)      NVIM_ONLY=true; INSTALL_NVIM=true; shift ;;
        --claude-hud)     CLAUDE_HUD_ONLY=true; INSTALL_CLAUDE_HUD=true; shift ;;
        --ai-switch)      AI_SWITCH_ONLY=true; INSTALL_AI_SWITCH=true; shift ;;
        --force)          FORCE="true"; shift ;;
        -h|--help)
            cat <<'EOF'
用法: install.sh [选项]

Profile（决定装哪些 layer）:
  --profile=macos-desktop|ubuntu-desktop|ubuntu-server
  --profile <profile>       同上
  --server                  = --profile=ubuntu-server
  --desktop                 macOS 上 = macos-desktop, Linux 上 = ubuntu-desktop
  （不指定时自动检测：macOS → macos-desktop, Linux+SSH → ubuntu-server, else → ubuntu-desktop）

可选组件:
  --all                     基础配置 + Neovim + Claude HUD + AI 中转切换器
  --nvim-only               仅 Neovim 环境
  --claude-hud              仅 Claude HUD 状态栏
  --ai-switch               仅 AI 中转切换器 (macOS: CC Switch / Linux: cc-switch-cli)

其它:
  --force                   强制覆盖，不备份
  -h, --help                显示此帮助
EOF
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

apply_profile() {
    case "$PROFILE" in
        macos-desktop)
            install_homebrew
            install_desktop_apps_macos
            apply_common "$FORCE"
            apply_desktop_shared "$FORCE"
            apply_desktop_macos "$FORCE"
            ;;
        ubuntu-desktop)
            install_packages_apt_min
            apply_common "$FORCE"
            apply_desktop_shared "$FORCE"
            apply_desktop_linux "$FORCE"
            ;;
        ubuntu-server)
            install_packages_apt_min
            apply_common "$FORCE"
            apply_server "$FORCE"
            ;;
        *)
            log_error "不支持的 profile: $PROFILE"
            log_error "支持: macos-desktop, ubuntu-desktop, ubuntu-server"
            exit 1
            ;;
    esac
}

# --- 一次性 Git 全局配置（取代 .bashrc 启动时反复写 ~/.gitconfig）---
setup_git_global_config() {
    if ! has_cmd git; then
        log_warn "git 未安装，跳过 git config 全局设置"
        return 0
    fi
    log_step "配置 Git 全局设置..."

    # UTF-8 / 中文文件名输出
    git config --global core.quotepath false
    git config --global gui.encoding utf-8
    git config --global i18n.commitencoding utf-8
    git config --global i18n.logoutputencoding utf-8

    # Linux profile：HTTPS → SSH 重写（macOS 桌面不需要，避免限制 https clone）
    case "$PROFILE" in
        ubuntu-*)
            if ! git config --global --get "url.git@github.com:.insteadOf" >/dev/null 2>&1; then
                log_info "设置 Git HTTPS -> SSH 重写规则"
                git config --global "url.git@github.com:".insteadOf "https://github.com/"
            fi
            ;;
    esac
}

main() {
    # nvim-only / claude-hud-only / ai-switch-only 时不需要 profile
    if [ "$NVIM_ONLY" != "true" ] && [ "$CLAUDE_HUD_ONLY" != "true" ] && [ "$AI_SWITCH_ONLY" != "true" ]; then
        if [ -z "$PROFILE" ]; then
            PROFILE="$(detect_profile)"
            log_info "自动检测 profile: $PROFILE"
        fi
    fi

    log_step "=========================================="
    log_step "z-codespace 开发环境安装"
    [ -n "$PROFILE" ] && log_step "Profile: $PROFILE"
    log_step "系统: $(detect_os) ($(detect_arch))"
    log_step "=========================================="
    echo ""

    # --- 基础配置（按 profile dispatch） ---
    if [ "$NVIM_ONLY" != "true" ] && [ "$CLAUDE_HUD_ONLY" != "true" ] && [ "$AI_SWITCH_ONLY" != "true" ]; then
        apply_profile
        setup_git_global_config

        # SSH key（所有 profile 都需要）
        log_step "检查 SSH key..."
        bash "$SCRIPT_DIR/scripts/setup-ssh.sh"

        echo ""
    fi

    # --- Neovim 环境 ---
    if [ "$CLAUDE_HUD_ONLY" != "true" ] && [ "$AI_SWITCH_ONLY" != "true" ]; then
        if [ "$INSTALL_NVIM" = "true" ]; then
            log_step "安装 Neovim (LazyVim) 环境..."
            echo ""
            bash "$SCRIPT_DIR/scripts/install-deps.sh"
            echo ""
            local nvim_flags=""
            [ "$FORCE" = "true" ] && nvim_flags="--force"
            bash "$SCRIPT_DIR/scripts/install-nvim.sh" $nvim_flags
        elif [ "$NVIM_ONLY" != "true" ]; then
            echo ""
            log_info "是否安装 Neovim (LazyVim) 开发环境？"
            log_info "（需要下载 ~200MB 依赖和插件）"
            printf "  输入 y 安装，其他跳过: "
            read -r answer
            if [[ "$answer" =~ ^[Yy] ]]; then
                echo ""
                bash "$SCRIPT_DIR/scripts/install-deps.sh"
                echo ""
                bash "$SCRIPT_DIR/scripts/install-nvim.sh"
            else
                log_info "跳过 Neovim 环境安装"
                log_info "后续可运行: bash scripts/install-deps.sh && bash scripts/install-nvim.sh"
            fi
        fi
    fi

    # --- Claude HUD ---
    if [ "$INSTALL_CLAUDE_HUD" = "true" ]; then
        echo ""
        log_step "安装 Claude HUD 状态栏插件..."
        echo ""
        bash "$SCRIPT_DIR/scripts/install-claude-hud.sh"
    elif [ "$NVIM_ONLY" != "true" ] && [ "$CLAUDE_HUD_ONLY" != "true" ] && [ "$AI_SWITCH_ONLY" != "true" ]; then
        echo ""
        log_info "是否安装 Claude HUD？（Claude Code 实时状态栏: context/tools/agents/todos）"
        printf "  输入 y 安装，其他跳过: "
        read -r answer
        if [[ "$answer" =~ ^[Yy] ]]; then
            echo ""
            bash "$SCRIPT_DIR/scripts/install-claude-hud.sh"
        else
            log_info "跳过 Claude HUD 安装"
            log_info "后续可运行: bash scripts/install-claude-hud.sh"
        fi
    fi

    # --- AI 中转切换器（flag 驱动，不交互；默认流程不触发） ---
    if [ "$INSTALL_AI_SWITCH" = "true" ]; then
        echo ""
        log_step "安装 AI 第三方中转切换器..."
        echo ""
        bash "$SCRIPT_DIR/scripts/install-ai-switcher.sh"
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
