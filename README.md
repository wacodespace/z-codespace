# z-codespace — 个人开发环境配置与冷启动仓库

个人 dotfiles、共享 Agent Skills 与新机器冷启动入口。支持 macOS Desktop、Linux Desktop 与 Linux / GPU Server。

## 冷启动三层模型

1. **脚本层（[install.sh](install.sh)）**：只做四件确定性的事——软链 `configs/`、按目录软链 `skills/`、写 Git 全局配置、SSH bootstrap（含 `ssh.github.com:443` host key）。不调用包管理器，不下载软件。
2. **Shell 层（[configs/common/bash/ai-cli.sh](configs/common/bash/ai-cli.sh)）**：提供 `icc` / `icx` / `igk`（Claude Code / Codex / Grok）联网安装入口，用来在新机器上拉起第一个 Agent。
3. **清单层（[BOOTSTRAP.md](BOOTSTRAP.md)）**：记录其余软件的期望结果与已知约束（Neovim、Antigravity、Orca、Flameshot、中转切换器等），交由第一个 Agent 现场安装。

## 快速开始

```bash
git clone https://github.com/wacodespace/z-codespace.git
cd z-codespace
bash install.sh                              # 自动检测 profile；GPU 容器显式加 --profile=ubuntu-server
source ~/.bashrc && proxy && icc             # 或 icx / igk 拉起第一个 Agent，之后按 BOOTSTRAP.md 装其余软件
```

常用参数：

```bash
bash install.sh --profile=macos-desktop      # macOS 桌面
bash install.sh --profile=ubuntu-desktop     # Linux 桌面
bash install.sh --profile=ubuntu-server      # Linux 服务器 / GPU 容器
bash install.sh --skills                     # 仅软链共享 Agent Skills（不改 Git / SSH）
bash install.sh --force                      # 强制覆盖，不备份
```

> 没有 `SSH_CLIENT` / `SSH_TTY` 的 Linux shell 会被自动识别为 `ubuntu-desktop`，GPU 容器里请显式传入 `--profile=ubuntu-server`。

### Profile 与软链映射

| Profile | `configs/common` + `configs/nvim` | `configs/desktop` | `configs/server` + `configs/site` |
|---------|:---:|:---:|:---:|
| `macos-desktop` | ✓ | ghostty / cmux / flameshot | – |
| `ubuntu-desktop` | ✓ | alacritty (`shared.toml` + `alacritty.toml`) | – |
| `ubuntu-server` | ✓ | – | `.bash_server` + `aliyun-gpu.sh` |

## 目录结构

```text
z-codespace/
├── BOOTSTRAP.md                 # 冷启动第三层：软件清单与约束（给 Agent 读）
├── AGENTS.md / CLAUDE.md        # 仓库级 Agent 规则
├── install.sh                   # 冷启动第一层：软链 + Git + SSH 入口
├── Casks/
│   └── flameshot.rb             # macOS Flameshot 自定义 Homebrew cask
├── configs/
│   ├── common/                  # 三 profile 共用（.bash_profile / .bashrc / .vimrc / .tmux.conf）
│   │   └── bash/                #   git-aliases.sh / ai-cli.sh
│   ├── desktop/                 # 桌面配置（macos: ghostty/flameshot；linux: alacritty）
│   ├── server/                  # 服务器配置（.bash_server）
│   ├── site/                    # 站点配置（aliyun-gpu.sh / ssh_config.site.example）
│   └── nvim/                    # LazyVim 配置（三 profile 共享，软链到 ~/.config/nvim）
├── scripts/
│   ├── lib.sh                   # 日志、系统检测、safe_link（含备份）
│   ├── profile-common.sh        # common + nvim + skills 软链
│   ├── profile-desktop.sh       # desktop/macos 与 desktop/linux 软链
│   ├── profile-server.sh        # server 软链
│   └── setup-ssh.sh             # ed25519 生成、GitHub 443、Include ~/.ssh/config.site
└── skills/                      # 共享 Agent Skills（Claude / Codex / Grok 唯一真身）
    └── codex-account-switch/
```

## 核心配置速查

- **Bash**：跨平台别名、`proxy` / `noproxy` 本地代理探测、Git 快捷命令（`gg` 查看）、GPU 监控（`nv` / `rc`）、AI CLI 安装与启动（`icc`/`icx`/`igk`，`cc`/`ccf`/`ccy`，`cx`/`cxf`/`cxy`，`gk`/`gky`）。
- **tmux**：前缀 `C-a`、vi 模式、与 nvim 无缝导航（`C-h/j/k/l`）、Pane 互换（`C-a H/J/K/L`）。
- **Neovim (LazyVim)**：Leader 为 `Space`，需 Neovim ≥ 0.11.2，首次打开自动拉插件；Visual 模式 `<Space>xs` 复制「绝对路径 + 选中代码」给 AI CLI。
- **SSH**：`scripts/setup-ssh.sh` 复用已有 key 或生成 `~/.ssh/id_ed25519`，配置 `github.com` 走 `ssh.github.com:443`、钉 `known_hosts`，并在存在 `~/.ssh/config.site` 时写入 `Include`。
- **共享 Agent Skills**：`skills/<name>/` 按目录软链到 `~/.agents/skills/<name>`（Codex / Grok）和 `~/.claude/skills/<name>`（Claude Code），`skills/<name>/bin/*` 链到 `~/.local/bin`。维护约定见 [AGENTS.md](AGENTS.md)。

## 私有配置

```bash
cp .bash_private.example ~/.bash_private
```

本仓库不保存密钥、Token 或机器特定 SSH 配置（见 `.gitignore`）。
