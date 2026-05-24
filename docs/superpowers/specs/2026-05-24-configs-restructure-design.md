# configs/ 目录按 profile 重组 — 设计

**日期：** 2026-05-24
**对应任务：** P1#1（架构评审第三节"三个目标平台塌成了两个"）
**状态：** 设计已锁定，待 Ralph 执行

## 背景

项目目标是覆盖三个平台：macOS desktop、Ubuntu desktop、Ubuntu server。但现有 `configs/` 只分 `common/macos/linux/nvim` 四个目录，把 Ubuntu desktop 和 Ubuntu server 都塞进 `linux/`。`linux_install.sh` 同时装 alacritty（GUI 终端）和 `.bash_server`（服务器优化），靠运行时 `$SSH_CLIENT` 启发式区分。结果：Ubuntu desktop 没有显式位置，未来扩展（多机器 profile、CI 安装等）困难。

## 设计决策

### §1 目录结构（分层叠加）

```text
configs/
├─ common/                   # 三 profile 都装
│  ├─ .bash_profile
│  ├─ .bashrc                # 末尾已 [-f ~/.bash_server] && . ~/.bash_server
│  ├─ .vimrc
│  └─ .tmux.conf
├─ desktop/                  # 只在 desktop profile 装
│  ├─ .config/alacritty/shared.toml      # 跨 OS 共享片段
│  ├─ macos/.config/alacritty/alacritty.toml
│  ├─ macos/.config/ghostty/config
│  └─ linux/.config/alacritty/alacritty.toml
├─ server/                   # 只在 ubuntu-server profile 装
│  └─ .bash_server
└─ nvim/                     # 与 profile 解耦，由 install-nvim.sh 单独处理
```

### §1.1 Profile 组合规则

| Profile | common | desktop/shared | desktop/{os} | server |
|---------|:---:|:---:|:---:|:---:|
| `macos-desktop` | ✓ | ✓ | macos | – |
| `ubuntu-desktop` | ✓ | ✓ | linux | – |
| `ubuntu-server` | ✓ | – | – | ✓ |

### §1.2 文件迁移映射（`git mv` 保留 history）

| 源路径 | 目标路径 |
|--------|---------|
| `configs/common/.config/alacritty/shared.toml` | `configs/desktop/.config/alacritty/shared.toml` |
| `configs/macos/.config/alacritty/alacritty.toml` | `configs/desktop/macos/.config/alacritty/alacritty.toml` |
| `configs/macos/.config/ghostty/config` | `configs/desktop/macos/.config/ghostty/config` |
| `configs/linux/.config/alacritty/alacritty.toml` | `configs/desktop/linux/.config/alacritty/alacritty.toml` |
| `configs/linux/.bash_server` | `configs/server/.bash_server` |

迁完 `configs/macos/` 和 `configs/linux/` 应为空，直接删除。

### §2 install.sh 调度

**Profile 检测**

```bash
detect_profile() {
  [ "$(uname -s)" = "Darwin" ] && echo "macos-desktop" && return
  [ -n "$SSH_CLIENT$SSH_TTY" ] && echo "ubuntu-server" && return
  echo "ubuntu-desktop"
}
```

**Dispatch 表**

```bash
case "$PROFILE" in
  macos-desktop)
    install_homebrew
    install_desktop_apps_macos          # alacritty / ghostty / Nerd Font via brew
    apply_common
    apply_desktop_shared
    apply_desktop_macos ;;
  ubuntu-desktop)
    install_packages_apt_min            # vim/tmux/curl/wget/git/htop/openssh-client
    apply_common
    apply_desktop_shared
    apply_desktop_linux ;;              # 不强装 alacritty 二进制，仅 symlink 配置
  ubuntu-server)
    install_packages_apt_min
    apply_common
    apply_server ;;
esac
```

**库函数分布**

- `scripts/lib.sh` — 不变（颜色/日志/safe_link/has_cmd 等）
- `scripts/profile-common.sh` — `apply_common()`
- `scripts/profile-desktop.sh` — `apply_desktop_shared()` / `apply_desktop_macos()` / `apply_desktop_linux()` / `install_homebrew()` / `install_desktop_apps_macos()`
- `scripts/profile-server.sh` — `apply_server()`
- `scripts/profile-packages.sh` — `install_packages_apt_min()` 等包管理逻辑（从 linux_install.sh 抽出）

