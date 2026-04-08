#!/usr/bin/env bash
# z-codespace/scripts/install-deps.sh — 安装 Neovim 及其运行依赖
# ============================================================
#
# 依赖分类:
#
# 必须 (运行时):
#   git        — 插件管理
#   ripgrep    — telescope live_grep
#   fd         — telescope find_files
#   gcc/clang  — treesitter parser 编译
#   node       — 部分 LSP (pyright, bashls) 需要
#   python3    — Python 开发 / LSP
#
# 必须 (安装阶段):
#   curl       — 下载 neovim / nvm
#   unzip/tar  — 解压
#   make       — treesitter parser 编译
#
# 可选:
#   fzf        — 命令行模糊搜索
#   tmux       — 终端复用
#   lazygit    — Git TUI
#   xclip/xsel — Linux 系统剪贴板支持
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT_ROOT="$(get_project_root)"
OS="$(detect_os)"
ARCH="$(detect_arch)"

# Neovim 版本
NVIM_MIN_VERSION="0.9.0"
NVIM_STABLE_VERSION="0.10.4"

# ============================================================
# macOS 安装
# ============================================================
install_deps_macos() {
    log_step "macOS: 检查 Homebrew..."
    if ! has_cmd brew; then
        log_info "安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        log_ok "Homebrew 已安装"
    fi

    log_step "macOS: 安装依赖..."
    local pkgs=(neovim ripgrep fd fzf node python3 tmux lazygit)
    for pkg in "${pkgs[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            log_ok "$pkg 已安装"
        else
            log_info "安装 $pkg..."
            brew install "$pkg"
        fi
    done
}

# ============================================================
# Linux 安装
# ============================================================
install_deps_linux() {
    local distro
    distro="$(detect_linux_distro)"
    local pkg_mgr
    pkg_mgr="$(detect_pkg_manager)"

    log_step "Linux ($distro, $pkg_mgr): 安装系统依赖..."

    case "$pkg_mgr" in
        apt)
            if has_cmd sudo; then
                sudo apt-get update -qq
                sudo apt-get install -y \
                    git curl wget unzip tar xz-utils \
                    build-essential \
                    ripgrep fd-find \
                    python3 python3-pip python3-venv \
                    tmux fzf xclip
            else
                log_warn "无 sudo 权限，跳过系统包安装"
                log_warn "请联系管理员安装: git curl build-essential ripgrep fd-find python3 tmux"
            fi
            # Debian/Ubuntu 上 fd-find 的二进制名是 fdfind，创建 fd 链接
            if has_cmd fdfind && ! has_cmd fd; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
                log_info "创建符号链接: fdfind -> ~/.local/bin/fd"
            fi
            ;;
        dnf)
            if has_cmd sudo; then
                sudo dnf install -y \
                    git curl wget unzip tar xz \
                    gcc gcc-c++ make \
                    ripgrep fd-find \
                    python3 python3-pip \
                    tmux fzf xclip
            else
                log_warn "无 sudo 权限，跳过系统包安装"
            fi
            ;;
        yum)
            if has_cmd sudo; then
                sudo yum install -y \
                    git curl wget unzip tar xz \
                    gcc gcc-c++ make \
                    python3 python3-pip \
                    tmux xclip
                # ripgrep/fd 可能不在默认 yum 源中
                if ! has_cmd rg; then
                    log_warn "ripgrep 不在 yum 默认源中，尝试手动安装..."
                    install_rg_binary
                fi
                if ! has_cmd fd; then
                    log_warn "fd 不在 yum 默认源中，尝试手动安装..."
                    install_fd_binary
                fi
            else
                log_warn "无 sudo 权限，跳过系统包安装"
            fi
            ;;
        pacman)
            if has_cmd sudo; then
                sudo pacman -Sy --noconfirm \
                    git curl wget unzip tar xz \
                    base-devel \
                    ripgrep fd \
                    python python-pip \
                    tmux fzf xclip
            else
                log_warn "无 sudo 权限，跳过系统包安装"
            fi
            ;;
        *)
            log_warn "未知包管理器 ($pkg_mgr)，请手动安装依赖"
            log_warn "需要: git curl gcc make ripgrep fd python3 tmux"
            ;;
    esac

    # Neovim
    install_nvim_linux

    # Node.js
    install_node_if_missing
}

