#!/usr/bin/env bash
# z-codespace/install.sh — 冷启动第一层：软链 configs / skills + Git + SSH
# 不调用包管理器，不下载软件（setup-ssh.sh 仅做 ssh-keyscan 钉 GitHub host key）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

source "$SCRIPT_DIR/scripts/lib.sh"
source "$SCRIPT_DIR/scripts/profile-common.sh"
source "$SCRIPT_DIR/scripts/profile-desktop.sh"
source "$SCRIPT_DIR/scripts/profile-server.sh"

PROFILE=""
FORCE="false"
SKILLS_ONLY=false

detect_profile() {
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "macos-desktop"
    elif [ -n "${SSH_CLIENT:-}${SSH_TTY:-}" ]; then
        echo "ubuntu-server"
    else
        echo "ubuntu-desktop"
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --profile=*) PROFILE="${1#--profile=}"; shift ;;
        --profile)
            [[ $# -ge 2 ]] || { log_error "--profile 缺少参数"; exit 1; }
            PROFILE="$2"; shift 2 ;;
        --skills)    SKILLS_ONLY=true; shift ;;
        --force)     FORCE="true"; shift ;;
        -h|--help)
            cat <<'EOF'
用法: install.sh [选项]

选项:
  --profile=macos-desktop|ubuntu-desktop|ubuntu-server
  --profile <profile>   显式指定 profile（默认：macOS → macos-desktop，
                        Linux+SSH → ubuntu-server，其余 Linux → ubuntu-desktop）
  --skills              仅软链共享 Agent Skills（不改 Git / SSH）
  --force               强制覆盖，不备份
  -h, --help            显示此帮助
EOF
            exit 0
            ;;
        *) log_error "未知参数: $1"; exit 1 ;;
    esac
done

apply_profile() {
    case "$PROFILE" in
        macos-desktop)
            apply_common "$FORCE"
            apply_desktop_macos "$FORCE"
            ;;
        ubuntu-desktop)
            apply_common "$FORCE"
            apply_desktop_linux "$FORCE"
            ;;
        ubuntu-server)
            apply_common "$FORCE"
            apply_server "$FORCE"
            ;;
        *)
            log_error "不支持的 profile: $PROFILE（支持: macos-desktop, ubuntu-desktop, ubuntu-server）"
            exit 1
            ;;
    esac
}

setup_git_global_config() {
    if ! has_cmd git; then
        log_warn "git 未安装，跳过 git config 全局设置"
        return 0
    fi
    log_step "配置 Git 全局设置..."
    git config --global user.name "acodespace"
    git config --global user.email "7epimenides@gmail.com"
    git config --global core.quotepath false
    git config --global gui.encoding utf-8
    git config --global i18n.commitencoding utf-8
    git config --global i18n.logoutputencoding utf-8

    case "$PROFILE" in
        ubuntu-*)
            if ! git config --global --get "url.git@github.com:.insteadOf" >/dev/null 2>&1; then
                log_info "设置 Git HTTPS -> SSH 重写规则"
                git config --global "url.git@github.com:".insteadOf "https://github.com/"
            fi
            ;;
    esac
}

main() {
    if [ "$SKILLS_ONLY" = "true" ]; then
        apply_agent_skills "$FORCE"
        return 0
    fi

    if [ -z "$PROFILE" ]; then
        PROFILE="$(detect_profile)"
        log_info "自动检测 profile: $PROFILE"
    fi

    log_step "z-codespace 基础环境部署 | Profile: $PROFILE | 系统: $(detect_os) ($(detect_arch))"

    # 1. 软链 configs/（含 configs/nvim）
    apply_profile
    # 2. 软链 skills/
    apply_agent_skills "$FORCE"
    # 3. Git 全局配置
    setup_git_global_config
    # 4. SSH bootstrap
    log_step "检查 SSH key..."
    bash "$SCRIPT_DIR/scripts/setup-ssh.sh"

    log_ok "基础配置完成！"
    log_info "下一步: source ~/.bashrc && proxy && icc   # 或 icx / igk 拉起第一个 Agent"
    log_info "其余软件按 BOOTSTRAP.md 交由 Agent 安装"
}

main "$@"
