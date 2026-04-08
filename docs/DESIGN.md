# LazyVim 环境设计文档

## 1. 总体设计目标

### 为什么选择 LazyVim

- **成熟稳定**：LazyVim 是目前 Neovim 生态中最成熟的发行版，维护者活跃，社区庞大
- **结构清晰**：配置分层明确（config/ + plugins/），易于理解和维护
- **合理默认**：开箱即用的 LSP、补全、搜索、Git 集成，无需从零拼装
- **版本锁定**：通过 lazy-lock.json 精确锁定每个插件版本，保证可复现

### 极简稳定策略

- **不追 nightly**：只使用 Neovim stable release（当前 0.10.x）
- **不追新插件**：只保留生产必需插件，不引入实验性功能
- **不默认 AI**：不集成 copilot / claude / codex / avante 等 AI 插件
- **不重度 UI**：不引入重量级 dashboard / 动画 / 主题切换器

### 能力边界

| 保留 | 不做 |
|------|------|
| 文件查找 / 模糊搜索 | AI 代码补全 |
| LSP (补全/跳转/诊断) | 远程开发插件 (SSHEdit) |
| Treesitter 高亮/缩进 | 浏览器预览 |
| Git signs / lazygit | DAP (调试) — 按需后加 |
| 基础状态栏 | 重量级笔记/知识库系统 |
| tmux 无缝导航 | Docker/容器集成 |
| 内嵌终端 | |

### 生产适用性保证

1. 所有插件版本通过 lazy-lock.json 锁定，提交到 Git
2. 升级是显式操作（`:Lazy update`），不会自动发生
3. 离线迁移有明确方案（打包 + 部署脚本）
4. 健康检查脚本可快速排查问题

---

## 2. 目录结构

```text
z-codespace/
├── configs/
│   ├── common/                  # 通用配置（已有）
│   │   ├── .bashrc
│   │   ├── .vimrc
│   │   └── .tmux.conf          # 已增加 nvim 集成
│   ├── macos/                   # macOS 配置（已有）
│   ├── linux/                   # Linux 配置（已有）
│   └── nvim/                    # [新增] LazyVim 配置
│       ├── init.lua             # 入口文件
│       ├── lazyvim.json         # LazyVim extras 声明
│       ├── lazy-lock.json       # 插件版本锁（首次 sync 后生成）
│       └── lua/
│           ├── config/
│           │   ├── lazy.lua     # lazy.nvim 引导
│           │   ├── options.lua  # Neovim 选项
│           │   ├── keymaps.lua  # 自定义快捷键
│           │   └── autocmds.lua # 自动命令
│           └── plugins/
│               ├── editor.lua   # 编辑器增强 (tmux/terminal)
│               ├── lang.lua     # 语言支持 (LSP/格式化)
│               ├── treesitter.lua # Treesitter 配置
│               └── disabled.lua # 明确禁用的插件
├── scripts/                     # [新增] 自动化脚本
│   ├── lib.sh                   # 共享工具函数
│   ├── install-deps.sh          # 安装依赖 (nvim/rg/fd/node...)
│   ├── install-nvim.sh          # 部署 LazyVim 配置
│   ├── uninstall-nvim.sh        # 卸载配置
│   ├── update-nvim.sh           # 更新插件
│   ├── doctor.sh                # 环境健康检查
│   ├── offline-pack.sh          # 创建离线部署包
│   └── offline-deploy.sh        # 离线环境部署
├── docs/                        # [新增] 文档
│   └── DESIGN.md                # 本文档
├── macos_install.sh             # macOS 安装脚本（已有）
├── linux_install.sh             # Linux 安装脚本（已有）
├── install.sh                   # [新增] 统一入口
├── .gitignore
└── README.md
```

---

## 3. 部署原则

### 操作系统检测

```bash
case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
esac
```

Linux 发行版检测通过 `/etc/os-release` 中的 `$ID` 字段判断。

### 依赖检测

所有脚本使用 `command -v <cmd>` 检测命令是否存在，避免依赖 `which`。

### 幂等性保证

- 安装脚本检查已有安装状态，跳过已完成的步骤
- 软链接创建前检查目标是否已是正确链接
- 包管理器安装前检查包是否已安装

### 失败处理

- 所有脚本使用 `set -euo pipefail`
- 每步操作有明确的日志输出
- 错误时给出可读的修复建议

### 非 root 支持

- Neovim 安装到 `~/.local/`（不需要 root）
- 只在安装系统包时使用 sudo（检测 sudo 可用性）
- 如无 sudo 权限，给出手动安装提示

### 避免修改全局状态

