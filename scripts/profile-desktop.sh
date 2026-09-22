#!/usr/bin/env bash
# z-codespace/scripts/profile-desktop.sh
# desktop layer：alacritty 共享片段 + OS 特定桌面配置
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
    log_step "应用 desktop/macos 层（alacritty / ghostty / cmux / flameshot）..."
    safe_link "$PROJECT_ROOT/configs/desktop/macos/.config/alacritty/alacritty.toml" \
              "$HOME/.config/alacritty/alacritty.toml" "$force"
    safe_link "$PROJECT_ROOT/configs/desktop/macos/.config/ghostty/config" \
              "$HOME/.config/ghostty/config" "$force"
    safe_link "$PROJECT_ROOT/configs/desktop/macos/.config/ghostty/config" \
              "$HOME/Library/Application Support/com.cmuxterm.app/config.ghostty" "$force"
    safe_link "$PROJECT_ROOT/configs/desktop/macos/.config/flameshot/flameshot.ini" \
              "$HOME/.config/flameshot/flameshot.ini" "$force"
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

install_flameshot_macos() {
    local app_path="/Applications/Flameshot.app"
    if brew list --cask flameshot >/dev/null 2>&1 || [ -d "$app_path" ]; then
        log_ok "Flameshot 已安装"
        return 0
    fi

    # The official Homebrew cask was disabled on 2026-09-01 because the app is
    # not notarized. Our tap pins and verifies the upstream release while
    # keeping Homebrew's quarantine and installation lifecycle intact.
    log_info "安装 Flameshot..."
    if ! brew tap | grep -qx "wacodespace/z-codespace"; then
        brew tap wacodespace/z-codespace https://github.com/wacodespace/z-codespace
    fi
    brew install --cask wacodespace/z-codespace/flameshot
    log_ok "Flameshot 已安装"
    log_warn "Flameshot 首次启动需在 macOS 隐私与安全中批准并授予屏幕录制权限"
}

install_desktop_apps_macos() {
    log_step "macOS 桌面应用..."
    if ! has_cmd alacritty; then
        log_info "安装 Alacritty..."
        if ! brew install --cask alacritty; then
            log_warn "Alacritty cask 已被 Homebrew 禁用，跳过安装"
            log_warn "macOS 将继续使用 Ghostty / cmux"
        fi
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
    if ! brew list --cask rectangle >/dev/null 2>&1 && [ ! -d "/Applications/Rectangle.app" ]; then
        log_info "安装 Rectangle..."
        brew install --cask rectangle
    else
        log_ok "Rectangle 已安装"
    fi
    install_flameshot_macos
    if ! ls ~/Library/Fonts/MesloLG*NerdFont* &>/dev/null; then
        log_info "安装 MesloLG Nerd Font..."
        brew install --cask font-meslo-lg-nerd-font
    else
        log_ok "MesloLG Nerd Font 已安装"
    fi
}
