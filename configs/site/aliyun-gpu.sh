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
alias oss='ossutil64 -i $OSS_AK_ID -k $OSS_AK_SECRET -e ${OSS_ENDPOINT:-cn-zhangjiakou.oss.aliyuncs.com} cp'

# --- docker → pouch 包装 ---
docker() {
    pouch "$@"
}
