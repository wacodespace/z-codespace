#!/bin/bash
# macOS 本地开发环境一键安装脚本
# 用法: bash install-macos.sh [--force]

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
log_macos() { echo -e "${BLUE}[macOS]${NC} $1"; }

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

# --- 创建符号链接 ---
link_file() {
    local src="$1"
    local dst="$2"
    
    if [[ "$FORCE" != "true" ]]; then
        backup_item "$dst"
    fi
    
    log_info "链接 $src -> $dst"
    run mkdir -p "$(dirname "$dst")"
    run ln -sf "$src" "$dst"
}

# --- 检查并安装 Homebrew ---
install_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_macos "安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # 添加到 PATH
        if [[ -x /opt/homebrew/bin/brew ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        log_macos "Homebrew 已安装"
    fi
}

# --- 安装 macOS 应用 ---
install_apps() {
    log_macos "检查安装终端应用..."
    
    # Alacritty
    if ! command -v alacritty >/dev/null 2>&1; then
        log_macos "安装 Alacritty..."
        brew install --cask alacritty
    fi
    
    # Ghostty (如果可用)
    if ! command -v ghostty >/dev/null 2>&1; then
        log_macos "Ghostty 未安装，可通过 Homebrew 安装: brew install --cask ghostty"
    fi
    
    # Nerd Font（LazyVim 图标渲染需要）
    if ! ls ~/Library/Fonts/MesloLG*NerdFont* &>/dev/null; then
        log_macos "安装 MesloLG Nerd Font..."
        brew install --cask font-meslo-lg-nerd-font
    else
        log_macos "MesloLG Nerd Font 已安装"
    fi
}

# --- 主函数 ---
main() {
    echo "=== macOS 开发环境安装脚本 ==="
    echo "源目录: $DOTFILES_DIR"
    echo "模式: ${FORCE:+强制覆盖}"
    echo ""
    
    # 安装 Homebrew
    install_homebrew
    
    # 安装应用
    install_apps
    
    # 安装通用配置
    log_info "安装通用配置..."
    link_file "$DOTFILES_DIR/configs/common/.bash_profile" "$HOME/.bash_profile"
    link_file "$DOTFILES_DIR/configs/common/.bashrc" "$HOME/.bashrc"
    link_file "$DOTFILES_DIR/configs/common/.vimrc" "$HOME/.vimrc"
    link_file "$DOTFILES_DIR/configs/common/.tmux.conf" "$HOME/.tmux.conf"
    
    # 安装 macOS 特定配置
    log_macos "安装 macOS 特定配置..."
    link_file "$DOTFILES_DIR/configs/common/.config/alacritty/shared.toml" "$HOME/.config/alacritty/shared.toml"
    link_file "$DOTFILES_DIR/configs/macos/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
    link_file "$DOTFILES_DIR/configs/macos/.config/ghostty/config" "$HOME/.config/ghostty/config"

    # SSH key
    log_macos "检查 SSH key..."
    bash "$DOTFILES_DIR/scripts/setup-ssh.sh"
    
    echo ""
    log_macos "macOS 环境配置完成！"
    echo "请执行 'source ~/.bashrc' 或重新打开终端使配置生效。"
    echo ""
    echo "提示："
    echo "  - Alacritty 配置已安装到 ~/.config/alacritty/"
    echo "  - Ghostty 配置已安装到 ~/.config/ghostty/"
    echo "  - SSH key 已检查；如新生成，请把公钥添加到 GitHub"
    echo "  - 使用 'brew install --cask <app>' 安装其他应用"
}

main "$@"
