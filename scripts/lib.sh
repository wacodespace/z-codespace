#!/usr/bin/env bash
# z-codespace/scripts/lib.sh — 共享工具函数库
# 所有脚本通过 source 引入本文件
# ============================================================

# 防止重复 source
[[ -n "${_LIB_SH_LOADED:-}" ]] && return 0
_LIB_SH_LOADED=1

set -euo pipefail

# --- 颜色输出 ---
readonly _RED='\033[0;31m'
readonly _GREEN='\033[0;32m'
readonly _YELLOW='\033[1;33m'
readonly _BLUE='\033[0;34m'
readonly _NC='\033[0m'

log_info()  { printf "${_GREEN}[INFO]${_NC}  %s\n" "$*"; }
log_warn()  { printf "${_YELLOW}[WARN]${_NC}  %s\n" "$*"; }
log_error() { printf "${_RED}[ERROR]${_NC} %s\n" "$*" >&2; }
log_step()  { printf "${_BLUE}[STEP]${_NC}  %s\n" "$*"; }
log_ok()    { printf "${_GREEN}[ OK ]${_NC}  %s\n" "$*"; }

# --- 操作系统检测 ---
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)  echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        *)             echo "$(uname -m)" ;;
    esac
}

# --- Linux 发行版检测 ---
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|pop|linuxmint) echo "debian" ;;
            centos|rhel|rocky|alma|fedora) echo "rhel" ;;
            arch|manjaro) echo "arch" ;;
            *) echo "$ID" ;;
        esac
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# --- 包管理器检测 ---
detect_pkg_manager() {
    if command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v apt-get >/dev/null 2>&1; then
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

# --- 命令存在检测 ---
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# --- 版本比较: $1 >= $2 ---
version_ge() {
    printf '%s\n%s' "$2" "$1" | sort -V | head -n1 | grep -qx "$2"
}

# --- 备份路径（幂等） ---
backup_path() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        log_warn "备份: $target -> $backup"
        cp -r "$target" "$backup"
    elif [ -L "$target" ]; then
        log_info "移除旧软链接: $target"
        rm -f "$target"
    fi
}

# --- 创建软链接（幂等） ---
safe_link() {
    local src="$1"
    local dst="$2"
    local force="${3:-false}"

    if [ ! -e "$src" ]; then
        log_error "源路径不存在: $src"
        return 1
    fi

    # 如果已经是正确的软链接，跳过
    if [ -L "$dst" ]; then
        local current_target
        current_target=$(readlink -f "$dst" 2>/dev/null || readlink "$dst")
        local expected
        expected=$(cd "$(dirname "$src")" && pwd)/$(basename "$src")
        if [ "$current_target" = "$expected" ]; then
            log_ok "已链接: $dst"
            return 0
        fi
    fi

    if [ "$force" = "true" ]; then
        rm -rf "$dst"
    else
        backup_path "$dst"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    log_ok "链接: $src -> $dst"
}

# --- 检查最低 Neovim 版本 ---
check_nvim_version() {
    local required="${1:-0.9.0}"
    if ! has_cmd nvim; then
        return 1
    fi
    local current
    current=$(nvim --version | head -n1 | sed 's/NVIM v//')
    version_ge "$current" "$required"
}

# --- 获取项目根目录 ---
get_project_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
    if [ "$(basename "$script_dir")" = "scripts" ]; then
        dirname "$script_dir"
    else
        echo "$script_dir"
    fi
}
