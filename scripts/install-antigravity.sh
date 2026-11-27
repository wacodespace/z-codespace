#!/usr/bin/env bash
# z-codespace/scripts/install-antigravity.sh — Antigravity App + Antigravity CLI
# ============================================================
#
#   Antigravity CLI (agy)  官方安装器 → ~/.local/bin/agy
#                          https://antigravity.google/cli/install.sh
#   Antigravity App        macOS: brew install --cask antigravity
#                          Linux: 官方最新 AppImage → ~/.local/opt/antigravity/
#                                 启动器 ~/.local/bin/antigravity
#
# 官方 CLI 安装器收尾会跑 `agy install`，给 ~/.bashrc / ~/.profile 追加 PATH。
# 本仓库的 ~/.bashrc 是软链接，不能让它改仓库文件。这里给 `agy install`
# 加上 --skip-path / --skip-aliases，并在跑完后还原指向本仓库的 shell rc。
# ~/.local/bin 已由 configs/common/.bashrc 放进 PATH。
#
# 用法:
#   bash scripts/install-antigravity.sh            # CLI + App
#   bash scripts/install-antigravity.sh cli
#   bash scripts/install-antigravity.sh app
#   bash scripts/install-antigravity.sh uninstall [cli|app|all]
#
# 终端里等价命令（bashrc 加载后）: iagy / uagy 、 iag / uag
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

ANTIGRAVITY_CLI_INSTALL_URL="https://antigravity.google/cli/install.sh"
# 与 Homebrew cask antigravity 的 livecheck 同一套 manifest。
ANTIGRAVITY_HUB_MANIFEST_BASE="https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/manifest"

APP_DIR="${HOME}/.local/opt/antigravity"
APP_IMAGE="${APP_DIR}/Antigravity.AppImage"
APP_LAUNCHER="${HOME}/.local/bin/antigravity"
APP_DESKTOP="${HOME}/.local/share/applications/antigravity.desktop"
APP_LAUNCHER_MARKER="z-codespace-antigravity-launcher"

usage() {
    cat <<'EOF'
用法: install-antigravity.sh [命令]

  all                 安装 Antigravity CLI 和 App（默认）
  cli                 只安装 Antigravity CLI (agy)
  app                 只安装 Antigravity App
  uninstall [all|cli|app]
                      卸载。保留登录数据（~/.gemini/antigravity-cli、~/.antigravity）
  -h, --help          显示此帮助
EOF
}

hint_proxy() {
    local retry_cmd="$1"
    if [ -z "${HTTPS_PROXY:-}${https_proxy:-}" ]; then
        log_warn "若当前网络访问不了 Google，先打开代理再试: proxy && ${retry_cmd}"
    fi
}

fetch_text() {
    local url="$1"
    if has_cmd curl; then
        curl -fsSL --connect-timeout 20 --retry 2 "$url"
    elif has_cmd wget; then
        wget -qO- --timeout=20 "$url"
    else
        log_error "需要 curl 或 wget"
        return 1
    fi
}

download_file() {
    local url="$1"
    local dest="$2"
    if has_cmd curl; then
        curl -fL --connect-timeout 20 --retry 3 --progress-bar -o "$dest" "$url"
    elif has_cmd wget; then
        wget -O "$dest" "$url"
    else
        log_error "需要 curl 或 wget"
        return 1
    fi
}

# --- 防止官方安装器改写仓库里的 shell 配置 ---
save_repo_rcs() {
    local stash="$1"
    local name target root key
    # pwd -P / readlink -f 都走物理路径。macOS 上 /var 是 /private/var 的软链接，
    # 不先规范化的话，仓库路径对不上，保护会漏掉。
    # 快照文件名去掉开头的点，否则 *.path 匹配不到 .bashrc.path。
    root="$(cd "$PROJECT_ROOT" && pwd -P)"
    mkdir -p "$stash"
    for name in .bashrc .bash_profile .zshrc .zprofile .profile; do
        [ -L "${HOME}/${name}" ] || continue
        target="$(readlink -f "${HOME}/${name}" 2>/dev/null || true)"
        [ -n "$target" ] && [ -f "$target" ] || continue
        case "$target" in
            "${root}/"*)
                key="${name#.}"
                cp -p "$target" "${stash}/${key}"
                printf '%s\n' "$target" > "${stash}/${key}.path"
                ;;
        esac
    done
}

