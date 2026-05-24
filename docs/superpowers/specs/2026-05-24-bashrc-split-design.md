# 拆分 configs/common/.bashrc — 设计

**日期：** 2026-05-24
**对应任务：** P1#2（架构评审第四节"`.bashrc` 是单体巨石"）
**状态：** 设计已锁定，待 Ralph 执行
**依赖：** P0、P1#1、P2#2 都已合并

## 背景

`configs/common/.bashrc` 当前 457 行（P0/P2#2 后），里面混了：

- 真·通用配置（env / proxy / shell options / PS1 / GPU 监控 / NVM 等）
- 阿里 GPU 集群 site-specific（`cdn`/`cdz` 导航、`ossutil`/`v3` 工具、`docker→pouch` 包装）— 约 15 行
- AI CLI 安装/卸载（`_ai_*` 一系列函数 + `icc`/`ucc`/`icx`/`ucx`/`cc`/`cx`）— 约 200 行
- 加载钩子（`.bash_aliases` / `.bash_private` / `.bash_server`）

阿里 site 内容污染了 macOS 桌面命名空间；AI CLI 一大块让通用入口难读。

## 设计决策

### §1 文件拆分（三块粗拆）

```text
configs/
├── common/
│   ├── .bashrc                       # ~150 行：env + shell + loader + 通用 alias + GPU + NVM
│   └── bash/
│       ├── git-aliases.sh            # 所有 Git alias + gl/glt/gls/gcm/gg 函数
│       └── ai-cli.sh                 # _ai_* 函数 + icc/ucc/icx/ucx/cc/cx
└── site/
    └── aliyun-gpu.sh                 # cdn/cdz + ossutil/v3 + docker→pouch
```

### §1.1 哪些内容去哪个文件

**configs/common/.bashrc（保留）**