- 配置使用软链接指向本仓库
- 二进制安装到 `~/.local/bin`
- 不修改系统级配置文件

---

## 4. 依赖管理

### 必须依赖

| 工具 | 用途 | 阶段 | macOS 安装 | Linux 安装 |
|------|------|------|-----------|-----------|
| git | 插件管理 | 运行时 | brew | apt/dnf/yum |
| curl | 下载 | 安装时 | 系统自带 | apt/dnf/yum |
| unzip/tar | 解压 | 安装时 | 系统自带 | apt/dnf/yum |
| gcc/clang | treesitter 编译 | 安装时 | Xcode CLT | build-essential |
| make | 编译 | 安装时 | Xcode CLT | build-essential |
| ripgrep | telescope 搜索 | 运行时 | brew | apt/dnf/手动 |
| node | LSP (pyright等) | 运行时 | brew | nvm |
| python3 | Python 开发 | 运行时 | brew | apt/dnf/yum |
| neovim | 编辑器 | 运行时 | brew | GitHub release |

### 可选依赖

| 工具 | 用途 | macOS | Linux |
|------|------|-------|-------|
| fd | 文件搜索 (telescope) | brew | apt/dnf/手动 |
| fzf | 命令行模糊搜索 | brew | apt/dnf |
| tmux | 终端复用 | brew | apt/dnf/yum |
| lazygit | Git TUI | brew | 手动 |
| xclip | 剪贴板 (Linux) | N/A | apt/dnf |

### 不需要的

- **luarocks**：LazyVim 不依赖 luarocks，不需要安装
- **pip 全局包**：LSP 通过 mason 或 npm 管理，不需要全局 pip 安装

---

## 5. LazyVim 配置设计

基于 LazyVim Starter 的标准结构，遵循以下原则：

1. **贴近官方**：目录结构完全遵循 LazyVim 约定
2. **配置分层**：config/ 处理基础设置，plugins/ 处理插件
3. **最小覆盖**：只覆盖需要修改的默认值
4. **版本锁定**：lazy-lock.json 提交到 Git

---

## 6. 插件清单

### LazyVim 内置（保留）

| 插件 | 能力 | 外网需求 | 外部二进制 |
|------|------|---------|-----------|
| telescope.nvim | 模糊搜索 | 安装时 | ripgrep, fd |
| nvim-lspconfig | LSP 客户端 | 无 | LSP 服务器 |
| nvim-treesitter | 语法高亮 | 安装时 | gcc/clang |
| gitsigns.nvim | Git 标记 | 安装时 | git |
| mini.surround | 括号操作 | 安装时 | 无 |
| mini.pairs | 自动配对 | 安装时 | 无 |
| mini.comment | 注释 | 安装时 | 无 |
| lualine.nvim | 状态栏 | 安装时 | 无 |
| neo-tree.nvim | 文件浏览 | 安装时 | 无 |
| mason.nvim | LSP 安装 | 安装时 | 无 |
| conform.nvim | 格式化 | 安装时 | 格式化工具 |

### 额外添加

| 插件 | 能力 | 原因 |
|------|------|------|
| vim-tmux-navigator | tmux 无缝导航 | SSH/远程开发必备 |
| toggleterm.nvim | 内嵌终端 | 快速运行命令 |

### 离线迁移适用性

所有插件安装后为本地 Git 仓库，不需要运行时网络。
打包 `~/.local/share/nvim` 即可完成离线迁移。

---

## 7. LSP 与语言支持

### LSP 服务器

| 语言 | LSP | 安装方式 | 离线运行 |
|------|-----|---------|---------|
| Python | pyright | mason/npm | ✅ |
| C/C++ | clangd | **系统包管理器** | ✅ |
| CUDA | clangd | 同上 | ✅ |
| Lua | lua_ls | mason | ✅ |
| Bash | bashls | mason/npm | ✅ |
| JSON | jsonls | mason | ✅ |
| YAML | yamlls | mason | ✅ |
| Markdown | marksman | mason | ✅ |
| TypeScript | tsserver | mason (可选) | ✅ |

### C/C++ 特殊说明

clangd 配置为 `mason = false`，即不通过 mason 安装，而是使用系统的 clangd。

原因：

- GPU 开发环境通常自带 LLVM/clang 工具链
- 系统 clangd 能更好地识别系统头文件和 CUDA 路径
- 减少对 mason 的依赖

### 离线迁移思路

1. 在有网机器通过 mason 安装所有 LSP
2. 打包 `~/.local/share/nvim/mason/` 目录
3. 在目标机器解压到相同路径
4. mason 安装的二进制位于 `~/.local/share/nvim/mason/bin/`