restore_repo_rcs() {
    local stash="$1"
    local pathfile name target
    for pathfile in "${stash}/"*.path; do
        [ -f "$pathfile" ] || continue
        name="$(basename "$pathfile" .path)"
        target="$(cat "$pathfile")"
        if [ -f "${stash}/${name}" ] && [ -f "$target" ] && ! cmp -s "${stash}/${name}" "$target"; then
            cp -p "${stash}/${name}" "$target"
            log_warn "官方安装器改写了 .${name}（指向本仓库）。已还原。"
            log_warn "~/.local/bin 已在 bashrc 的 PATH 中，无需它再写一遍。"
        fi
    done
}

# 当前 install.sh 不转发 --skip-path。补到 agy install 上，失败也不阻断装二进制。
patch_cli_installer() {
    local src="$1"
    local dst="$2"
    awk '
        {
            if ($0 ~ /"\$BINARY_PATH" install/ && $0 !~ /--skip-path/) {
                sub(/install/, "install --skip-path --skip-aliases")
            }
            print
        }
    ' "$src" > "$dst"
}

install_cli() {
    local agy="${HOME}/.local/bin/agy"
    local work installer patched stash

    if [ -x "$agy" ] || has_cmd agy; then
        if [ -x "$agy" ]; then
            log_ok "Antigravity CLI 已安装: ${agy}"
            "$agy" --version 2>/dev/null || true
        else
            log_ok "Antigravity CLI 已安装: $(command -v agy)"
            agy --version 2>/dev/null || true
        fi
        return 0
    fi

    if ! has_cmd curl && ! has_cmd wget; then
        log_error "需要 curl 或 wget 才能安装 Antigravity CLI"
        return 1
    fi

    work="$(mktemp -d)"
    installer="${work}/install.sh"
    patched="${work}/install.patched.sh"
    stash="${work}/rcs"

    log_step "下载 Antigravity CLI 安装脚本..."
    if ! fetch_text "$ANTIGRAVITY_CLI_INSTALL_URL" > "$installer" || [ ! -s "$installer" ]; then
        rm -rf "$work"
        log_error "Antigravity CLI 安装脚本下载失败。"
        hint_proxy "iagy"
        log_info "手动: curl -fsSL ${ANTIGRAVITY_CLI_INSTALL_URL} -o /tmp/agy-install.sh && bash /tmp/agy-install.sh"
        return 1
    fi
    if ! grep -q "Antigravity CLI" "$installer"; then
        rm -rf "$work"
        log_error "下载到的内容不是 Antigravity CLI 安装脚本。"
        return 1
    fi

    patch_cli_installer "$installer" "$patched"
    if ! grep -q -- "--skip-path" "$patched"; then
        log_warn "安装脚本里没有找到 agy install 交接，装完后会检查 shell rc 是否被改写。"
        cp "$installer" "$patched"
    fi

    save_repo_rcs "$stash"
    log_step "安装 Antigravity CLI → ~/.local/bin/agy ..."
    if ! bash "$patched"; then
        restore_repo_rcs "$stash"
        rm -rf "$work"
        log_error "Antigravity CLI 安装失败。"
        hint_proxy "iagy"
        return 1
    fi
    restore_repo_rcs "$stash"
    rm -rf "$work"
    hash -r || true

    if [ -x "$agy" ]; then
        log_ok "Antigravity CLI 安装完成: ${agy}"
        "$agy" --version 2>/dev/null || true
        return 0
    fi
    if has_cmd agy; then
        log_ok "Antigravity CLI 安装完成: $(command -v agy)"
        agy --version 2>/dev/null || true
        return 0
    fi

    log_error "安装脚本执行完，但未找到 agy。"
    return 1
}

