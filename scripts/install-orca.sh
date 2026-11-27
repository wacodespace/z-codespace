#!/usr/bin/env bash
# z-codespace/scripts/install-orca.sh — Orca 桌面应用（CLI 随应用提供）
# ============================================================
#
#   macOS   brew install --cask stablyai/orca/orca
#           必须写全名。裸 `brew install --cask orca` 是另一个 Plotly cask。
#           cask 会把 Orca.app 里的 CLI 链到 brew 的 bin/orca。
#   Linux   官方 AppImage → ~/.local/opt/orca/Orca.AppImage
#           启动器 ~/.local/bin/orca-ide
#           不安装名为 orca 的命令：GNOME 屏幕阅读器占用了 /usr/bin/orca。
#
# 用法:
#   bash scripts/install-orca.sh
#   bash scripts/install-orca.sh uninstall
#
# 终端里等价命令（bashrc 加载后）: iorca / uorca
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

ORCA_CASK="stablyai/orca/orca"
ORCA_BUNDLE_ID="com.stablyai.orca"
ORCA_RELEASE_BASE="https://github.com/stablyai/orca/releases/latest/download"

APP_DIR="${HOME}/.local/opt/orca"
APP_IMAGE="${APP_DIR}/Orca.AppImage"
APP_LAUNCHER="${HOME}/.local/bin/orca-ide"
APP_DESKTOP="${HOME}/.local/share/applications/orca-ide.desktop"
APP_LAUNCHER_MARKER="z-codespace-orca-launcher"

usage() {
    cat <<'EOF'
用法: install-orca.sh [命令]

  install             安装 Orca（默认）
  uninstall           卸载。保留 ~/.orca 和应用数据
  -h, --help          显示此帮助
EOF
}

hint_proxy() {
    if [ -z "${HTTPS_PROXY:-}${https_proxy:-}" ]; then
        log_warn "若当前网络访问不了 GitHub，先打开代理再试: proxy && iorca"
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

linux_manifest_name() {
    case "$(uname -m)" in
        x86_64|amd64) printf '%s\n' "latest-linux.yml" ;;
        aarch64|arm64) printf '%s\n' "latest-linux-arm64.yml" ;;
        *)
            log_error "不支持的架构: $(uname -m)"
            return 1
            ;;
    esac
}

