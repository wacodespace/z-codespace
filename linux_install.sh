#!/bin/bash
# Linux 服务器环境一键安装脚本
# 用法: bash install-linux.sh [--force]

set -e

# --- 参数解析 ---
FORCE=false
DOTFILES_DIR="$(dirname "$(readlink -f "$0")")"

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "用法: $0 [--force]"
            echo "  --force     : 强制覆盖，不备份"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# --- 颜色输出 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[信息]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
log_error() { echo -e "${RED}[错误]${NC} $1"; }
log_linux() { echo -e "${BLUE}[Linux]${NC} $1"; }

# --- 执行包装器 ---
run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[预览] $*"
    else
        "$@"
    fi
}

# --- 备份函数 ---
backup_item() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        log_warn "备份 $target -> $backup"
        run cp -r "$target" "$backup"
    fi
}

# --- 清理旧备份 ---
cleanup_backups() {
    local target="$1"
    local pattern="${target}.bak.*"
    local backups=($(ls -t $pattern 2>/dev/null))
    local count=${#backups[@]}
    
    if [[ $count -gt 3 ]]; then
        log_warn "清理旧备份，保留最近 3 个"
        for ((i=3; i<count; i++)); do
            run rm -rf "${backups[$i]}"
        done
    fi
}

# --- 创建符号链接 ---
link_file() {
    local src="$1"
    local dst="$2"
    
    if [[ "$FORCE" != "true" ]]; then
        backup_item "$dst"
        cleanup_backups "$dst"
    fi
    
    log_info "链接 $src -> $dst"
    run mkdir -p "$(dirname "$dst")"
    run ln -sf "$src" "$dst"
}

# --- 检测包管理器 ---
detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# --- 安装基础软件 ---
install_packages() {
    local pkg_manager=$(detect_package_manager)
    
    case $pkg_manager in
        apt)
            log_linux "使用 apt 安装软件..."
            sudo apt-get update
            sudo apt-get install -y vim tmux curl wget git htop openssh-client
            ;;
        yum|dnf)
            log_linux "使用 $pkg_manager 安装软件..."
            sudo $pkg_manager install -y vim tmux curl wget git htop openssh-clients
            ;;
        pacman)
            log_linux "使用 pacman 安装软件..."
            sudo pacman -Sy --noconfirm vim tmux curl wget git htop openssh
            ;;
        *)
            log_warn "未识别的包管理器，请手动安装: vim tmux curl wget git htop openssh-client"
            ;;
    esac
}

# --- 设置服务器环境 ---
setup_server_env() {
    # 检查是否在 SSH 会话中
    if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
        log_linux "检测到 SSH 会话，优化服务器配置..."
        
        # 添加服务器特定配置
        if [[ -f "$DOTFILES_DIR/configs/linux/.bash_server" ]]; then
            echo "" >> ~/.bashrc
            echo "# 服务器特定配置" >> ~/.bashrc
            cat "$DOTFILES_DIR/configs/linux/.bash_server" >> ~/.bashrc
        fi
    fi
}

# --- 主函数 ---
main() {
    echo "=== Linux 服务器环境安装脚本 ==="
    echo "源目录: $DOTFILES_DIR"
    echo "模式: ${FORCE:+强制覆盖}"
    echo ""
    
    # 检测系统信息
    log_linux "系统信息: $(uname -a)"
    log_linux "包管理器: $(detect_package_manager)"
    echo ""
    
    # 安装基础软件
    log_info "安装基础软件包..."
    install_packages
    
    # 安装配置文件
    log_info "安装配置文件..."
    link_file "$DOTFILES_DIR/configs/common/.bash_profile" "$HOME/.bash_profile"
    link_file "$DOTFILES_DIR/configs/common/.bashrc" "$HOME/.bashrc"
    link_file "$DOTFILES_DIR/configs/common/.vimrc" "$HOME/.vimrc"
    link_file "$DOTFILES_DIR/configs/common/.tmux.conf" "$HOME/.tmux.conf"
    if [[ -f "$DOTFILES_DIR/configs/linux/.config/alacritty/alacritty.toml" ]]; then
        link_file "$DOTFILES_DIR/configs/common/.config/alacritty/shared.toml" "$HOME/.config/alacritty/shared.toml"
        link_file "$DOTFILES_DIR/configs/linux/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
    fi
    
    # 设置服务器环境
    setup_server_env

    # SSH key
    log_linux "检查 SSH key..."
    bash "$DOTFILES_DIR/scripts/setup-ssh.sh"
    
    # Git 配置
    if ! git config --global --get "url.git@github.com:.insteadOf" >/dev/null 2>&1; then
        log_linux "设置 Git HTTPS -> SSH 重写规则"
        git config --global "url.git@github.com:".insteadOf "https://github.com/"
    fi
    
    echo ""
    log_linux "Linux 服务器环境配置完成！"
    echo "请执行 'source ~/.bashrc' 或重新打开终端使配置生效。"
    echo ""
    echo "提示："
    echo "  - 使用 tmux 进行会话管理: tmux new -s session_name"
    echo "  - 服务器已优化 SSH 体验"
    echo "  - 基础工具已安装: vim, tmux, git, htop, OpenSSH client"
    echo "  - SSH key 已检查；如新生成，请把公钥添加到 GitHub"
    echo "  - Alacritty 配置已安装到 ~/.config/alacritty/（如果仓库内存在 Linux 配置）"
}

main "$@"
