# ~/.bashrc - 个人 Shell 配置
# ============================================================

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

# --- 导航别名 ---
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
alias s='ssh'
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
    alias | grep -E "^alias (g|gp|gf|gs|gss|gsw|gb|gc|gclone|gcl|glt|gamd|gpuf|gfs|gfn)='" | sed 's/^/  /' | sort
    printf '%s\n' "" "函数:"
    printf '%s\n' \
        "  gl [N]     git log --oneline（省略 N 时默认 10 条）" \
        "  gls [N]    git log --shortstat（省略 N 时默认 10 条）" \
        "  gcm 'msg'  先 git pull 再 git commit -m（避免冲突）" \
        "" \
        "（提示：单独看全部 alias 用命令 alias）"
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

# --- 工具别名 ---
if [[ "$(uname -s)" == "Linux" ]]; then
    alias ossutil='ossutil_x86_64'
fi
alias pps='pip show'
alias v3='rocprofv3'
alias oss='ossutil64 -i $OSS_AK_ID -k $OSS_AK_SECRET -e ${OSS_ENDPOINT:-cn-zhangjiakou.oss.aliyuncs.com} cp'

# --- docker → pouch 包装 ---
docker() {
    pouch "$@"
}

# --- PATH (去重整理) ---
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.cargo/bin:/opt/rocm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# --- npm 全局安装目录（避免 sudo，但与 nvm 不兼容）---
# 仅在未使用 nvm 时设置，避免与 nvm 的 prefix 管理冲突
if [ -z "${NVM_DIR:-}" ] && [ ! -d "$HOME/.nvm" ]; then
    mkdir -p "$HOME/.npm-global"
    if command -v npm >/dev/null 2>&1; then
        npm config set prefix "$HOME/.npm-global" 2>/dev/null || true
    fi
fi

# --- Git 全局配置: HTTPS → SSH (仅 Linux) ---
if [[ "$(uname -s)" == "Linux" ]]; then
    git config --global url."git@github.com:".insteadOf "https://github.com/"
fi

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

_ai_fetch() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$1"
    else
        printf '%s\n' "需要 curl 或 wget，当前系统未找到。" >&2
        return 1
    fi
}

_ai_download_to() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1" -o "$2"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$2" "$1"
    else
        printf '%s\n' "需要 curl 或 wget，当前系统未找到。" >&2
        return 1
    fi
}

_ai_file_looks_like_shell() {
    [ -s "$1" ] || return 1
    head -n 5 "$1" | grep -Eiq '^(#!|set[[:space:]]+-|[[:space:]]*(if|case|function)[[:space:](]|[[:space:]]*[A-Za-z_][A-Za-z0-9_]*\(\)[[:space:]]*\{)'
}

_ai_ensure_nvm() {
    export NVM_DIR="$HOME/.nvm"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        _ai_fetch "https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh" | bash || return 1
    fi
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    command -v nvm >/dev/null 2>&1
}

_ai_ensure_node() {
    local node_major=""
    if command -v node >/dev/null 2>&1; then
        node_major=$(node -p "process.versions.node.split('.')[0]" 2>/dev/null || true)
    fi
    if [ -n "$node_major" ] && [ "$node_major" -ge 18 ] && command -v npm >/dev/null 2>&1; then
        return 0
    fi
    _ai_ensure_nvm || return 1
    nvm install --lts || return 1
    nvm alias default 'lts/*' >/dev/null 2>&1 || true
    nvm use default >/dev/null 2>&1 || nvm use --lts || return 1
    command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1
}

_install_claude_code() {
    if command -v claude >/dev/null 2>&1; then
        printf '%s\n' "claude 已存在：$(command -v claude)"
        claude --version 2>/dev/null || true
        return 0
    fi
    local installer_tmp=""
    installer_tmp=$(mktemp 2>/dev/null) || installer_tmp="/tmp/claude-install.$$"
    if _ai_download_to "https://claude.ai/install.sh" "$installer_tmp"; then
        if _ai_file_looks_like_shell "$installer_tmp"; then
            if bash "$installer_tmp"; then
                hash -r
            fi
        else
            printf '%s\n' "Claude 原生安装脚本不可用，可能是区域限制或返回了网页，改用 npm 安装。" >&2
        fi
    fi
    rm -f "$installer_tmp"
    if command -v claude >/dev/null 2>&1; then
        printf '%s\n' "Claude Code 安装完成。"
        claude --version 2>/dev/null || true
        return 0
    fi
    _ai_ensure_node || return 1
    npm install -g @anthropic-ai/claude-code || return 1
    hash -r
    if command -v claude >/dev/null 2>&1; then
        printf '%s\n' "Claude Code 安装完成（npm 回退方案）。"
        claude --version 2>/dev/null || true
        return 0
    fi
    printf '%s\n' "Claude Code 安装失败。" >&2
    return 1
}

_install_codex() {
    _ai_ensure_node || return 1
    npm install -g @openai/codex || return 1
    hash -r
    if command -v codex >/dev/null 2>&1; then
        printf '%s\n' "Codex 安装完成。"
        codex --version 2>/dev/null || true
        return 0
    fi
    printf '%s\n' "Codex 安装失败。" >&2
    return 1
}

icc() {
    _install_claude_code
}

icx() {
    _install_codex
}

cc() {
    claude "$@"
}

cx() {
    codex "$@"
}

# 服务器特定配置
# Linux 服务器特定配置