# stdin: electron-builder latest-linux*.yml。stdout: AppImage 文件名和 sha512（两行）。
parse_appimage_manifest() {
    awk '
        $1 == "-" && $2 == "url:" && $3 ~ /AppImage$/ { url = $3; capture = 1; next }
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

macos_bundle_id() {
    [ -d "/Applications/Orca.app" ] || return 1
    plutil -extract CFBundleIdentifier raw -o - "/Applications/Orca.app/Contents/Info.plist" 2>/dev/null || true
}

orca_cask_installed() {
    has_cmd brew && brew list --cask "$ORCA_CASK" >/dev/null 2>&1
}

write_linux_launcher() {
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
Name=Orca
Comment=Orca IDE
Exec="${APP_LAUNCHER}" %U
Terminal=false
Categories=Development;
EOF
}

install_macos() {
    local bundle_id=""

    if [ -d "/Applications/Orca.app" ]; then
        bundle_id="$(macos_bundle_id || true)"
    fi

    if orca_cask_installed || [ "$bundle_id" = "$ORCA_BUNDLE_ID" ]; then
        log_ok "Orca 已安装: /Applications/Orca.app"
        log_info "CLI 由 Homebrew cask 提供（命令 orca）。升级: brew upgrade --cask ${ORCA_CASK}"
        return 0
    fi

    if ! has_cmd brew; then
        log_error "未找到 Homebrew，无法安装 Orca。"
        log_info "先装 Homebrew，或运行: bash install.sh --desktop"
        return 1
    fi

    log_step "安装 Orca (brew install --cask ${ORCA_CASK})..."
    log_info "不用裸 cask 名 orca：那是 Plotly 的另一个软件。"
    if ! brew install --cask "$ORCA_CASK"; then
        log_error "Orca 安装失败。"
        hint_proxy
        log_info "手动: brew install --cask ${ORCA_CASK}"
        return 1
    fi
    log_ok "Orca 已安装: /Applications/Orca.app"
}

install_linux() {
    local manifest_name manifest parsed file_url sha version url work payload expected actual

    if [ -x "$APP_IMAGE" ] && [ -x "$APP_LAUNCHER" ]; then
        log_ok "Orca 已安装: ${APP_LAUNCHER}"
        if [ -f "${APP_DIR}/VERSION" ]; then
            log_info "版本: $(cat "${APP_DIR}/VERSION")"
        fi
        return 0
    fi

    manifest_name="$(linux_manifest_name)" || return 1
    log_step "查询 Orca 最新版本..."
    if ! manifest="$(fetch_text "${ORCA_RELEASE_BASE}/${manifest_name}")" || [ -z "$manifest" ]; then
        log_error "Orca 版本清单下载失败。"
        hint_proxy
        log_info "手动下载: https://github.com/stablyai/orca/releases/latest"
        return 1
    fi

    parsed="$(printf '%s\n' "$manifest" | parse_appimage_manifest)"
    file_url="$(printf '%s\n' "$parsed" | sed -n '1p')"
    sha="$(printf '%s\n' "$parsed" | sed -n '2p')"
    version="$(printf '%s\n' "$manifest" | awk '$1 == "version:" { print $2; exit }')"
    if [ -z "$file_url" ] || [ -z "$sha" ]; then
        log_error "版本清单里没有 AppImage。"
        return 1
    fi
    case "$file_url" in
        https://*) url="$file_url" ;;
        *) url="${ORCA_RELEASE_BASE}/${file_url}" ;;
    esac

    work="$(mktemp -d)"
    payload="${work}/Orca.AppImage"

    log_step "下载 Orca ${version:-latest} ..."
    if ! download_file "$url" "$payload"; then
        rm -rf "$work"
        log_error "Orca AppImage 下载失败。"
        hint_proxy
        return 1
    fi

    expected="$(sha512_b64_to_hex "$sha" | tr '[:upper:]' '[:lower:]')"
    actual="$(file_sha512 "$payload" | tr '[:upper:]' '[:lower:]')"
    if [ -z "$expected" ] || [ "$actual" != "$expected" ]; then
        rm -rf "$work"
        log_error "Orca AppImage 校验失败，已丢弃下载文件。"
        return 1
    fi

    mkdir -p "$APP_DIR"
    mv "$payload" "$APP_IMAGE"
    rm -rf "$work"
    chmod 755 "$APP_IMAGE"
    printf '%s\n' "${version:-unknown}" > "${APP_DIR}/VERSION"
    write_linux_launcher
    log_ok "Orca 安装完成: ${APP_LAUNCHER}"
    log_info "AppImage: ${APP_IMAGE}"
    log_info "Linux 上命令是 orca-ide，不是 orca（/usr/bin/orca 是 GNOME 屏幕阅读器）。"
}

install_orca() {
    case "$(detect_os)" in
        macos) install_macos ;;
        linux) install_linux ;;
        *)
            log_error "不支持的系统: $(uname -s)"
            return 1
            ;;
    esac
}

uninstall_macos() {
    if orca_cask_installed; then
        log_step "卸载 Homebrew cask ${ORCA_CASK}..."
        brew uninstall --cask "$ORCA_CASK"
        log_ok "Orca 已卸载。保留 ~/.orca 和应用数据。"
        return 0
    fi
    if [ -d "/Applications/Orca.app" ]; then
        log_warn "发现 /Applications/Orca.app，但不是 ${ORCA_CASK} 安装的，未删除。"
        log_info "确认要删时: rm -rf /Applications/Orca.app"
        return 1
    fi
    log_info "Orca 未安装。"
}

uninstall_linux() {
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
        log_ok "Orca 已卸载。保留 ~/.orca 和应用数据。"
    else
        log_info "Orca 未安装。"
    fi
}

uninstall_orca() {
    case "$(detect_os)" in
        macos) uninstall_macos ;;
        linux) uninstall_linux ;;
        *)
            log_error "不支持的系统: $(uname -s)"
            return 1
            ;;
    esac
}

main() {
    local cmd="${1:-install}"
    case "$cmd" in
        install|all) install_orca ;;
        uninstall) uninstall_orca ;;
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
