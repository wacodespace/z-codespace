#!/usr/bin/env bash
# z-codespace/scripts/profile-packages.sh
# Linux 基础包管理（apt/yum/dnf/pacman 安装 vim/tmux/git/htop 等）
# ============================================================

# 防止重复 source
[[ -n "${_PROFILE_PACKAGES_SH_LOADED:-}" ]] && return 0
_PROFILE_PACKAGES_SH_LOADED=1

# Linux 原生包管理器检测（避免 lib.sh 的 brew 优先误判）
detect_linux_pkg_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

install_packages_apt_min() {
    local pkg_manager
    pkg_manager=$(detect_linux_pkg_manager)
    case "$pkg_manager" in
        apt)
            log_step "使用 apt 安装基础工具..."
            sudo apt-get update
            sudo apt-get install -y vim tmux curl wget git htop openssh-client
            ;;
        yum|dnf)
            log_step "使用 $pkg_manager 安装基础工具..."
            sudo "$pkg_manager" install -y vim tmux curl wget git htop openssh-clients
            ;;
        pacman)
            log_step "使用 pacman 安装基础工具..."
            sudo pacman -Sy --noconfirm vim tmux curl wget git htop openssh
            ;;
        *)
            log_warn "未识别的包管理器，请手动安装: vim tmux curl wget git htop openssh-client"
            ;;
    esac
}
