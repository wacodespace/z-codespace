# 开发环境配置管理

这个仓库包含了 macOS 本地开发环境和 Linux 服务器环境的配置文件和安装脚本。

## 🎯 支持的平台

### macOS 本地开发环境

- 终端模拟器配置（Alacritty、Ghostty）
- 开发工具配置（Vim、Tmux）
- Shell 环境（Bash）
- 包管理器（Homebrew）

### Linux 服务器环境

- 服务器优化配置
- SSH 会话优化
- 基础开发工具安装
- 性能监控工具

## 🚀 快速开始

### macOS 安装

```bash
# 克隆仓库
git clone https://github.com/wacodespace/z-codespace.git
cd z-codespace

# 运行 macOS 安装脚本
./macos_install.sh

# 或强制覆盖（不备份）
./macos_install.sh --force
```

### Linux 服务器安装

```bash
# 克隆仓库
git clone https://github.com/wacodespace/z-codespace.git
cd z-codespace

# 运行 Linux 安装脚本
./linux_install.sh

# 或强制覆盖（不备份）
./linux_install.sh --force
```

## 📁 目录结构

```text
dotfiles/
├── configs/
│   ├── common/               # 通用配置
│   │   ├── .bashrc          # Bash 配置（含平台检测）
│   │   ├── .vimrc           # Vim 配置
│   │   └── .tmux.conf       # Tmux 配置
│   ├── macos/               # macOS 特定配置
│   │   └── .config/
│   │       ├── alacritty/
│   │       │   └── alacritty.toml
│   │       └── ghostty/
│   │           └── config
│   └── linux/               # Linux 特定配置
│       └── .bash_server     # 服务器专用配置
├── macos_install.sh          # macOS 安装脚本
├── linux_install.sh          # Linux 安装脚本
├── install.sh                # 原始安装脚本（兼容性）
└── README.md                 # 本文档
```

## ⚙️ 配置说明

### 通用配置

#### .bashrc

- 跨平台别名（macOS/Linux）
- Git 快捷键
- 开发工具配置
- 平台特定功能自动检测
- AI CLI 工具集成（Claude Code、Codex）

#### .vimrc

- 语法高亮
- 行号显示
- 搜索配置
- 缩进设置
- `;` 作为 Leader 键

#### .tmux.conf

- `C-a` 前缀键
- vi 模式 + hjkl 面板导航
- 鼠标支持
- 分屏保持当前路径

### macOS 特定

#### Alacritty 配置

- Monokai 配色主题
- 透明度设置
- 字体优化（Menlo 19pt）

#### Ghostty 配置

- 与 Alacritty 相同的配色
- 原生 macOS 集成
- 性能优化

### Linux 服务器特定

#### .bash_server

- SSH 会话优化
- 服务器监控别名
- 安全操作提醒
- 快速导航命令

## 🛠️ 功能特性

### macOS

- ✅ 自动安装 Homebrew
- ✅ 自动安装终端应用
- ✅ GUI 终端配置
- ✅ 原生体验优化

### Linux

- ✅ 自动检测包管理器
- ✅ 自动安装基础工具
- ✅ SSH 环境优化
- ✅ 服务器性能监控

## 💡 使用提示

### 备份机制

- 安装脚本会自动备份现有配置
- 备份文件格式：`.bak.YYYYMMDDHHMMSS`
- 使用 `--force` 可跳过备份

### AI CLI 工具

```bash
# 安装 Claude Code
icc

# 安装 Codex CLI
icx

# 启动 Claude Code
cc

# 启动 Codex CLI
cx
```

### 私有配置

```bash
# 复制模板并填写密钥
cp ~/z-codespace/.bash_private.example ~/.bash_private
vim ~/.bash_private
```
