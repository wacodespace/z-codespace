# z-codespace — 开发环境配置管理

可重复、可审计、可自动化部署的开发环境方案。支持 macOS 和 Linux 裸环境一键安装。

## 项目目标

- **生产可用**：稳定优先，适合 AI infra / CUDA / Python / C++ 日常开发
- **可重复部署**：脚本幂等，配置版本锁定，支持离线迁移
- **最小依赖**：不依赖 Docker / Nix / Ansible / Home Manager
- **跨平台**：macOS 本地 + Linux 服务器 + SSH 远程 + GPU 机器

## 支持平台

| 平台 | 状态 |
|------|------|
| macOS (Apple Silicon / Intel) | 完整支持 |
| Ubuntu / Debian | 完整支持 |
| RHEL / CentOS / Rocky | 完整支持 |
| Arch Linux | 基本支持 |

## 快速开始

### 完整安装（基础配置 + Neovim 环境）

```bash
git clone https://github.com/wacodespace/z-codespace.git
cd z-codespace
bash install.sh --all
```

### 仅安装基础配置（bashrc / vimrc / tmux）

```bash
# macOS
bash macos_install.sh

# Linux
bash linux_install.sh
```

### 仅安装 Neovim (LazyVim) 环境

```bash
bash scripts/install-deps.sh    # 安装依赖
bash scripts/install-nvim.sh    # 部署配置（会先 headless 自检，再 Lazy sync 拉插件，无需打开 nvim）
```

### 强制覆盖（不备份）

```bash
bash install.sh --all --force
```

## 升级

### 升级插件（按 lazy-lock.json 同步）

```bash
bash scripts/update-nvim.sh
```

### 升级插件到最新版本

```bash
bash scripts/update-nvim.sh --upgrade
# 验证后提交 lazy-lock.json
git add configs/nvim/lazy-lock.json
git commit -m "chore: update lazy-lock.json"
```

### 回滚插件

```bash
git checkout configs/nvim/lazy-lock.json
bash scripts/update-nvim.sh
```

## 卸载

```bash
# 仅移除配置链接
bash scripts/uninstall-nvim.sh

# 同时清理插件和缓存
bash scripts/uninstall-nvim.sh --all
```

## 离线部署

适用于无外网的 Linux 服务器 / GPU 机器：

```bash
# 1. 在有网机器上准备离线包
bash scripts/offline-pack.sh

# 2. 传输到目标机器
scp ~/nvim-offline-*.tar.gz user@server:/tmp/

# 3. 在目标机器解压并部署
cd /tmp && tar xzf nvim-offline-*.tar.gz
bash nvim-bundle/deploy.sh

# 前提: 目标机器需已安装 nvim + gcc（可通过 install-deps.sh 安装）
```

## 目录结构

```text
z-codespace/
├── configs/
│   ├── common/                  # 通用配置
│   │   ├── .bash_profile       #   Bash 登录 shell 入口，加载 .bashrc
│   │   ├── .bashrc             #   Bash (含平台检测 / Git 别名 / AI CLI)
│   │   ├── .vimrc              #   Vim
│   │   └── .tmux.conf          #   Tmux (含 nvim 无缝导航)
│   ├── macos/                   # macOS 特定 (Alacritty / Ghostty)
│   ├── linux/                   # Linux 特定 (服务器优化)
│   └── nvim/                    # LazyVim 配置
│       ├── init.lua             #   入口
│       ├── lazyvim.json         #   启用的 LazyVim extras
│       ├── lazy-lock.json       #   插件版本锁
│       └── lua/
│           ├── config/          #   基础设置 (options/keymaps/autocmds)
│           └── plugins/         #   插件配置 (editor/lang/treesitter)
├── scripts/                     # 自动化脚本
│   ├── lib.sh                   #   共享工具函数
│   ├── setup-ssh.sh             #   自动检查 / 生成 SSH key
│   ├── install-deps.sh          #   安装依赖 (nvim/rg/fd/node...)
│   ├── install-nvim.sh          #   部署 LazyVim 配置
│   ├── uninstall-nvim.sh        #   卸载
│   ├── update-nvim.sh           #   更新插件
│   ├── doctor.sh                #   环境健康检查
│   ├── offline-pack.sh          #   创建离线包
│   └── offline-deploy.sh        #   离线部署
├── docs/
│   └── DESIGN.md                # 设计文档（依赖 / LSP / 离线迁移等）
├── install.sh                   # 统一安装入口
├── macos_install.sh             # macOS 基础配置安装
├── linux_install.sh             # Linux 基础配置安装
└── README.md
```

