# BOOTSTRAP.md — 新机器软件清单与约束

本文件是冷启动**第三层**：供新机器上已经跑起来的 Agent（或人）按平台安装软件。只写**期望结果**和**已知约束**，安装方式由 Agent 按当下系统环境现场执行。

## 冷启动三步

```bash
git clone https://github.com/wacodespace/z-codespace.git
cd z-codespace
bash install.sh                              # GPU 容器里显式加 --profile=ubuntu-server
source ~/.bashrc && proxy && icc             # 或 icx / igk，拉起第一个 Agent
```

> **Profile 检测约束**：没有 `SSH_CLIENT` / `SSH_TTY` 的 Linux shell 会被 `install.sh` 当成 `ubuntu-desktop`。在 GPU 容器或无 SSH 变量的终端里，显式执行 `bash install.sh --profile=ubuntu-server`。

---

## 期望软件与已知约束

### 1. 基础 CLI 与 Neovim（全平台）

- **期望工具**：`git`、`curl`、`tmux`、`neovim`（**≥ 0.11.2**）、`ripgrep`（`rg`）、`fd`、C 编译器（`gcc` 或 `clang`，Treesitter parser 编译需要）、`node`、`fzf`、`lazygit`。
- **Neovim 配置**：`install.sh` 已将 `configs/nvim` 软链到 `~/.config/nvim`；装好 Neovim ≥ 0.11.2 后直接打开 `nvim`，由 LazyVim 自动拉取插件。
- **Debian / Ubuntu 的 `fd`**：apt 包名为 `fd-find`，二进制名为 `fdfind`，需软链成 `~/.local/bin/fd`。
- **无 sudo 环境**：预编译 / 静态二进制统一放 `~/.local/bin`（已在 `.bashrc` 的 `PATH` 中）。

### 2. Antigravity（CLI + App）

- **期望结果**：
  - 全平台：Antigravity CLI（命令 `agy`，放 `~/.local/bin/agy`）。
  - Desktop profile（`macos-desktop` / `ubuntu-desktop`）：另装 Antigravity App（macOS 用 Homebrew cask `antigravity`；Linux 桌面用官方 AppImage，启动器放 `~/.local/bin/antigravity`）。`ubuntu-server` 只装 CLI。
- **关键约束**：Antigravity 官方安装器会改写 `~/.bashrc` / `~/.profile`，而这些文件是指向本仓库的软链接。
  - 安装 CLI 时带 `--skip-path` / `--skip-aliases`。
  - 若安装器仍改写了指向仓库的 rc 文件，立即 `git checkout` 还原仓库文件。`~/.local/bin` 已在 `configs/common/.bashrc` 的 `PATH` 里，不需要安装器追加。

### 3. Orca（仅 Desktop）

- **期望结果**：桌面环境安装 Orca；`ubuntu-server` 跳过。
- **macOS 约束**：Homebrew cask 名必须写全名 `stablyai/orca/orca`（裸名 `orca` 是 Plotly 的另一个软件）。CLI 随应用提供（`orca`）。
- **Linux 桌面约束**：使用官方 AppImage，启动器命名必须为 `orca-ide`（放在 `~/.local/bin/orca-ide`），不要占用 `/usr/bin/orca`（GNOME 屏幕阅读器）。

### 4. macOS 桌面应用（仅 `macos-desktop`）

- **期望应用**：Homebrew、Ghostty、cmux（`manaflow-ai/cmux`，复用 `~/.config/ghostty/config`）、Rectangle、Flameshot、MesloLG Nerd Font（`font-meslo-lg-nerd-font`）。
- **Flameshot 约束**：官方 Homebrew cask 因未公证已停用，必须使用本仓库提供的 cask：
  ```bash
  brew tap wacodespace/z-codespace https://github.com/wacodespace/z-codespace
  brew install --cask wacodespace/z-codespace/flameshot
  ```
  首次启动需在 macOS「系统设置 → 隐私与安全性」中批准并授予屏幕录制权限。配置文件 `flameshot.ini` 已由 `install.sh` 软链（区域截图快捷键 `Command+1`）。
- **Alacritty**：macOS 已停用，不再安装。Linux 桌面如使用 Alacritty，其配置已由 `install.sh` 软链。

### 5. AI 中转切换器（按需）

- **期望结果**：macOS 装桌面版 CC Switch（`brew install --cask cc-switch`）；Linux 装 `cc-switch-cli`（放 `~/.local/bin/cc-switch`）。
- **关键约束**：本仓库只记录工具，**绝不保存 AI API Key / Base URL**。中转 provider 列表由切换器写入各 CLI 的原生配置（`~/.claude/settings.json`、Codex `config.toml`），`cc` / `cx` 启动器裸调即可生效。