uninstall_cli() {
    local removed=0

    if has_cmd brew && brew list --cask antigravity-cli >/dev/null 2>&1; then
        log_step "卸载 Homebrew cask antigravity-cli..."
        brew uninstall --cask antigravity-cli
        removed=1
    fi

    if [ -e "${HOME}/.local/bin/agy" ] || [ -L "${HOME}/.local/bin/agy" ]; then
        rm -f "${HOME}/.local/bin/agy"
        removed=1
    fi

    hash -r || true
    if has_cmd agy; then
        log_error "agy 仍存在: $(command -v agy)"
        return 1
    fi
    if [ "$removed" -eq 1 ]; then
        log_ok "Antigravity CLI 已卸载。保留 ~/.gemini/antigravity-cli。"
    else
        log_info "Antigravity CLI 未安装。"
    fi
}

linux_manifest_name() {
    case "$(uname -m)" in
        x86_64|amd64) printf '%s\n' "latest-x64-linux.yml" ;;
        aarch64|arm64) printf '%s\n' "latest-arm64-linux-arm64.yml" ;;
        *)
            log_error "不支持的架构: $(uname -m)"
            return 1
            ;;
    esac
}

# stdin: electron-builder manifest。stdout: AppImage URL 和它的 sha512（两行）。
parse_appimage_manifest() {
    awk '
        $1 == "-" && $2 == "url:" && $3 ~ /Antigravity\.AppImage$/ { url = $3; capture = 1; next }
        capture && $1 == "sha512:" { print url; print $2; exit }
    '
}

sha512_b64_to_hex() {
    local b64="$1"
    if [ "$(uname -s)" = "Darwin" ]; then
        printf '%s' "$b64" | base64 -D | od -An -tx1 | tr -d '[:space:]'
    else
        printf '%s' "$b64" | base64 -d | od -An -tx1 | tr -d '[:space:]'
    fi
}

file_sha512() {
    if has_cmd sha512sum; then
        sha512sum "$1" | awk '{print $1}'
    else
        shasum -a 512 "$1" | awk '{print $1}'
    fi
}

write_app_launcher() {
    mkdir -p "${HOME}/.local/bin" "${HOME}/.local/share/applications"
    cat > "$APP_LAUNCHER" <<EOF
#!/bin/sh
# ${APP_LAUNCHER_MARKER}
exec "${APP_IMAGE}" "\$@"
EOF
    chmod 755 "$APP_LAUNCHER"

    cat > "$APP_DESKTOP" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Antigravity
Comment=Google Antigravity
Exec="${APP_LAUNCHER}" %U
Terminal=false
Categories=Development;
EOF
}

install_app_macos() {
    if ! has_cmd brew; then
        log_error "未找到 Homebrew，无法安装 Antigravity App。"
        log_info "先装 Homebrew，或运行: bash install.sh --desktop"
        return 1
    fi

    if brew list --cask antigravity >/dev/null 2>&1 || [ -d "/Applications/Antigravity.app" ]; then
        log_ok "Antigravity App 已安装: /Applications/Antigravity.app"
        return 0
    fi

    log_step "安装 Antigravity App (brew install --cask antigravity)..."
    if ! brew install --cask antigravity; then
        log_error "Antigravity App 安装失败。"
        hint_proxy "iag"
        log_info "手动: brew install --cask antigravity"
        return 1
    fi
    log_ok "Antigravity App 已安装: /Applications/Antigravity.app"
}