# --- 手动安装 ripgrep (针对无 rg 的 yum 系统) ---
install_rg_binary() {
    local ver="14.1.1"
    local url="https://github.com/BurntSushi/ripgrep/releases/download/${ver}/ripgrep-${ver}-x86_64-unknown-linux-musl.tar.gz"
    if [ "$ARCH" = "arm64" ]; then
        url="https://github.com/BurntSushi/ripgrep/releases/download/${ver}/ripgrep-${ver}-aarch64-unknown-linux-gnu.tar.gz"
    fi
    local tmpdir
    tmpdir=$(mktemp -d)
    curl -fsSL "$url" -o "$tmpdir/rg.tar.gz"
    tar xzf "$tmpdir/rg.tar.gz" -C "$tmpdir"
    mkdir -p "$HOME/.local/bin"
    find "$tmpdir" -name "rg" -type f -exec cp {} "$HOME/.local/bin/rg" \;
    chmod +x "$HOME/.local/bin/rg"
    rm -rf "$tmpdir"
    log_ok "ripgrep 安装到 ~/.local/bin/rg"
}

# --- 手动安装 fd (针对无 fd 的 yum 系统) ---
install_fd_binary() {
    local ver="10.2.0"
    local url="https://github.com/sharkdp/fd/releases/download/v${ver}/fd-v${ver}-x86_64-unknown-linux-musl.tar.gz"
    if [ "$ARCH" = "arm64" ]; then
        url="https://github.com/sharkdp/fd/releases/download/v${ver}/fd-v${ver}-aarch64-unknown-linux-gnu.tar.gz"
    fi
    local tmpdir
    tmpdir=$(mktemp -d)
    curl -fsSL "$url" -o "$tmpdir/fd.tar.gz"
    tar xzf "$tmpdir/fd.tar.gz" -C "$tmpdir"
    mkdir -p "$HOME/.local/bin"
    find "$tmpdir" -name "fd" -type f -exec cp {} "$HOME/.local/bin/fd" \;
    chmod +x "$HOME/.local/bin/fd"
    rm -rf "$tmpdir"
    log_ok "fd 安装到 ~/.local/bin/fd"
}

# --- 安装 Neovim (Linux，下载预编译二进制到 ~/.local) ---
install_nvim_linux() {
    if has_cmd nvim && check_nvim_version "$NVIM_MIN_VERSION"; then
        log_ok "Neovim 已安装: $(nvim --version | head -n1)"
        return 0
    fi

    log_step "安装 Neovim v${NVIM_STABLE_VERSION} 到 ~/.local ..."
    mkdir -p "$HOME/.local/bin"

    local url
    case "$ARCH" in
        x86_64)
            url="https://github.com/neovim/neovim/releases/download/v${NVIM_STABLE_VERSION}/nvim-linux-x86_64.tar.gz"
            ;;
        arm64)
            url="https://github.com/neovim/neovim/releases/download/v${NVIM_STABLE_VERSION}/nvim-linux-arm64.tar.gz"
            ;;
        *)
            log_error "不支持的架构: $ARCH"
            return 1
            ;;
    esac

    local tmpdir
    tmpdir=$(mktemp -d)
    log_info "下载: $url"
    curl -fsSL "$url" -o "$tmpdir/nvim.tar.gz"
    tar xzf "$tmpdir/nvim.tar.gz" -C "$tmpdir"

    # 找到解压后的目录并复制到 ~/.local
    local extracted
    extracted=$(find "$tmpdir" -maxdepth 1 -type d -name 'nvim-*' | head -1)
    if [ -z "$extracted" ]; then
        log_error "解压失败"
        rm -rf "$tmpdir"
        return 1
    fi

    cp -rf "$extracted"/* "$HOME/.local/"
    rm -rf "$tmpdir"

    if [ -x "$HOME/.local/bin/nvim" ]; then
        log_ok "Neovim 安装成功: $("$HOME/.local/bin/nvim" --version | head -n1)"
    else
        log_error "Neovim 安装失败"
        return 1
    fi
}

# --- 安装 Node.js (如果缺失，通过 nvm) ---
install_node_if_missing() {
    if has_cmd node; then
        log_ok "Node.js 已安装: $(node --version 2>/dev/null)"
        return 0
    fi

    log_step "安装 Node.js (通过 nvm)..."
    export NVM_DIR="$HOME/.nvm"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    fi
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm alias default 'lts/*'
    log_ok "Node.js 安装完成: $(node --version)"
}

# ============================================================
# 主入口
# ============================================================
main() {
    log_step "=========================================="
    log_step "安装 Neovim 环境依赖"
    log_step "系统: $OS ($ARCH)"
    log_step "=========================================="
    echo ""

    case "$OS" in
        macos) install_deps_macos ;;
        linux) install_deps_linux ;;
        *)
            log_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac

    echo ""
    log_ok "依赖安装完成。"
    echo ""
    log_info "请确保 ~/.local/bin 在 PATH 中:"
    log_info "  export PATH=\"\$HOME/.local/bin:\$PATH\""
}

main "$@"
