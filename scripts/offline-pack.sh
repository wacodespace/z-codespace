#!/usr/bin/env bash
# z-codespace/scripts/offline-pack.sh — 在有网机器上创建离线部署包
# ============================================================
#
# 用法: bash scripts/offline-pack.sh [输出路径]
#
# 打包内容:
#   1. configs/nvim/          — LazyVim 配置（含 lazy-lock.json）
#   2. ~/.local/share/nvim/   — lazy 插件 + treesitter parsers + mason 工具
#   3. ~/.local/state/nvim/   — lazy state
#   4. deploy.sh              — 目标机器部署脚本
#   5. MANIFEST.txt           — 包元信息
#
# 不打包内容（不建议同步）:
#   - ~/.cache/nvim           — 临时缓存，可重建
#   - ~/.local/share/nvim/swap — swap 文件
#
# 注意:
#   - treesitter parser (.so) 是平台相关的，不能跨平台迁移
#   - 确保源机器和目标机器架构一致 (x86_64/arm64)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT_ROOT="$(get_project_root)"

OUTPUT="${1:-$HOME/nvim-offline-$(detect_os)-$(detect_arch)-$(date +%Y%m%d).tar.gz}"

main() {
    log_step "=========================================="
    log_step "创建离线部署包"
    log_step "=========================================="
    echo ""

    # 前置检查
    if [ ! -d "$HOME/.local/share/nvim/lazy" ]; then
        log_error "插件目录不存在: ~/.local/share/nvim/lazy"
        log_error "请先在有网环境运行 'bash scripts/install-nvim.sh' 完成初始化"
        exit 1
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    local bundle="$tmpdir/nvim-bundle"
    mkdir -p "$bundle"

    # 1. 配置文件
    log_info "复制 nvim 配置..."
    cp -r "$PROJECT_ROOT/configs/nvim" "$bundle/nvim-config"

    # 2. 插件数据（最大的部分）
    log_info "复制插件数据 (~/.local/share/nvim)..."
    # 排除不需要的内容
    rsync -a --exclude='swap' --exclude='shada' \
        "$HOME/.local/share/nvim/" "$bundle/share-nvim/" 2>/dev/null \
        || cp -r "$HOME/.local/share/nvim" "$bundle/share-nvim"

    # 3. 状态数据
    if [ -d "$HOME/.local/state/nvim" ]; then
        log_info "复制状态数据 (~/.local/state/nvim)..."
        cp -r "$HOME/.local/state/nvim" "$bundle/state-nvim"
    fi

    # 4. 部署脚本
    log_info "嵌入部署脚本..."
    cp "$SCRIPT_DIR/offline-deploy.sh" "$bundle/deploy.sh"
    chmod +x "$bundle/deploy.sh"

    # 5. 元信息
    cat > "$bundle/MANIFEST.txt" <<EOF
nvim-offline-bundle
===================================
创建时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
创建主机: $(hostname)
操作系统: $(detect_os) $(detect_arch)
Neovim:   $(nvim --version 2>/dev/null | head -n1 || echo "未安装")
Node.js:  $(node --version 2>/dev/null || echo "未安装")
Python:   $(python3 --version 2>/dev/null || echo "未安装")
===================================
插件数量: $(find "$HOME/.local/share/nvim/lazy" -maxdepth 1 -type d 2>/dev/null | wc -l) 个目录
Parsers:  $(find "$HOME/.local/share/nvim/lazy/nvim-treesitter/parser" -name "*.so" 2>/dev/null | wc -l) 个
Mason:    $(find "$HOME/.local/share/nvim/mason/bin" -type f -o -type l 2>/dev/null | wc -l) 个工具
===================================
注意: .so 文件为平台相关，目标机器需与本机架构一致
EOF

    # 6. 打包
    log_info "打包中..."
    tar czf "$OUTPUT" -C "$tmpdir" "nvim-bundle"
    rm -rf "$tmpdir"

    # 输出大小
    local size
    if [[ "$(detect_os)" == "macos" ]]; then
        size=$(stat -f%z "$OUTPUT" 2>/dev/null || echo "0")
    else
        size=$(stat -c%s "$OUTPUT" 2>/dev/null || echo "0")
    fi
    local size_mb=$(( size / 1024 / 1024 ))

    echo ""
    log_ok "离线包创建完成"
    log_ok "文件: $OUTPUT"
    log_ok "大小: ${size_mb} MB"
    echo ""
    log_info "部署步骤:"
    log_info "  1. scp $(basename "$OUTPUT") user@server:/tmp/"
    log_info "  2. cd /tmp && tar xzf $(basename "$OUTPUT")"
    log_info "  3. bash /tmp/nvim-bundle/deploy.sh"
    log_info ""
    log_info "前提: 目标机器需已安装 nvim、gcc、git"
    log_info "      可通过 scripts/install-deps.sh 安装"
}

main "$@"