# SSH 会话优化
if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    # 设置终端标题为 user@host:dir
    case "$TERM" in
        xterm*|rxvt*)
            PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
            ;;
    esac
    
    # 防止 SSH 会话挂起
    export TMOUT=0
    
    # 服务器提示符优化
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# 服务器性能监控别名
alias ps='ps aux'
alias du='du -h'
alias df='df -h'
alias top='htop'  # 如果安装了 htop

# 网络工具别名
alias myip='curl -s ifconfig.me'
alias ports='netstat -tuln'

# 快速导航
alias cdw='cd /var/www'
alias cdl='cd /var/log'
alias cdc='cd /etc'

# 安全操作提醒
alias rm='rm -I'
alias cp='cp -i'
alias mv='mv -i'

# 服务器信息
alias about='echo "系统: $(uname -s)" && echo "版本: $(uname -r)" && echo "架构: $(uname -m)" && echo "在线: $(uptime -p)"'

# Git 本地用户配置
alias gsn='git config user.name "acodespace"'
alias gse='git config user.email "7epimenides@gmail.com"'
alias gsu='git config user.name "acodespace" && git config user.email "7epimenides@gmail.com" && echo "Git 用户配置完成: acodespace <7epimenides@gmail.com>"'
alias gclun='git config --local user.name'
alias gclue='git config --local user.email'
alias gcgun='git config --global user.name'
alias gcgue='git config --global user.email'

# 服务器特定配置
# Linux 服务器特定配置

# SSH 会话优化
if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    # 设置终端标题为 user@host:dir
    case "$TERM" in
        xterm*|rxvt*)
            PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
            ;;
    esac
    
    # 防止 SSH 会话挂起
    export TMOUT=0
    
    # 服务器提示符优化
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# 服务器性能监控别名
alias ps='ps aux'
alias du='du -h'
alias df='df -h'
alias top='htop'  # 如果安装了 htop

# 网络工具别名
alias myip='curl -s ifconfig.me'
alias ports='netstat -tuln'

# 快速导航
alias cdw='cd /var/www'
alias cdl='cd /var/log'
alias cdc='cd /etc'

# 安全操作提醒
alias rm='rm -I'
alias cp='cp -i'
alias mv='mv -i'

# 服务器信息
alias about='echo "系统: $(uname -s)" && echo "版本: $(uname -r)" && echo "架构: $(uname -m)" && echo "在线: $(uptime -p)"'

# 服务器特定配置
# Linux 服务器特定配置

# SSH 会话优化
if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    # 设置终端标题为 user@host:dir
    case "$TERM" in
        xterm*|rxvt*)
            PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
            ;;
    esac
    
    # 防止 SSH 会话挂起
    export TMOUT=0
    
    # 服务器提示符优化
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# 服务器性能监控别名
alias ps='ps aux'
alias du='du -h'
alias df='df -h'
alias top='htop'  # 如果安装了 htop

# 网络工具别名
alias myip='curl -s ifconfig.me'
alias ports='netstat -tuln'

# 快速导航
alias cdw='cd /var/www'
alias cdl='cd /var/log'
alias cdc='cd /etc'

# 安全操作提醒
alias rm='rm -I'
alias cp='cp -i'
alias mv='mv -i'

# 服务器信息
alias about='echo "系统: $(uname -s)" && echo "版本: $(uname -r)" && echo "架构: $(uname -m)" && echo "在线: $(uptime -p)"'

# 服务器特定配置
# Linux 服务器特定配置

# SSH 会话优化
if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    # 设置终端标题为 user@host:dir
    case "$TERM" in
        xterm*|rxvt*)
            PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
            ;;
    esac
    
    # 防止 SSH 会话挂起
    export TMOUT=0
    
    # 服务器提示符优化
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# 服务器性能监控别名
alias ps='ps aux'
alias du='du -h'
alias df='df -h'
alias top='htop'  # 如果安装了 htop

# 网络工具别名
alias myip='curl -s ifconfig.me'
alias ports='netstat -tuln'

# 快速导航
alias cdw='cd /var/www'
alias cdl='cd /var/log'
alias cdc='cd /etc'

# 安全操作提醒
alias rm='rm -I'
alias cp='cp -i'
alias mv='mv -i'

# 服务器信息
alias about='echo "系统: $(uname -s)" && echo "版本: $(uname -r)" && echo "架构: $(uname -m)" && echo "在线: $(uptime -p)"'

# 服务器特定配置
# Linux 服务器特定配置

# SSH 会话优化
if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    # 设置终端标题为 user@host:dir
    case "$TERM" in
        xterm*|rxvt*)
            PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
            ;;
    esac
    
    # 防止 SSH 会话挂起
    export TMOUT=0
    
    # 服务器提示符优化
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# 服务器性能监控别名
alias ps='ps aux'
alias du='du -h'
alias df='df -h'
alias top='htop'  # 如果安装了 htop

# 网络工具别名
alias myip='curl -s ifconfig.me'
alias ports='netstat -tuln'

# 快速导航
alias cdw='cd /var/www'
alias cdl='cd /var/log'
alias cdc='cd /etc'

# 安全操作提醒
alias rm='rm -I'
alias cp='cp -i'
alias mv='mv -i'

# 服务器信息
alias about='echo "系统: $(uname -s)" && echo "版本: $(uname -r)" && echo "架构: $(uname -m)" && echo "在线: $(uptime -p)"'