### §2.1 命令行参数

```
bash install.sh                          # 自动检测 profile，含 nvim/claude-hud 交互询问
bash install.sh --profile=ubuntu-server  # 显式指定
bash install.sh --server                 # 语法糖 = --profile=ubuntu-server
bash install.sh --desktop                # 语法糖：mac 时 = macos-desktop，linux 时 = ubuntu-desktop
bash install.sh --all                    # profile + nvim + claude-hud
bash install.sh --nvim-only              # 保留现有
bash install.sh --claude-hud             # 保留现有
bash install.sh --force                  # 强制覆盖
```

### §2.2 删除 / 保留

**删除**

- `macos_install.sh`（逻辑搬到 `install.sh` + `scripts/profile-desktop.sh`）
- `linux_install.sh`（同上）
- 迁移后空的 `configs/macos/`、`configs/linux/`

**保留不动**

- `configs/nvim/` 及 nvim 相关脚本（`install-nvim.sh` / `install-deps.sh` / `update-nvim.sh` / `uninstall-nvim.sh` / `offline-pack.sh` / `offline-deploy.sh`）
- `scripts/setup-ssh.sh`、`scripts/doctor.sh`、`scripts/install-claude-hud.sh`
- `configs/common/.bashrc` 内容（P1#2 是另一个 Ralph 处理）

### §3 文档同步（吸收 P2#1 的一部分）

本轮 Ralph 顺手更新：

- `README.md` —— 「目录结构」段、「快速开始」段、所有 `macos_install.sh` / `linux_install.sh` 引用
- `docs/DESIGN.md` —— 「目录结构」段、「Neovim 版本」（顺手把 0.10.x → 0.11.5）

避免文档继续漂移。

## 验收命令（Ralph 完成 promise 的前置条件）

```bash
# 结构正确
test -d configs/common && test -d configs/desktop && test -d configs/server
test -f configs/desktop/.config/alacritty/shared.toml
test -f configs/desktop/macos/.config/alacritty/alacritty.toml
test -f configs/desktop/macos/.config/ghostty/config
test -f configs/desktop/linux/.config/alacritty/alacritty.toml
test -f configs/server/.bash_server
test ! -d configs/macos
test ! -d configs/linux

# 旧 install 脚本已删
test ! -f macos_install.sh && test ! -f linux_install.sh

# 新库到位
test -f scripts/profile-common.sh
test -f scripts/profile-desktop.sh
test -f scripts/profile-server.sh

# 语法
bash -n install.sh
bash -n scripts/profile-common.sh
bash -n scripts/profile-desktop.sh
bash -n scripts/profile-server.sh

# install.sh 含 profile dispatch
grep -q 'detect_profile' install.sh
grep -q 'macos-desktop\|ubuntu-desktop\|ubuntu-server' install.sh

# bashrc 仍然引用 bash_server（P0 改动保留）
grep -q bash_server configs/common/.bashrc

# 文档同步
grep -q 'desktop/' README.md
grep -q 'desktop/' docs/DESIGN.md
! grep -q 'macos_install.sh' README.md
! grep -q 'linux_install.sh' README.md

# Profile 模拟自检（不实际执行，只 dry-run 检测）
PROFILE=ubuntu-server bash install.sh --help 2>&1 | grep -q -i 'profile\|server\|desktop'
```

## 约束

- 直接在 master 分支上改，不开新分支
- 用 `git mv` 保留文件 history
- 不动 `configs/common/.bashrc` 实质内容（P0 已修，P1#2 单独处理）
- 不动 `configs/nvim/` 和 nvim 相关脚本
- 不做 `git commit`，改完用户自己 review 后提交
- 保持 install.sh 既有交互式 nvim/claude-hud 提问 UX 不变

## 已知后续工作（不在本设计范围）

- **P1#2**：拆分 `configs/common/.bashrc`，把阿里 GPU 集群特定内容（cdn/cdz/pouch/ossutil）剥到 site 目录
- **P2#2**：HTTPS→SSH 重写规则集中到一处（现在 `.bashrc` 和 install 脚本各设一遍）
- **P2#1 剩余部分**：DESIGN.md 其它过时段落（LSP 表、treesitter parser 版本等）系统性 review
