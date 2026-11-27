#!/usr/bin/env bash
# z-codespace/scripts/profile-desktop.sh
# desktop layer：OS 特定桌面配置软链（不负责装包，装软件见 BOOTSTRAP.md）
# 由 install.sh source 后通过 apply_desktop_* 调用
# ============================================================

# 防止重复 source
[[ -n "${_PROFILE_DESKTOP_SH_LOADED:-}" ]] && return 0
_PROFILE_DESKTOP_SH_LOADED=1

apply_desktop_macos() {
    local force="${1:-false}"
    log_step "应用 desktop/macos 层（ghostty / cmux / flameshot）..."
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
    safe_link "$PROJECT_ROOT/configs/desktop/.config/alacritty/shared.toml" \
              "$HOME/.config/alacritty/shared.toml" "$force"
    safe_link "$PROJECT_ROOT/configs/desktop/linux/.config/alacritty/alacritty.toml" \
              "$HOME/.config/alacritty/alacritty.toml" "$force"
}
