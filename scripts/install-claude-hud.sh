#!/usr/bin/env bash
# z-codespace/scripts/install-claude-hud.sh — 安装 Claude HUD 状态栏插件
# 项目: https://github.com/jarrodwatts/claude-hud  (MIT)
# ============================================================
#
# Claude HUD 在 Claude Code 终端中实时显示:
#   · Context 使用量 (颜色编码: 绿/黄/红)
#   · 当前执行的工具
#   · 子 Agent 运行状态
#   · Todo 任务进度
#
# 安装原理:
#   1. git clone jarrodwatts/claude-hud → ~/.claude/plugins/cache/claude-hud/
#   2. npm install + npm run build (编译 TypeScript → dist/)
#   3. 在 ~/.claude/settings.json 写入 statusLine 命令
#      命令通过 stty size </dev/tty 读取终端宽度，无需 TTY stdin
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"
PLUGIN_DIR="$CLAUDE_CONFIG_DIR/plugins/cache/claude-hud"
DIST_ENTRY="$PLUGIN_DIR/dist/index.js"
REPO_URL="https://github.com/jarrodwatts/claude-hud.git"

# --- 确保 Node.js / npm 可用 ---
ensure_node() {
    if has_cmd node && has_cmd npm; then
        log_ok "Node.js $(node --version), npm $(npm --version)"
        return 0
    fi

    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck disable=SC1091
        . "$NVM_DIR/nvm.sh"
        if has_cmd node && has_cmd npm; then
            log_ok "通过 nvm 加载 Node.js $(node --version)"
            return 0
        fi
    fi

    log_error "未找到 Node.js / npm，Claude HUD 需要 npm 进行编译"
    log_error "请先运行: bash scripts/install-deps.sh"
    return 1
}

# --- clone 或更新插件源码 ---
clone_or_update() {
    mkdir -p "$CLAUDE_CONFIG_DIR/plugins/cache"

    if [ -d "$PLUGIN_DIR/.git" ]; then
        log_step "更新 claude-hud 插件源码..."
        git -C "$PLUGIN_DIR" pull --ff-only --quiet
        log_ok "源码已更新"
    else
        # 若目录存在但不是 git repo（残留），先清理
        if [ -d "$PLUGIN_DIR" ]; then
            log_warn "发现残留目录，清理后重新 clone: $PLUGIN_DIR"
            rm -rf "$PLUGIN_DIR"
        fi
        log_step "克隆 jarrodwatts/claude-hud..."
        git clone --depth=1 "$REPO_URL" "$PLUGIN_DIR"
        log_ok "克隆完成: $PLUGIN_DIR"
    fi
}

# --- 安装依赖并编译 ---
build_plugin() {
    log_step "安装依赖并编译 TypeScript..."
    (
        cd "$PLUGIN_DIR"
        npm install --silent
        npm run build --silent
    )

    if [ ! -f "$DIST_ENTRY" ]; then
        log_error "编译失败，未找到: $DIST_ENTRY"
        return 1
    fi
    log_ok "编译完成: $DIST_ENTRY"
}

# --- 生成 statusLine 命令字符串 ---
make_statusline_cmd() {
    # 用 stty size </dev/tty 读取实际终端列数（绕过 Claude Code 的非 TTY stdin）
    # -4 对应 Claude Code 输入区左侧留白
    # 优先用 bun（更快启动），否则 node
    local runtime
    if has_cmd bun; then
        runtime="bun --env-file /dev/null"
    else
        runtime="node"
    fi

    printf 'COLUMNS=$(( $(stty size </dev/tty 2>/dev/null | awk '"'"'{print $2}'"'"' || echo 80) - 4 )) %s %s' \
        "$runtime" "$DIST_ENTRY"
}

# --- 更新 ~/.claude/settings.json ---
update_settings() {
    log_step "配置 Claude Code statusLine..."

    mkdir -p "$CLAUDE_CONFIG_DIR"

    if [ ! -f "$SETTINGS_FILE" ]; then
        printf '{}\n' > "$SETTINGS_FILE"
        log_info "创建 $SETTINGS_FILE"
    fi

    # 检查是否已有 statusLine
    local already_set
    already_set=$(python3 -c "
import json
try:
    with open('$SETTINGS_FILE') as f:
        s = json.load(f)
    print('true' if 'statusLine' in s else 'false')
except Exception:
    print('false')
" 2>/dev/null || echo "false")

    if [ "$already_set" = "true" ]; then
        log_ok "statusLine 已配置，跳过"
        log_info "如需重置: 删除 $SETTINGS_FILE 中的 statusLine 字段后重新运行本脚本"
        return 0
    fi

    local cmd
    cmd="$(make_statusline_cmd)"

    python3 -c "
import json
with open('$SETTINGS_FILE', 'r') as f:
    settings = json.load(f)
settings['statusLine'] = {'type': 'command', 'command': '''$cmd'''}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
"
    log_ok "statusLine 已写入: $SETTINGS_FILE"
    log_info "命令: $cmd"
}

# --- 冒烟测试：确认 dist/index.js 可正常输出 ---
smoke_test() {
    log_step "冒烟测试 statusLine 输出..."

    local test_input='{"type":"system","subtype":"init","session_id":"test","tools":[],"mcp_servers":[],"model":"claude-sonnet-4-6","permissionMode":"default","apiKeySource":"unknown"}'

    local output
    output=$(echo "$test_input" | COLUMNS=76 node "$DIST_ENTRY" 2>&1 || true)

    if [ -z "$output" ]; then
        log_warn "statusLine 输出为空（可能需要实际 Claude Code 会话数据才能渲染）"
    else
        log_ok "statusLine 可正常运行"
        log_info "示例输出（截取前两行）:"
        echo "$output" | head -2 | sed 's/^/    /'
    fi
}

# --- 主流程 ---
main() {
    log_step "=========================================="
    log_step "Claude HUD 状态栏插件安装"
    log_step "https://github.com/jarrodwatts/claude-hud"
    log_step "=========================================="
    echo ""

    ensure_node
    echo ""

    clone_or_update
    echo ""

    build_plugin
    echo ""

    update_settings
    echo ""

    smoke_test
    echo ""

    log_ok "=========================================="
    log_ok "Claude HUD 安装完成！"
    log_ok "=========================================="
    echo ""
    log_info "重新启动 Claude Code 后状态栏将显示:"
    log_info "  · Context 用量 (绿色 < 70% / 黄色 < 85% / 红色 >= 85%)"
    log_info "  · 当前执行的工具"
    log_info "  · 子 Agent 运行状态"
    log_info "  · Todo 任务进度"
    echo ""
    log_info "插件目录: $PLUGIN_DIR"
    log_info "配置文件: $SETTINGS_FILE"
    log_info "插件文档: https://github.com/jarrodwatts/claude-hud"
}

main "$@"
