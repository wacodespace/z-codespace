#!/usr/bin/env bash
# z-codespace/scripts/install-claude-gateway.sh - write Claude gateway secrets to ~/.bash_private
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib.sh"

PRIVATE_FILE="${BASH_PRIVATE_FILE:-$HOME/.bash_private}"
BEGIN_MARKER="# >>> claude gateway >>>"
END_MARKER="# <<< claude gateway <<<"

shell_quote() {
    local value="$1"
    printf "'%s'" "$(printf '%s' "$value" | sed "s/'/'\\\\''/g")"
}

remove_existing_block() {
    local src="$1"
    local dst="$2"

    if [ ! -f "$src" ]; then
        : > "$dst"
        return 0
    fi

    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
        $0 == begin { skip = 1; next }
        $0 == end { skip = 0; next }
        skip != 1 { print }
    ' "$src" > "$dst"
}

main() {
    local base_url=""
    local api_key=""
    local model=""
    local tmp=""

    log_step "配置 Claude 第三方中转"
    printf '中转 Base URL: '
    IFS= read -r base_url
    if [ -z "$base_url" ]; then
        log_error "Base URL 不能为空"
        return 1
    fi

    printf 'API Key（输入时不回显）: '
    IFS= read -r -s api_key
    printf '\n'
    if [ -z "$api_key" ]; then
        log_error "API Key 不能为空"
        return 1
    fi

    printf '默认模型（可选，留空则使用 Claude 默认模型）: '
    IFS= read -r model

    mkdir -p "$(dirname "$PRIVATE_FILE")"
    tmp="$(mktemp)"
    remove_existing_block "$PRIVATE_FILE" "$tmp"

    {
        printf '\n%s\n' "$BEGIN_MARKER"
        printf '# Used by z-codespace ccg/ccgf/ccgp/ccgy wrappers. Secrets stay outside git.\n'
        printf 'export CLAUDE_GATEWAY_BASE_URL=%s\n' "$(shell_quote "$base_url")"
        printf 'export CLAUDE_GATEWAY_API_KEY=%s\n' "$(shell_quote "$api_key")"
        if [ -n "$model" ]; then
            printf 'export CLAUDE_GATEWAY_MODEL=%s\n' "$(shell_quote "$model")"
        else
            printf '# export CLAUDE_GATEWAY_MODEL="claude-sonnet-4-5"\n'
        fi
        printf '%s\n' "$END_MARKER"
    } >> "$tmp"

    install -m 600 "$tmp" "$PRIVATE_FILE"
    rm -f "$tmp"

    log_ok "已写入 $PRIVATE_FILE"
    log_info "重新打开 shell，或运行: source ~/.bash_private"
    log_info "检查状态: ccgw"
}

main "$@"
