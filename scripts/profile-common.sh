#!/usr/bin/env bash
# z-codespace/scripts/profile-common.sh
# common layer：bash/vim/tmux 三 profile 共用配置
# 由 install.sh source 后通过 apply_common 调用
# ============================================================

# 防止重复 source
[[ -n "${_PROFILE_COMMON_SH_LOADED:-}" ]] && return 0
_PROFILE_COMMON_SH_LOADED=1

apply_common() {
    local force="${1:-false}"
    log_step "应用 common 层（bash_profile / bashrc / vimrc / tmux.conf）..."
    safe_link "$PROJECT_ROOT/configs/common/.bash_profile" "$HOME/.bash_profile" "$force"
    safe_link "$PROJECT_ROOT/configs/common/.bashrc"       "$HOME/.bashrc"       "$force"
    safe_link "$PROJECT_ROOT/configs/common/.vimrc"        "$HOME/.vimrc"        "$force"
    safe_link "$PROJECT_ROOT/configs/common/.tmux.conf"    "$HOME/.tmux.conf"    "$force"

    # SSH site config 软链（所有 profile 共用，setup-ssh.sh 会把 Include 写进 ~/.ssh/config）
    local site_ssh="$PROJECT_ROOT/configs/site/ssh_config.site"
    if [ -f "$site_ssh" ]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        safe_link "$site_ssh" "$HOME/.ssh/config.site" "$force"
    fi
}
