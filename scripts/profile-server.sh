#!/usr/bin/env bash
# z-codespace/scripts/profile-server.sh
# server layer：Ubuntu server 特定优化（~/.bash_server 软链）
# .bashrc 末尾会自动 source ~/.bash_server，所以只需安装软链
# ============================================================

# 防止重复 source
[[ -n "${_PROFILE_SERVER_SH_LOADED:-}" ]] && return 0
_PROFILE_SERVER_SH_LOADED=1

apply_server() {
    local force="${1:-false}"
    log_step "应用 server 层（~/.bash_server + ~/.bash_site，由 .bashrc 自动 source）..."
    safe_link "$PROJECT_ROOT/configs/server/.bash_server" "$HOME/.bash_server" "$force"
    # 当前用户的 Ubuntu server 即阿里 GPU 集群；未来若有其它 site，需在此处分支或抽出 apply_site_*
    safe_link "$PROJECT_ROOT/configs/site/aliyun-gpu.sh"  "$HOME/.bash_site"   "$force"
}
