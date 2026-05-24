# git-aliases.sh - Git 快捷别名 + 函数
# 由 configs/common/.bashrc 的 BASH_DIR loader 自动 source
# 用户面：g / gp / gs / gss / gsw / gb / gc / gclone / gcl / grl / gamd / gpuf / gfs / gfn
#         gl / glt / gls / gcm / gg
# ============================================================

# --- Git 别名 ---
alias g='git'

# 兼容旧配置：glt 曾是 alias，需先清理，否则 Bash 会展开 glt() 导致语法错误。
unalias glt 2>/dev/null || true

gl() {
    git log --oneline -"${1:-10}"
}
glt() {
    git log -n "${1:-10}" --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%C(yellow)%h%Creset %Cgreen%ad%Creset %s'
}
gls() {
    git log --shortstat -"${1:-10}"
}
alias gp='git pull'
alias gf='git diff'
alias gs='git status'
alias gss='git submodule status'
alias gsw='git switch'
alias gb='git branch'
alias gc='git checkout'
alias gclone='git clone --recursive'
alias gcl='git clone --recurse-submodules'
alias grl='git reflog --date=short'
alias gamd='git commit --amend --no-edit'
alias gpuf='git push --force-with-lease'
alias gfs='git diff --stat --'
alias gfn='git diff --numstat --'

# 先 pull 再 commit（避免冲突）
gcm() {
    if [ $# -eq 0 ]; then
        echo "用法: gcm '提交信息'" >&2
        return 1
    fi
    git pull && git commit -m "$1"
}

# 列出上面定义的 Git 别名与函数（gg：git 快捷键备忘）
gg() {
    printf '%s\n' "=== Git 快捷键（本文件）===" ""
    printf '%s\n' "别名:"
    alias | grep -E "^alias (g|gp|gf|gs|gss|gsw|gb|gc|gclone|gcl|grl|gamd|gpuf|gfs|gfn)='" | sed 's/^/  /' | sort
    printf '%s\n' "" "函数:"
    printf '%s\n' \
        "  gl [N]     git log --oneline（省略 N 时默认 10 条）" \
        "  glt [N]    git log 带提交时间（省略 N 时默认 10 条）" \
        "  gls [N]    git log --shortstat（省略 N 时默认 10 条）" \
        "  gcm 'msg'  先 git pull 再 git commit -m（避免冲突）" \
        "" \
        "（提示：单独看全部 alias 用命令 alias）"
}