---

## 8. Treesitter 策略

### 安装

- 首次 `nvim --headless '+Lazy! sync' +qa` 时自动编译
- 需要 C 编译器 (gcc/clang)
- 需要网络下载 parser 源码

### 版本锁定

- parser 版本由 nvim-treesitter 插件版本决定
- 通过 lazy-lock.json 锁定 nvim-treesitter 即间接锁定 parser

### 运行时安全

- `auto_install = false`：不自动下载未声明的 parser
- 大文件自动禁用高亮（>512KB）

### 离线迁移

- parser 编译后为 `.so` 文件，位于 `~/.local/share/nvim/lazy/nvim-treesitter/parser/`
- **平台相关**：不能跨架构迁移（x86_64 → arm64）
- 同架构机器间可直接复制

---

## 9. 离线迁移方案

### 需要同步的路径

| 路径 | 内容 | 必须 |
|------|------|------|
| `~/.config/nvim` | 配置文件 | ✅ |
| `~/.local/share/nvim/lazy/` | 插件 Git 仓库 | ✅ |
| `~/.local/share/nvim/mason/` | LSP/格式化工具 | ✅ |
| `~/.local/state/nvim/lazy/` | lazy.nvim 状态 | 推荐 |

### 不建议同步

| 路径 | 原因 |
|------|------|
| `~/.cache/nvim` | 临时缓存，可重建 |
| `~/.local/share/nvim/swap` | swap 文件 |
| `~/.local/share/nvim/shada` | 历史记录，机器相关 |

### 流程

```text
有网机器                          无网机器
─────────                        ─────────
1. install-deps.sh               1. 手动安装 nvim + gcc
2. install-nvim.sh               2. scp 离线包
3. offline-pack.sh ──tar.gz──>   3. tar xzf + deploy.sh
```

---

## 10. macOS 与 Linux 差异

### 统一处理

- Neovim 配置完全相同（configs/nvim/）
- tmux 配置完全相同（configs/common/.tmux.conf）
- 快捷键和插件配置完全相同

### 需要平台分支

| 场景 | macOS | Linux |
|------|-------|-------|
| 包管理器 | brew | apt/dnf/yum/pacman |
| Neovim 安装 | brew install neovim | 下载预编译二进制到 ~/.local |
| C 编译器 | Xcode CLT (clang) | build-essential (gcc) |
| Node.js | brew install node | nvm |
| 剪贴板 | 系统自带 pbcopy | xclip/xsel |
| fd 命令名 | fd | fd-find (Debian/Ubuntu) |

---

## 11. tmux 配合方案

### 设计原则

- 前缀键 `C-a`（与 screen 一致，适合远程）
- vi 模式
- `C-h/j/k/l` 在 tmux pane 和 nvim split 间无缝切换
- `escape-time 10`：避免 nvim 中 Esc 延迟
- `focus-events on`：支持 nvim autoread

### 推荐工作流

```text
┌─ tmux session: dev ────────────────────────────┐
│ ┌─ window 1: editor ─┐ ┌─ window 2: terminal ─┐│
│ │  nvim              │ │  shell               ││
│ │  (C-h/j/k/l 切换)  │ │                      ││
│ └────────────────────┘ └──────────────────────┘│
└────────────────────────────────────────────────┘
```

---

## 12. 未来扩展建议

### AI 插件接入

在 `plugins/` 下创建独立文件（如 `plugins/ai.lua`），不修改现有配置：

```lua
-- plugins/ai.lua (按需创建)
return {
  { "zbirenbaum/copilot.lua", opts = {} },
}
```

### Profile 分层

为不同机器创建 profile 文件：

```text
configs/nvim/lua/plugins/
  ├── editor.lua      # 所有机器
  ├── lang.lua        # 所有机器
  └── local.lua       # .gitignore 中排除，机器特定配置
```

### 增加语言支持

1. 在 `lazyvim.json` 的 extras 中添加对应 extra
2. 在 `treesitter.lua` 的 ensure_installed 中添加 parser
3. 运行 `:Lazy sync` 和 `:TSInstall`

### 升级风险控制

1. 升级前: `git stash` 或创建分支
2. 升级: nvim 中 `:Lazy update`
3. 测试: 确认功能正常
4. 锁定: `git add lazy-lock.json && git commit`
5. 回滚: `git checkout lazy-lock.json && :Lazy sync`

### 版本锁定与回滚

- Neovim 版本: 脚本中 `NVIM_STABLE_VERSION` 变量控制
- 插件版本: lazy-lock.json
- LSP 工具版本: mason lock (手动管理)
