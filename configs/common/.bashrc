# ~/.bashrc - 个人 Shell 配置（入口 + env + loader）
# Git 别名 / AI CLI / 阿里 site 各在 bash/*.sh 和 configs/site/aliyun-gpu.sh
# ============================================================

# Homebrew on Apple Silicon
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- 非交互式退出 ---
case $- in
    *i*) ;;
      *) return;;
esac

# --- 代理管理 ---
# proxy  — 自动探测本地代理端口并设置环境变量
# noproxy — 清除代理环境变量
proxy() {
    local ports=(7897 7890 1087 1080 8080)
    for p in "${ports[@]}"; do
        if curl -so /dev/null --connect-timeout 1 -x "http://127.0.0.1:$p" http://www.google.com 2>/dev/null; then
            export HTTP_PROXY="http://127.0.0.1:$p"
            export HTTPS_PROXY="http://127.0.0.1:$p"
            export ALL_PROXY="socks5://127.0.0.1:$p"
            export NO_PROXY="localhost,127.0.0.1,::1"
            echo "proxy set → 127.0.0.1:$p"
            return 0
        fi
    done
    echo "no proxy found (tried: ${ports[*]})"
    return 1
}
noproxy() {
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
    echo "proxy cleared"
}

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
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u:\w \$ '
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

# --- 平台特定配置 ---
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS 特定配置
    alias ls='ls -G'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux 特定配置
    alias ls='ls --color=auto'
fi

# --- 常用别名 ---
alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'
alias rm='rm -I'
alias s='ssh'
alias pps='pip show'

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

# --- GPU 监控别名 (NVIDIA) ---
alias nv='nvidia-smi'
alias wnv='watch -n 0.1 nvidia-smi'

# --- GPU 监控别名 (AMD ROCm) ---
alias rc='rocm-smi'
alias wrc='watch -n 0.1 rocm-smi'
alias rcp='rocm-smi --showpids'
alias rocm='rocm-smi --showuse --showmeminfo vram --showpids'
alias wrocm='watch -n 0.1 rocm-smi --showuse --showmeminfo vram --showpids'

# --- PATH (去重整理) ---
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.cargo/bin:/opt/rocm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# --- AI CLI 固定 npm prefix ---
# Claude Code / Codex 统一安装到这里，不依赖当前 npm config prefix。
export AI_NPM_PREFIX="${AI_NPM_PREFIX:-$HOME/.npm-global}"

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

# --- 加载拆分模块（git aliases / AI CLI 等） ---
_BASH_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/bash"
[ -d "$_BASH_DIR" ] && {
    . "$_BASH_DIR/git-aliases.sh"
    . "$_BASH_DIR/ai-cli.sh"
}
unset _BASH_DIR

# --- 服务器配置 (按需 source，由 install.sh 创建 ~/.bash_server / ~/.bash_site 软链接) ---
[ -f ~/.bash_server ] && . ~/.bash_server
[ -f ~/.bash_site ] && . ~/.bash_site

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
# <<< grok installer <<<