## 环境检查

```bash
bash scripts/doctor.sh
```

输出示例：

```text
[STEP]  --- 必需工具 ---
[ OK ]  nvim: NVIM v0.10.4
[ OK ]  git: git version 2.43.0
[ OK ]  rg: ripgrep 14.1.1
[ OK ]  node: v22.12.0
[STEP]  --- 配置状态 ---
[ OK ]  nvim 配置: ~/.config/nvim -> .../configs/nvim
[ OK ]  lazy-lock.json 存在 (约 40 个插件)
```

## 配置说明

### Neovim (LazyVim)

- **Leader 键**: Space
- **缩进**: 4 空格 (Python)，2 空格 (C/C++)
- **LSP**: pyright / clangd / lua_ls / bashls / jsonls / yamlls / marksman
- **格式化**: black + isort (Python) / stylua (Lua) / shfmt (Shell)
- **Treesitter**: python / c / cpp / cuda / lua / bash / json / yaml / markdown
- **版本锁定**: 通过 lazy-lock.json，不自动检查更新

常用快捷键：

| 快捷键 | 功能 |
|--------|------|
| `<Space>ff` | 查找文件 |
| `<Space>fg` | 全局搜索 (ripgrep) |
| `<Space>e` | 文件浏览器 |
| `<Space>l` | Lazy 插件管理 |
| `<C-\>` | 浮动终端 |
| `<C-h/j/k/l>` | 窗口 / tmux pane 切换 |

### tmux

- 前缀键: `C-a`
- vi 模式 + hjkl 面板导航
- 窗口切换: macOS 用 `C-a Left/Right`，Linux 用 `Alt-h/l`
- Pane 位置互换: `C-a H/J/K/L`
- 鼠标支持
- 与 nvim 无缝导航 (`C-h/j/k/l`)
- `escape-time 10` 避免 nvim Esc 延迟

### Bash

- 跨平台别名（macOS/Linux）
- Git 快捷键 (输入 `gg` 查看)
- GPU 监控别名 (NVIDIA: `nv` / AMD: `rc`)
- AI CLI 工具集成 (`icc`/`ucc` 安装/卸载 Claude Code, `icx`/`ucx` 安装/卸载 Codex)

### SSH key

macOS / Linux 基础安装都会执行 `scripts/setup-ssh.sh`：

- 已存在 `~/.ssh/id_ed25519` / `id_rsa` / `id_ecdsa` 时直接复用
- 不存在时自动生成 `~/.ssh/id_ed25519`
- 尝试把 `github.com` 加入 `~/.ssh/known_hosts`
- 输出公钥，方便添加到 GitHub 的 SSH keys

### 私有配置

```bash
cp .bash_private.example ~/.bash_private
vim ~/.bash_private
```

## 故障排查

### nvim 启动报错

```bash
# 检查依赖
bash scripts/doctor.sh

# 重新同步插件
bash scripts/update-nvim.sh

# 完全重装
bash scripts/uninstall-nvim.sh --all
bash scripts/install-nvim.sh
```

### Treesitter parser 编译失败

确保安装了 C 编译器：

```bash
# macOS
xcode-select --install

# Linux (Debian/Ubuntu)
sudo apt-get install build-essential

# Linux (RHEL/CentOS)
sudo yum install gcc gcc-c++ make
```

### LSP 不工作

```bash
# nvim 内检查 LSP 状态
:LspInfo

# 检查 mason 安装的工具
:Mason

# 手动安装 LSP
:MasonInstall pyright
```

### 离线部署后插件不可用

- 确保源机器和目标机器**架构一致** (x86_64 / arm64)
- Treesitter parser (.so) 不能跨架构迁移
- 检查 `~/.local/share/nvim/lazy/` 目录是否完整

## 设计文档

详细的设计决策、依赖管理、LSP 策略、离线迁移方案见 [docs/DESIGN.md](docs/DESIGN.md)。
