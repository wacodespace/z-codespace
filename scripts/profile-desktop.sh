#!/usr/bin/env bash
# z-codespace/scripts/profile-desktop.sh
# desktop layer：alacritty 共享片段 + OS 特定终端配置
# 由 install.sh source 后通过 apply_desktop_* / install_desktop_apps_macos 调用
# ============================================================

# 防止重复 source
[[ -n "${_PROFILE_DESKTOP_SH_LOADED:-}" ]] && return 0
_PROFILE_DESKTOP_SH_LOADED=1

apply_desktop_shared() {
    local force="${1:-false}"
    log_step "应用 desktop 共享层（alacritty shared.toml）..."
    safe_link "$PROJECT_ROOT/configs/desktop/.config/alacritty/shared.toml" \
              "$HOME/.config/alacritty/shared.toml" "$force"
}

apply_desktop_macos() {
    local force="${1:-false}"
    log_step "应用 desktop/macos 层（alacritty / ghostty）..."
    safe_link "$PROJECT_ROOT/configs/desktop/macos/.config/alacritty/alacritty.toml" \
              "$HOME/.config/alacritty/alacritty.toml" "$force"
    safe_link "$PROJECT_ROOT/configs/desktop/macos/.config/ghostty/config" \
              "$HOME/.config/ghostty/config" "$force"
}

apply_desktop_linux() {
    local force="${1:-false}"
    log_step "应用 desktop/linux 层（alacritty）..."
    safe_link "$PROJECT_ROOT/configs/desktop/linux/.config/alacritty/alacritty.toml" \
              "$HOME/.config/alacritty/alacritty.toml" "$force"
}

# --- macOS 桌面 brew 安装 ---
install_homebrew() {
    if ! has_cmd brew; then
        log_step "安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -x /opt/homebrew/bin/brew ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        log_ok "Homebrew 已安装"
    fi
}

install_desktop_apps_macos() {
    log_step "macOS 桌面应用..."
    if ! has_cmd alacritty; then
        log_info "安装 Alacritty..."
        brew install --cask alacritty
    else
        log_ok "Alacritty 已安装"
    fi
    if ! has_cmd ghostty; then
        log_info "安装 Ghostty..."
        brew install --cask ghostty
    else
        log_ok "Ghostty 已安装"
    fi
    if ! has_cmd cmux; then
        log_info "安装 cmux（libghostty 内核，读取同一份 ~/.config/ghostty/config）..."
        brew tap manaflow-ai/cmux
        brew install --cask cmux
    else
        log_ok "cmux 已安装"
    fi
    if ! ls ~/Library/Fonts/MesloLG*NerdFont* &>/dev/null; then
        log_info "安装 MesloLG Nerd Font..."
        brew install --cask font-meslo-lg-nerd-font
    else
        log_ok "MesloLG Nerd Font 已安装"
    fi
}
