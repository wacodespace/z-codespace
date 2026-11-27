#!/usr/bin/env bash
# z-codespace/scripts/profile-server.sh
# server layer：Ubuntu server 特定配置软链（~/.bash_server + ~/.bash_site）
# .bashrc 末尾会自动 source 这两个文件
# ============================================================

# 防止重复 source
[[ -n "${_PROFILE_SERVER_SH_LOADED:-}" ]] && return 0
_PROFILE_SERVER_SH_LOADED=1

apply_server() {
    local force="${1:-false}"
    log_step "应用 server 层（~/.bash_server + ~/.bash_site，由 .bashrc 自动 source）..."
    safe_link "$PROJECT_ROOT/configs/server/.bash_server" "$HOME/.bash_server" "$force"
    # 当前用户的 Ubuntu server 即阿里 GPU 集群；未来若有其它 site，可在此处分支
    safe_link "$PROJECT_ROOT/configs/site/aliyun-gpu.sh"  "$HOME/.bash_site"   "$force"
}