- 1-8 行 Homebrew 检测
- 9-14 行 非交互式退出 guard
- 15-37 行 proxy / noproxy 函数
- 38-100 行 terminal/color/history/PS1/dircolors/通用 alias（ls/ll/rm 等）
- 105-123 行 本仓库 Git 作者识别块
- 180-189 行 GPU 监控别名（NVIDIA + AMD ROCm，通用 dev 机器都可能用）
- 204-205 行 PATH
- 207-209 行 AI_NPM_PREFIX export
- 220-224 行 `.bash_aliases` / `.bash_private` 加载
- 226-244 行 NVM
- 末尾 `.bash_server` source 行（P0 已有）
- 末尾 grok installer 块（外部注入，不动）
- **新增**：bash/*.sh loader（详 §2）
- **新增**：`.bash_site` source 行

**configs/common/bash/git-aliases.sh（搬出）**

- 125-178 行：`alias g='git'` 起到 `gg` 函数结束的整段 Git 块
- 加上文件末尾的 `gsn`/`gse`/`gsu`/`gclun`/`gclue`/`gcgun`/`gcgue`（如果还在 .bashrc 里）

**configs/common/bash/ai-cli.sh（搬出）**

- 244-450 行整段：`_ai_fetch` 起，到 `cx()` 函数结束
- 包括 `_ai_ensure_nvm` / `_ai_ensure_node` / `_ai_ensure_npm_prefix` / `_ai_known_npm_prefixes` / `_ai_unique_known_npm_prefixes` / `_ai_prefix_has_package` / `_ai_uninstall_from_prefix` / `_ai_cleanup_duplicate_npm_package` / `_ai_report_duplicate_npm_package` / `_ai_install_npm_global_managed` / `_install_claude_code` / `_install_codex` / `_uninstall_npm_global` / `_uninstall_claude_code` / `_uninstall_codex` 以及用户面的 `icc`/`icx`/`ucc`/`ucx`/`cc`/`cx`

**configs/site/aliyun-gpu.sh（搬出）**

- 101-104 行：`cdn`/`cdz` 导航别名
- 191-197 行：`ossutil`/`v3`/`pps` 工具别名 + Linux 下的 `ossutil_x86_64` rebind
- 199-202 行：`docker() { pouch ... }` 包装

### §2 .bashrc loader 机制

`.bashrc` 末尾（在 .bash_server / grok 块之前）新增显式 source 三行：

```bash
# --- 加载拆分模块（git aliases / AI CLI 等） ---
_BASH_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/bash"
[ -d "$_BASH_DIR" ] && {
    . "$_BASH_DIR/git-aliases.sh"
    . "$_BASH_DIR/ai-cli.sh"
}
unset _BASH_DIR
```

并保留/添加 site 钩子（紧邻 .bash_server 那一对）：

```bash
[ -f ~/.bash_server ] && . ~/.bash_server     # P0 已有
[ -f ~/.bash_site ] && . ~/.bash_site         # 新增
```

加新模块的代价：在 .bashrc 末尾加一行 `. "$_BASH_DIR/xxx.sh"`。可接受。

### §3 install.sh 安装路径

`scripts/profile-server.sh` 的 `apply_server()` 在现有 `~/.bash_server` 软链之外，新增 `~/.bash_site` → `configs/site/aliyun-gpu.sh` 的软链。

```bash
apply_server() {
    local force="${1:-false}"
    log_step "应用 server 层（~/.bash_server, ~/.bash_site）..."
    safe_link "$PROJECT_ROOT/configs/server/.bash_server" "$HOME/.bash_server" "$force"
    safe_link "$PROJECT_ROOT/configs/site/aliyun-gpu.sh"  "$HOME/.bash_site"   "$force"
}
```

说明：当前用户的 Ubuntu server 就是阿里 GPU 集群，所以 `ubuntu-server` profile 直接绑 `aliyun-gpu` site。未来若出现其它 server site，可拆出 `apply_site_aliyun_gpu()` 或引入 `--site=` flag，那是另一次重构。

macOS 桌面 / Ubuntu desktop profile 都**不会**装 `~/.bash_site`，所以 `.bashrc` 末尾的 `[ -f ~/.bash_site ]` 检查不通过，cdn/cdz/pouch/ossutil 不会污染桌面 shell。

### §4 已安装 ~/.bashrc 的兼容性

`~/.bashrc` 已是指向 `configs/common/.bashrc` 的软链，无需重新 link。下次新 shell 启动时，新 .bashrc 自动按 `${BASH_SOURCE[0]}` 推断出 repo 内的 `bash/` 子目录并 source。

## 验收命令（Ralph 完成 promise 的前置条件）

```bash
# 结构
test -f configs/common/.bashrc
test -f configs/common/bash/git-aliases.sh
test -f configs/common/bash/ai-cli.sh
test -f configs/site/aliyun-gpu.sh

# .bashrc 瘦身
test "$(wc -l < configs/common/.bashrc)" -lt 200

# 语法
bash -n configs/common/.bashrc
bash -n configs/common/bash/git-aliases.sh
bash -n configs/common/bash/ai-cli.sh
bash -n configs/site/aliyun-gpu.sh

# loader 存在
grep -q '_BASH_DIR' configs/common/.bashrc
grep -q 'git-aliases.sh' configs/common/.bashrc
grep -q 'ai-cli.sh' configs/common/.bashrc
grep -q 'bash_site' configs/common/.bashrc
grep -q 'bash_server' configs/common/.bashrc

# 内容搬迁正确
grep -q 'alias g=' configs/common/bash/git-aliases.sh
grep -q '^gg()' configs/common/bash/git-aliases.sh
grep -q '_ai_install_npm_global_managed' configs/common/bash/ai-cli.sh
grep -q '^icc()' configs/common/bash/ai-cli.sh
grep -q 'alias cdn=' configs/site/aliyun-gpu.sh
grep -q 'pouch' configs/site/aliyun-gpu.sh
grep -q 'ossutil' configs/site/aliyun-gpu.sh

# common 里搬出的内容已无残留
test "$(grep -c "^alias g='git'" configs/common/.bashrc)" -eq 0
test "$(grep -c '^icc()' configs/common/.bashrc)" -eq 0
test "$(grep -c '^alias cdn=' configs/common/.bashrc)" -eq 0
test "$(grep -c '^docker()' configs/common/.bashrc)" -eq 0

# profile-server 升级
grep -q bash_site scripts/profile-server.sh

# 保留：通用别名 / GPU 监控 / NVM / proxy 仍在 common
grep -q '^alias nv=' configs/common/.bashrc
grep -q 'proxy()' configs/common/.bashrc
grep -q 'NVM_DIR' configs/common/.bashrc
```

## 约束

- 直接在 master 改，不开新分支
- 不动 `configs/nvim/`、`scripts/install-nvim.sh`、`scripts/install-deps.sh`
- 不动 P0/P1#1/P2#2 已完成的工作
- 不动 grok installer 注入块（外部 CLI 自管）
- 不做 git commit；改完用户自己 review
- 保持 .bashrc 中 source 顺序：env → 通用 aliases → bash/*.sh → bash_server → bash_site → grok block

## 已知后续工作（不在本设计范围）

- DESIGN.md 系统性 review（P2#1 剩余）
- Ubuntu 真机验证（P0/P1#1/P2#2/P1#2 都没在真 Ubuntu 上验证过）
- 如果用户未来有非阿里的 server，需要 site mechanism 进一步抽象
