# ~/.bashrc - 个人 Shell 配置
# ============================================================

# --- 非交互式退出 ---
case $- in
    *i*) ;;
      *) return;;
esac

# --- 代理环境变量 ---
export HTTP_PROXY=http://127.0.0.1:1080
export HTTPS_PROXY=http://127.0.0.1:1080

# --- 终端与颜色 ---
export TERM=xterm-256color
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export LANG=C.UTF-8
export LC_ALL=C.UTF-8


# --- 历史记录 ---
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# --- Shell 选项 ---
shopt -s checkwinsize

# --- 提示符 ---
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# --- 颜色别名 ---
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# --- 常用别名 ---
alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'
alias rm='rm -I'

# --- 导航别名 ---
alias i='iflow'
alias cdn='cd /chatgpt_nas'
alias cdz='cd /home/admin/zhc'

# --- 本仓库 Git 作者（写入该仓库 .git/config，不依赖全局 user.name / user.email）---
# 优先 $DOTFILES_DIR；否则若 ~/.bashrc 是指向本仓库的符号链接则自动解析目录；否则用 $HOME/dotfiles
{
    _df_git=""
    if [[ -n "${DOTFILES_DIR:-}" && -d "${DOTFILES_DIR}/.git" ]]; then
        _df_git="$DOTFILES_DIR"
    elif [[ -L "$HOME/.bashrc" ]]; then
        _df_git=$(dirname "$(readlink -f "$HOME/.bashrc" 2>/dev/null)" 2>/dev/null) || true
        [[ -n "$_df_git" && ! -d "${_df_git}/.git" ]] && _df_git=""
    fi
    if [[ -z "$_df_git" && -d "$HOME/dotfiles/.git" ]]; then
        _df_git="$HOME/dotfiles"
    fi
    if [[ -n "$_df_git" && -d "${_df_git}/.git" ]]; then
        git -C "$_df_git" config user.name "acodespace"
        git -C "$_df_git" config user.email "7epimenides@gmail.com"
    fi
    unset _df_git
}

# --- Git 别名 ---
alias g='git'

gl() {
    git log --oneline -"${1:-10}"
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
alias glt='git reflog --date=short'
alias gamd='git commit --amend --no-edit'
alias gpuf='git push --force-with-lease'
alias gfs='git diff --stat --'
alias gfn='git diff --numstat --'

# --- GPU 监控别名 (NVIDIA) ---
alias nv='nvidia-smi'
alias wnv='watch -n 0.1 nvidia-smi'

# --- GPU 监控别名 (AMD ROCm) ---
alias rc='rocm-smi'
alias wrc='watch -n 0.1 rocm-smi'
alias rcp='rocm-smi --showpids'
alias rocm='rocm-smi --showuse --showmeminfo vram --showpids'
alias wrocm='watch -n 0.1 rocm-smi --showuse --showmeminfo vram --showpids'

# --- 工具别名 ---
alias ossutil='ossutil_x86_64'
alias pps='pip show'
alias v3='rocprofv3'
alias oss='ossutil64 -i $OSS_AK_ID -k $OSS_AK_SECRET -e ${OSS_ENDPOINT:-cn-zhangjiakou.oss.aliyuncs.com} cp'

# --- docker → pouch 包装 ---
docker() {
    pouch "$@"
}

# --- PATH (去重整理) ---
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.cargo/bin:/opt/rocm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# --- Git 全局配置: HTTPS → SSH ---
git config --global url."git@github.com:".insteadOf "https://github.com/"

# --- Git 中文编码配置 ---
git config --global core.quotepath false
git config --global gui.encoding utf-8
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8

# --- Bash 补全 ---
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# --- 加载用户自定义别名 ---
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# --- 加载私有配置（含密钥，不进 git 仓库）---
[ -f ~/.bash_private ] && . ~/.bash_private

# --- NVM ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
