# ai-cli.sh - Claude Code / Codex / Grok CLI 安装管理函数
# 由 configs/common/.bashrc 的 BASH_DIR loader 自动 source
# 依赖：bashrc 已 export AI_NPM_PREFIX
# 用户面：icc/ucc (Claude Code 装/卸) / icx/ucx (Codex 装/卸) / igk/ugk (Grok 装/卸) / cc / cx / gk
# 第三方中转：交给 CC Switch (macOS) / cc-switch-cli (headless) 管理，见
#   scripts/install-ai-switcher.sh；本文件 launcher 保持裸调，读取切换器写入的原生 config
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

_install_grok() {
    _ai_fetch "https://x.ai/cli/install.sh" | bash
    hash -r

    if command -v grok >/dev/null 2>&1; then
        printf '%s\n' "grok 安装完成: $(command -v grok)"
        grok --version 2>/dev/null || true
        return 0
    fi

    printf '%s\n' "grok 已安装，但当前 shell 尚未在 PATH 中找到它。" >&2
    printf '%s\n' "请重启终端，或执行: export PATH=\"\$HOME/.grok/bin:\$PATH\"" >&2
    return 1
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

_remove_grok_path_link() {
    local link_path="$1"
    local target=""

    [ -L "$link_path" ] || return 0
    target="$(readlink "$link_path" 2>/dev/null || true)"

    case "$target" in
        "$HOME/.grok/bin/"*|"$HOME/.grok/bin/grok"|"$HOME/.grok/bin/agent")
            rm -f "$link_path"
            ;;
    esac
}

_uninstall_grok() {
    local removed=0

    for name in grok agent; do
        if [ -e "$HOME/.grok/bin/$name" ] || [ -L "$HOME/.grok/bin/$name" ]; then
            rm -f "$HOME/.grok/bin/$name"
            removed=1
        fi

        _remove_grok_path_link "$HOME/.local/bin/$name"
        _remove_grok_path_link "/usr/local/bin/$name"
    done

    hash -r
    if command -v grok >/dev/null 2>&1; then
        printf '%s\n' "grok 仍存在：$(command -v grok)"
        return 1
    fi

    if [ "$removed" -eq 1 ]; then
        printf '%s\n' "grok 已卸载。保留 ~/.grok/auth.json、config.toml 和 downloads。"
    else
        printf '%s\n' "grok 未安装。"
    fi
}

_claude_run() {
    command claude "$@"
}

_codex_run() {
    command codex "$@"
}

_grok_run() {
    command grok "$@"
}

icc() {
    _install_claude_code
}

icx() {
    _install_codex
}

igk() {
    _install_grok
}

ucc() {
    _uninstall_claude_code
}

ucx() {
    _uninstall_codex
}

ugk() {
    _uninstall_grok
}

cc() {
    _claude_run "$@"
}

ccf() {
    _claude_run --permission-mode acceptEdits "$@"
}

ccy() {
    IS_SANDBOX=1 _claude_run --dangerously-skip-permissions "$@"
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

gk() {
    _grok_run "$@"
}
