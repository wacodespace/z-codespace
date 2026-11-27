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

# --- 系统与命令检测 ---
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

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# --- 备份路径（幂等） ---
backup_path() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        log_warn "备份: $target -> $backup"
        mv "$target" "$backup"
    elif [ -L "$target" ]; then
        log_info "移除旧软链接: $target"
        rm -f "$target"
    fi
}

# --- 创建软链接（幂等，支持文件与目录） ---
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
        local current_target expected
        current_target="$(readlink -f "$dst" 2>/dev/null || readlink "$dst")"
        expected="$(cd "$(dirname "$src")" && pwd -P)/$(basename "$src")"
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
    ln -s "$src" "$dst"
    log_ok "链接: $src -> $dst"
}