install_app_linux() {
    local manifest_name manifest parsed url sha version work payload expected actual

    if [ -x "$APP_IMAGE" ] && [ -x "$APP_LAUNCHER" ]; then
        log_ok "Antigravity App 已安装: ${APP_LAUNCHER}"
        if [ -f "${APP_DIR}/VERSION" ]; then
            log_info "版本: $(cat "${APP_DIR}/VERSION")"
        fi
        return 0
    fi

    manifest_name="$(linux_manifest_name)" || return 1
    log_step "查询 Antigravity App 最新版本..."
    if ! manifest="$(fetch_text "${ANTIGRAVITY_HUB_MANIFEST_BASE}/${manifest_name}")" || [ -z "$manifest" ]; then
        log_error "Antigravity App manifest 下载失败。"
        hint_proxy "iag"
        log_info "手动下载: https://antigravity.google/download"
        return 1
    fi

    parsed="$(printf '%s\n' "$manifest" | parse_appimage_manifest)"
    url="$(printf '%s\n' "$parsed" | sed -n '1p')"
    sha="$(printf '%s\n' "$parsed" | sed -n '2p')"
    version="$(printf '%s\n' "$manifest" | awk '$1 == "version:" { print $2; exit }')"
    if [ -z "$url" ] || [ -z "$sha" ]; then
        log_error "manifest 里没有 Antigravity.AppImage。"
        return 1
    fi

    work="$(mktemp -d)"
    payload="${work}/Antigravity.AppImage"

    log_step "下载 Antigravity App ${version:-latest} ..."
    if ! download_file "$url" "$payload"; then
        rm -rf "$work"
        log_error "Antigravity AppImage 下载失败。"
        hint_proxy "iag"
        return 1
    fi

    expected="$(sha512_b64_to_hex "$sha" | tr '[:upper:]' '[:lower:]')"
    actual="$(file_sha512 "$payload" | tr '[:upper:]' '[:lower:]')"
    if [ -z "$expected" ] || [ "$actual" != "$expected" ]; then
        rm -rf "$work"
        log_error "Antigravity AppImage 校验失败，已丢弃下载文件。"
        return 1
    fi

    mkdir -p "$APP_DIR"
    mv "$payload" "$APP_IMAGE"
    rm -rf "$work"
    chmod 755 "$APP_IMAGE"
    printf '%s\n' "${version:-unknown}" > "${APP_DIR}/VERSION"
    write_app_launcher
    log_ok "Antigravity App 安装完成: ${APP_LAUNCHER}"
    log_info "AppImage: ${APP_IMAGE}"
}

install_app() {
    case "$(detect_os)" in
        macos) install_app_macos ;;
        linux) install_app_linux ;;
        *)
            log_error "不支持的系统: $(uname -s)"
            return 1
            ;;
    esac
}

uninstall_app_macos() {
    if has_cmd brew && brew list --cask antigravity >/dev/null 2>&1; then
        log_step "卸载 Homebrew cask antigravity..."
        brew uninstall --cask antigravity
        log_ok "Antigravity App 已卸载。保留 ~/.antigravity 和 ~/.gemini/antigravity。"
        return 0
    fi
    if [ -d "/Applications/Antigravity.app" ]; then
        log_warn "发现 /Applications/Antigravity.app，但不是 Homebrew cask 安装，未删除。"
        log_info "确认要删时: rm -rf /Applications/Antigravity.app"
        return 1
    fi
    log_info "Antigravity App 未安装。"
}

uninstall_app_linux() {
    local removed=0

    if [ -e "$APP_IMAGE" ] || [ -d "$APP_DIR" ]; then
        rm -rf "$APP_DIR"
        removed=1
    fi
    if [ -f "$APP_LAUNCHER" ] && grep -F -q "$APP_LAUNCHER_MARKER" "$APP_LAUNCHER"; then
        rm -f "$APP_LAUNCHER"
        removed=1
    fi
    if [ -f "$APP_DESKTOP" ] && grep -F -q "$APP_LAUNCHER" "$APP_DESKTOP"; then
        rm -f "$APP_DESKTOP"
        removed=1
    fi

    if [ "$removed" -eq 1 ]; then
        log_ok "Antigravity App 已卸载。保留 ~/.config/Antigravity 和 ~/.gemini/antigravity。"
    else
        log_info "Antigravity App 未安装。"
    fi
}

uninstall_app() {
    case "$(detect_os)" in
        macos) uninstall_app_macos ;;
        linux) uninstall_app_linux ;;
        *)
            log_error "不支持的系统: $(uname -s)"
            return 1
            ;;
    esac
}

install_all() {
    local rc=0
    install_cli || rc=1
    install_app || rc=1
    return "$rc"
}

uninstall_all() {
    local rc=0
    uninstall_cli || rc=1
    uninstall_app || rc=1
    return "$rc"
}

main() {
    local cmd="${1:-all}"
    case "$cmd" in
        all) install_all ;;
        cli|install-cli) install_cli ;;
        app|install-app) install_app ;;
        uninstall)
            case "${2:-all}" in
                all) uninstall_all ;;
                cli) uninstall_cli ;;
                app) uninstall_app ;;
                *)
                    log_error "未知卸载目标: $2"
                    usage
                    return 1
                    ;;
            esac
            ;;
        -h|--help|help) usage ;;
        *)
            log_error "未知命令: $cmd"
            usage
            return 1
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
