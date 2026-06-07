# ai-cli.sh - Claude Code / Codex CLI 安装管理函数
# 由 configs/common/.bashrc 的 BASH_DIR loader 自动 source
# 依赖：bashrc 已 export AI_NPM_PREFIX
# 用户面：icc/ucc (Claude Code 装/卸) / icx/ucx (Codex 装/卸) / cc / cx
# ============================================================

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

_ai_ensure_npm_prefix() {
    mkdir -p "$AI_NPM_PREFIX/bin"
    case ":$PATH:" in
        *":$AI_NPM_PREFIX/bin:"*) ;;
        *)
            printf '%s\n' "提示: $AI_NPM_PREFIX/bin 不在 PATH 中，当前 shell 可能找不到刚安装的命令。" >&2
            ;;
    esac
}

_ai_known_npm_prefixes() {
    local prefix=""

    printf '%s\n' "$AI_NPM_PREFIX"

    if command -v npm >/dev/null 2>&1; then
        prefix="$(npm config get prefix 2>/dev/null || true)"
        [ -n "$prefix" ] && [ "$prefix" != "undefined" ] && printf '%s\n' "$prefix"
    fi

    [ -d /opt/homebrew ] && printf '%s\n' /opt/homebrew
    [ -d /usr/local ] && printf '%s\n' /usr/local

    if [ -n "${NVM_DIR:-}" ] && [ -d "$NVM_DIR/versions/node" ]; then
        for prefix in "$NVM_DIR"/versions/node/*; do
            [ -d "$prefix" ] && printf '%s\n' "$prefix"
        done
    fi
}

_ai_unique_known_npm_prefixes() {
    local prefix=""
    local seen=":"

    while IFS= read -r prefix; do
        [ -n "$prefix" ] || continue
        case "$seen" in
            *":$prefix:"*) ;;
            *)
                seen="${seen}${prefix}:"
                printf '%s\n' "$prefix"
                ;;
        esac
    done < <(_ai_known_npm_prefixes)
}

_ai_prefix_has_package() {
    local prefix="$1"
    local package_name="$2"

    [ -d "$prefix/lib/node_modules/$package_name" ]
}

_ai_uninstall_from_prefix() {
    local prefix="$1"
    local package_name="$2"

    if ! _ai_prefix_has_package "$prefix" "$package_name"; then
        return 0
    fi

    printf '%s\n' "卸载重复安装: $package_name ($prefix)"
    npm uninstall -g --prefix "$prefix" "$package_name"
}

_ai_cleanup_duplicate_npm_package() {
    local package_name="$1"
    local keep_prefix="$2"
    local prefix=""
    local failed=0

    while IFS= read -r prefix; do
        [ -n "$prefix" ] || continue
        [ "$prefix" != "$keep_prefix" ] || continue
        if _ai_prefix_has_package "$prefix" "$package_name"; then
            _ai_uninstall_from_prefix "$prefix" "$package_name" || failed=1
        fi
    done < <(_ai_unique_known_npm_prefixes)

    return "$failed"
}

_ai_report_duplicate_npm_package() {
    local package_name="$1"
    local keep_prefix="$2"
    local prefix=""
    local found=0

    while IFS= read -r prefix; do
        [ -n "$prefix" ] || continue
        [ "$prefix" != "$keep_prefix" ] || continue
        if _ai_prefix_has_package "$prefix" "$package_name"; then
            if [ "$found" -eq 0 ]; then
                printf '%s\n' "检测到重复安装:"
                found=1
            fi
            printf '%s\n' "  $prefix/lib/node_modules/$package_name"
        fi
    done < <(_ai_unique_known_npm_prefixes)

    return "$found"
}

_ai_install_npm_global_managed() {
    local package_name="$1"
    local command_name="$2"

    _ai_ensure_node || return 1
    _ai_ensure_npm_prefix

    npm install -g --prefix "$AI_NPM_PREFIX" "$package_name" || return 1
    _ai_cleanup_duplicate_npm_package "$package_name" "$AI_NPM_PREFIX" || return 1
    hash -r

    if [ -x "$AI_NPM_PREFIX/bin/$command_name" ]; then
        printf '%s\n' "$command_name 安装完成: $AI_NPM_PREFIX/bin/$command_name"
        "$AI_NPM_PREFIX/bin/$command_name" --version 2>/dev/null || true
        return 0
    fi

    printf '%s\n' "$command_name 安装失败。" >&2
    return 1
}

_install_claude_code() {
    _ai_install_npm_global_managed "@anthropic-ai/claude-code" "claude"
}

_install_codex() {
    _ai_install_npm_global_managed "@openai/codex" "codex"
}

_uninstall_npm_global() {
    local package_name="$1"
    local command_name="$2"

    _ai_ensure_node || return 1
    _ai_uninstall_from_prefix "$AI_NPM_PREFIX" "$package_name" || return 1
    _ai_cleanup_duplicate_npm_package "$package_name" "$AI_NPM_PREFIX" || return 1
    hash -r
    if command -v "$command_name" >/dev/null 2>&1; then
        printf '%s\n' "$command_name 仍存在：$(command -v "$command_name")"
        _ai_report_duplicate_npm_package "$package_name" "$AI_NPM_PREFIX" || true
        return 1
    fi
    printf '%s\n' "$command_name 已卸载。"
}

_uninstall_claude_code() {
    _uninstall_npm_global "@anthropic-ai/claude-code" "claude"
}

_uninstall_codex() {
    if ! command -v codex >/dev/null 2>&1; then
        printf '%s\n' "codex 未安装。"
        return 0
    fi

    _uninstall_npm_global "@openai/codex" "codex"
}

_codex_toml_string() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '"%s"' "$value"
}

_codex_gateway_api_key() {
    printf '%s\n' "${CODEX_GATEWAY_API_KEY:-${OPENAI_API_KEY:-}}"
}

_claude_gateway_api_key() {
    printf '%s\n' "${CLAUDE_GATEWAY_API_KEY:-${ANTHROPIC_API_KEY:-}}"
}

_codex_gateway_enabled() {
    [ -n "${CODEX_GATEWAY_BASE_URL:-}" ] \
        && [ -n "$(_codex_gateway_api_key)" ]
}

_claude_gateway_enabled() {
    [ -n "${CLAUDE_GATEWAY_BASE_URL:-}" ] \
        && [ -n "$(_claude_gateway_api_key)" ]
}

_claude_gateway_run() {
    local api_key=""

    if ! _claude_gateway_enabled; then
        printf '%s\n' "Claude gateway 未配置。请设置 CLAUDE_GATEWAY_BASE_URL 和 CLAUDE_GATEWAY_API_KEY。" >&2
        printf '%s\n' "可运行: bash scripts/install-claude-gateway.sh && source ~/.bash_private" >&2
        return 1
    fi

    api_key="$(_claude_gateway_api_key)"
    if [ -n "${CLAUDE_GATEWAY_MODEL:-}" ]; then
        ANTHROPIC_BASE_URL="$CLAUDE_GATEWAY_BASE_URL" \
            ANTHROPIC_API_KEY="$api_key" \
            ANTHROPIC_MODEL="$CLAUDE_GATEWAY_MODEL" \
            command claude "$@"
        return
    fi

    ANTHROPIC_BASE_URL="$CLAUDE_GATEWAY_BASE_URL" \
        ANTHROPIC_API_KEY="$api_key" \
        command claude "$@"
}

_claude_subscription_run() {
    ANTHROPIC_API_KEY= ANTHROPIC_BASE_URL= ANTHROPIC_MODEL= command claude "$@"
}

_claude_run() {
    case "${CLAUDE_USE_GATEWAY:-0}" in
        1|true|yes|on)
            _claude_gateway_run "$@"
            return
            ;;
    esac

    _claude_subscription_run "$@"
}

_claude_gateway_status() {
    if _claude_gateway_enabled; then
        printf '%s\n' "Claude gateway: configured"
        printf '%s\n' "  default: subscription via cc/ccf/ccp/ccy"
        printf '%s\n' "  gateway: ccg/ccgf/ccgp/ccgy"
        printf '%s\n' "  base_url: $CLAUDE_GATEWAY_BASE_URL"
        [ -n "${CLAUDE_GATEWAY_MODEL:-}" ] && printf '%s\n' "  model: $CLAUDE_GATEWAY_MODEL"
        return
    fi

    printf '%s\n' "Claude gateway: not configured"
    printf '%s\n' "  default: subscription via cc/ccf/ccp/ccy"
    printf '%s\n' "  set CLAUDE_GATEWAY_BASE_URL and CLAUDE_GATEWAY_API_KEY in ~/.bash_private"
}

_codex_gateway_run() {
    local api_key=""
    local -a codex_args=()

    if ! _codex_gateway_enabled; then
        printf '%s\n' "Codex gateway 未配置。请设置 CODEX_GATEWAY_BASE_URL 和 CODEX_GATEWAY_API_KEY。" >&2
        printf '%s\n' "可运行: bash scripts/install-codex-gateway.sh && source ~/.bash_private" >&2
        return 1
    fi

    api_key="$(_codex_gateway_api_key)"
    codex_args+=("-c" "model_provider=openai")
    codex_args+=("-c" "openai_base_url=$(_codex_toml_string "$CODEX_GATEWAY_BASE_URL")")

    if [ -n "${CODEX_GATEWAY_MODEL:-}" ]; then
        codex_args+=("-m" "$CODEX_GATEWAY_MODEL")
    fi

    OPENAI_API_KEY="$api_key" command codex "${codex_args[@]}" "$@"
}

_codex_subscription_run() {
    OPENAI_API_KEY= command codex "$@"
}

_codex_run() {
    case "${CODEX_USE_GATEWAY:-0}" in
        1|true|yes|on)
            _codex_gateway_run "$@"
            return
            ;;
    esac

    _codex_subscription_run "$@"
}

_codex_gateway_status() {
    if _codex_gateway_enabled; then
        printf '%s\n' "Codex gateway: configured"
        printf '%s\n' "  default: subscription via cx/cxf/cxy"
        printf '%s\n' "  gateway: cxg/cxgf/cxgy"
        printf '%s\n' "  base_url: $CODEX_GATEWAY_BASE_URL"
        [ -n "${CODEX_GATEWAY_MODEL:-}" ] && printf '%s\n' "  model: $CODEX_GATEWAY_MODEL"
        return
    fi

    printf '%s\n' "Codex gateway: not configured"
    printf '%s\n' "  default: subscription via cx/cxf/cxy"
    printf '%s\n' "  set CODEX_GATEWAY_BASE_URL and CODEX_GATEWAY_API_KEY in ~/.bash_private"
}

cxgw() {
    _codex_gateway_status
}

ccgw() {
    _claude_gateway_status
}

icc() {
    _install_claude_code
}

icx() {
    _install_codex
}

ucc() {
    _uninstall_claude_code
}

ucx() {
    _uninstall_codex
}

cc() {
    _claude_run "$@"
}

ccf() {
    _claude_run --permission-mode acceptEdits "$@"
}

ccp() {
    IS_SANDBOX=1 _claude_run --permission-mode plan --allow-dangerously-skip-permissions "$@"
}

ccy() {
    IS_SANDBOX=1 _claude_run --dangerously-skip-permissions "$@"
}

ccg() {
    _claude_gateway_run "$@"
}

ccgf() {
    _claude_gateway_run --permission-mode acceptEdits "$@"
}

ccgp() {
    IS_SANDBOX=1 _claude_gateway_run --permission-mode plan --allow-dangerously-skip-permissions "$@"
}

ccgy() {
    IS_SANDBOX=1 _claude_gateway_run --dangerously-skip-permissions "$@"
}

cx() {
    _codex_run "$@"
}

cxf() {
    _codex_run -a never -s workspace-write "$@"
}

cxy() {
    _codex_run --dangerously-bypass-approvals-and-sandbox "$@"
}

cxg() {
    _codex_gateway_run "$@"
}

cxgf() {
    _codex_gateway_run -a never -s workspace-write "$@"
}

cxgy() {
    _codex_gateway_run --dangerously-bypass-approvals-and-sandbox "$@"
}
