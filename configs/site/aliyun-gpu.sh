# aliyun-gpu.sh - 阿里 GPU 集群 site-specific shell 配置
# 由 ubuntu-server profile 通过 install.sh 软链到 ~/.bash_site
# .bashrc 末尾通过 [ -f ~/.bash_site ] 钩子自动 source
# 桌面 (macos-desktop / ubuntu-desktop) 不会装这个文件，避免污染命名空间。
# ============================================================

# --- 导航别名 ---
alias cdn='cd /chatgpt_nas'
alias cdz='cd /home/admin/zhc'

# --- 工具别名 ---
if [[ "$(uname -s)" == "Linux" ]]; then
    alias ossutil='ossutil_x86_64'
fi
alias v3='rocprofv3'

# --- OSS 上传/下载 ---
# 凭据走 ~/.ossutilconfig（600），不放命令行参数——共享集群上 ps 可见明文 AK/SK。
# 首次运行 oss 时从 ~/.bash_private 的 OSS_AK_ID / OSS_AK_SECRET 生成配置文件。
# 兼容旧配置：oss 曾是 alias，需先清理，否则函数定义时会被 alias 展开导致语法错误。
unalias oss 2>/dev/null || true
_oss_ensure_config() {
    local cfg="$HOME/.ossutilconfig"
    [ -f "$cfg" ] && return 0
    if [ -z "${OSS_AK_ID:-}" ] || [ -z "${OSS_AK_SECRET:-}" ]; then
        echo "缺少 OSS 凭据：请先配置 ~/.bash_private（OSS_AK_ID / OSS_AK_SECRET）" >&2
        return 1
    fi
    (
        umask 077
        cat > "$cfg" <<EOF
[Credentials]
language=EN
endpoint=${OSS_ENDPOINT:-cn-zhangjiakou.oss.aliyuncs.com}
accessKeyID=$OSS_AK_ID
accessKeySecret=$OSS_AK_SECRET
EOF
    )
    chmod 600 "$cfg"
    echo "已生成 OSS 凭据配置: $cfg (600)" >&2
}
oss() {
    _oss_ensure_config || return 1
    ossutil64 --config-file "$HOME/.ossutilconfig" cp "$@"
}

# --- docker → pouch 包装 ---
docker() {
    pouch "$@"
}
