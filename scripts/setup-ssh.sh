#!/usr/bin/env bash
# z-codespace/scripts/setup-ssh.sh — SSH key bootstrap
# ============================================================

set -euo pipefail

KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_ed25519}"
KEY_TYPE="${SSH_KEY_TYPE:-ed25519}"
KEY_COMMENT="${SSH_KEY_COMMENT:-}"
KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"

log_info() { printf '\033[0;32m[INFO]\033[0m  %s\n' "$*"; }
log_warn() { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
log_ok() { printf '\033[0;32m[ OK ]\033[0m  %s\n' "$*"; }

detect_comment() {
    if [ -n "$KEY_COMMENT" ]; then
        printf '%s\n' "$KEY_COMMENT"
        return 0
    fi

    if command -v git >/dev/null 2>&1; then
        local email
        email="$(git config --global user.email 2>/dev/null || true)"
        if [ -n "$email" ]; then
            printf '%s\n' "$email"
            return 0
        fi
    fi

    local host
    host="$(hostname -s 2>/dev/null || hostname 2>/dev/null || printf 'localhost')"
    printf '%s@%s\n' "${USER:-user}" "$host"
}

find_existing_key() {
    local key
    for key in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa"; do
        if [ -f "$key" ] && [ -f "$key.pub" ]; then
            printf '%s\n' "$key"
            return 0
        fi
    done
    return 1
}

ensure_ssh_dir() {
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
}

generate_key() {
    local comment="$1"

    if [ -f "$KEY_FILE" ] && [ ! -f "$KEY_FILE.pub" ]; then
        log_warn "检测到私钥但缺少公钥，重新导出: $KEY_FILE.pub"
        ssh-keygen -y -f "$KEY_FILE" > "$KEY_FILE.pub"
        chmod 644 "$KEY_FILE.pub"
        return 0
    fi

    if [ -e "$KEY_FILE" ] || [ -e "$KEY_FILE.pub" ]; then
        log_warn "目标 key 已存在，跳过生成: $KEY_FILE"
        return 0
    fi

    log_info "生成 SSH key: $KEY_FILE ($KEY_TYPE)"
    ssh-keygen -t "$KEY_TYPE" -C "$comment" -f "$KEY_FILE" -N ""
    chmod 600 "$KEY_FILE"
    chmod 644 "$KEY_FILE.pub"
    log_ok "SSH key 已生成: $KEY_FILE.pub"
}

ensure_github_known_host() {
    if ! command -v ssh-keyscan >/dev/null 2>&1; then
        log_warn "未找到 ssh-keyscan，跳过 GitHub known_hosts 初始化"
        return 0
    fi

    touch "$KNOWN_HOSTS_FILE"
    chmod 600 "$KNOWN_HOSTS_FILE"

    if ssh-keygen -F github.com -f "$KNOWN_HOSTS_FILE" >/dev/null 2>&1; then
        log_ok "GitHub known_hosts 已存在"
        return 0
    fi

    log_info "添加 GitHub host key 到 known_hosts"
    if ssh-keyscan -T 5 github.com >> "$KNOWN_HOSTS_FILE" 2>/dev/null; then
        log_ok "GitHub known_hosts 已更新"
    else
        log_warn "无法连接 github.com，跳过 known_hosts 初始化"
    fi
}

print_next_step() {
    local key="$1"
    if [ ! -f "$key.pub" ]; then
        log_warn "未找到公钥文件: $key.pub"
        return 0
    fi

    echo ""
    log_info "GitHub SSH 公钥如下，请添加到 GitHub: Settings -> SSH and GPG keys"
    sed 's/^/  /' "$key.pub"
}

main() {
    if ! command -v ssh-keygen >/dev/null 2>&1; then
        log_warn "未找到 ssh-keygen，请先安装 OpenSSH"
        return 0
    fi

    ensure_ssh_dir

    local key
    if key="$(find_existing_key)"; then
        log_ok "检测到已有 SSH key: $key"
    else
        key="$KEY_FILE"
        generate_key "$(detect_comment)"
    fi

    ensure_github_known_host
    print_next_step "$key"
}

main "$@"
