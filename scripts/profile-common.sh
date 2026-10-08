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

    apply_agent_skills "$force"
}

# 共享 Agent Skills：仓库 skills/ 是唯一真身，按目录软链到各 agent 的用户级 skill 目录。
#   ~/.agents/skills  Codex、Grok 读
#   ~/.claude/skills  Claude Code 读
# 只链单个 skill 目录、不链整个父目录，其他工具（如 understand-anything）放在同一目录下的 skill 不受影响。
# skills/<name>/bin/* 是 skill 自带的命令行工具，链到 ~/.local/bin。
apply_agent_skills() {
    local force="${1:-false}"
    local skill name tool
    log_step "应用共享 Agent Skills（Claude / Codex / Grok）..."
    for skill in "$PROJECT_ROOT"/skills/*/; do
        [ -f "$skill/SKILL.md" ] || continue
        skill="${skill%/}"
        name="$(basename "$skill")"
        safe_link "$skill" "$HOME/.agents/skills/$name" "$force"
        safe_link "$skill" "$HOME/.claude/skills/$name" "$force"
        for tool in "$skill"/bin/*; do
            [ -f "$tool" ] && [ -x "$tool" ] || continue
            safe_link "$tool" "$HOME/.local/bin/$(basename "$tool")" "$force"
        done
    done
}
