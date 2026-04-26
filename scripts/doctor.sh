#!/usr/bin/env bash
# z-codespace/scripts/doctor.sh — 环境健康检查
# ============================================================
# 检查所有依赖是否就绪，输出可读的诊断报告

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT_ROOT="$(get_project_root)"
OS="$(detect_os)"
ARCH="$(detect_arch)"

ERRORS=0
WARNINGS=0

# --- 检查单个命令 ---
check_cmd() {
    local cmd="$1"
    local required="${2:-true}"
    local desc="${3:-}"

    if has_cmd "$cmd"; then
        local ver=""
        case "$cmd" in
            nvim)    ver=$($cmd --version 2>/dev/null | head -n1) ;;
            node)    ver=$($cmd --version 2>/dev/null) ;;
            python3) ver=$($cmd --version 2>/dev/null) ;;
            git)     ver=$($cmd --version 2>/dev/null) ;;
            rg)      ver=$($cmd --version 2>/dev/null | head -n1) ;;
            fd)      ver=$($cmd --version 2>/dev/null | head -n1) ;;
            gcc)     ver=$($cmd --version 2>/dev/null | head -n1) ;;
            clang)   ver=$($cmd --version 2>/dev/null | head -n1) ;;
            make)    ver=$($cmd --version 2>/dev/null | head -n1) ;;
            tmux)    ver=$($cmd -V 2>/dev/null) ;;
            npm)     ver=$($cmd --version 2>/dev/null) ;;
            pip3)    ver=$($cmd --version 2>/dev/null) ;;
            claude)  ver=$($cmd --version 2>/dev/null | head -n1) ;;
            *)       ver="found" ;;
        esac
        log_ok "$cmd: $ver"
    else
        if [ "$required" = "true" ]; then
            log_error "缺少必需工具: $cmd ${desc:+($desc)}"
            ERRORS=$((ERRORS + 1))
        else
            log_warn "缺少可选工具: $cmd ${desc:+($desc)}"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

# --- 检查 nvim 配置状态 ---
check_nvim_config() {
    local nvim_config="$HOME/.config/nvim"
    if [ -L "$nvim_config" ]; then
        local target
        target=$(readlink -f "$nvim_config" 2>/dev/null || readlink "$nvim_config")
        log_ok "nvim 配置: $nvim_config -> $target"
    elif [ -d "$nvim_config" ]; then
        log_warn "nvim 配置是普通目录（非软链接）: $nvim_config"
        WARNINGS=$((WARNINGS + 1))
    else
        log_error "nvim 配置不存在: $nvim_config"
        ERRORS=$((ERRORS + 1))
    fi

    # 检查 init.lua
    if [ -f "$nvim_config/init.lua" ]; then
        log_ok "init.lua 存在"
    else
        log_error "init.lua 缺失"
        ERRORS=$((ERRORS + 1))
    fi
}

# --- 检查 lazy-lock.json ---
check_lazy_lock() {
    local lock="$PROJECT_ROOT/configs/nvim/lazy-lock.json"
    if [ -f "$lock" ]; then
        local plugins
        plugins=$(grep -c '"' "$lock" 2>/dev/null || echo "0")
        log_ok "lazy-lock.json 存在 (约 $((plugins / 3)) 个插件)"
    else
        log_warn "lazy-lock.json 不存在（插件版本未锁定）"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# --- 检查插件数据目录 ---
check_plugin_data() {
    local lazy_dir="$HOME/.local/share/nvim/lazy"
    if [ -d "$lazy_dir" ]; then
        local count
        count=$(find "$lazy_dir" -maxdepth 1 -type d | wc -l)
        count=$((count - 1))  # 减去目录本身
        log_ok "已安装插件: $count 个 ($lazy_dir)"
    else
        log_warn "插件目录不存在: $lazy_dir"
        WARNINGS=$((WARNINGS + 1))
    fi

    # treesitter parsers
    local ts_dir="$HOME/.local/share/nvim/lazy/nvim-treesitter/parser"
    if [ -d "$ts_dir" ]; then
        local parsers
        parsers=$(find "$ts_dir" -name "*.so" | wc -l)
        log_ok "Treesitter parsers: $parsers 个"
    else
        log_warn "Treesitter parser 目录不存在"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# --- 检查 PATH ---
check_path() {
    if echo "$PATH" | tr ':' '\n' | grep -q "$HOME/.local/bin"; then
        log_ok "PATH 包含 ~/.local/bin"
    else
        log_warn "PATH 未包含 ~/.local/bin，部分工具可能无法找到"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# --- 检查 SSH key ---
check_ssh_key() {
    local key
    for key in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa"; do
        if [ -f "$key" ] && [ -f "$key.pub" ]; then
            log_ok "SSH key: $key"
            return 0
        fi
    done

    log_warn "未找到常见 SSH key，可运行: bash scripts/setup-ssh.sh"
    WARNINGS=$((WARNINGS + 1))
}

# --- 检查 mason 工具 ---
check_mason() {
    local mason_dir="$HOME/.local/share/nvim/mason/bin"
    if [ -d "$mason_dir" ]; then
        local tools
        tools=$(find "$mason_dir" -type f -o -type l 2>/dev/null | wc -l)
        log_ok "Mason 工具: $tools 个 ($mason_dir)"
    else
        log_warn "Mason 目录不存在（LSP/格式化工具未通过 Mason 安装）"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# ============================================================
# 主入口
# ============================================================
main() {
    log_step "=========================================="
    log_step "z-codespace 环境健康检查"
    log_step "系统: $OS ($ARCH)"
    log_step "=========================================="
    echo ""

    log_step "--- 必需工具 ---"
    check_cmd nvim   true "编辑器"
    check_cmd git    true "版本管理"
    check_cmd curl   true "下载工具"
    check_cmd rg     true "ripgrep: telescope 搜索"
    check_cmd node   true "部分 LSP 需要"
    check_cmd python3 true "Python 开发"
    echo ""

    log_step "--- 编译工具 (Treesitter) ---"
    if has_cmd gcc || has_cmd clang; then
        check_cmd gcc   false "C 编译器"
        check_cmd clang false "C 编译器"
    else
        log_error "缺少 C 编译器 (gcc 或 clang)"
        ERRORS=$((ERRORS + 1))
    fi
    check_cmd make true "构建工具"
    echo ""

    log_step "--- 可选工具 ---"
    check_cmd fd      false "文件搜索"
    check_cmd fzf     false "模糊搜索"
    check_cmd tmux    false "终端复用"
    check_cmd lazygit false "Git TUI"
    check_cmd npm     false "Node 包管理"
    check_cmd pip3    false "Python 包管理"
    check_cmd claude  false "Claude Code CLI (claudecode.nvim 插件依赖)"
    echo ""

    log_step "--- 配置状态 ---"
    check_nvim_config
    check_lazy_lock
    check_path
    check_ssh_key
    echo ""

    log_step "--- 运行时数据 ---"
    check_plugin_data
    check_mason
    echo ""

    log_step "=========================================="
    if [ "$ERRORS" -gt 0 ]; then
        log_error "发现 $ERRORS 个错误, $WARNINGS 个警告"
        log_info "修复建议: bash scripts/install-deps.sh"
        exit 1
    elif [ "$WARNINGS" -gt 0 ]; then
        log_warn "发现 $WARNINGS 个警告（非致命）"
        log_ok "基础环境正常"
    else
        log_ok "所有检查通过！"
    fi
}

main "$@"
