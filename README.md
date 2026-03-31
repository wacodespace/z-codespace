# dotfiles

个人开发环境配置文件，适用于 Linux 容器环境（AMD ROCm / NVIDIA GPU 开发）。

## 包含文件

- **`.bashrc`** — Shell 配置（别名、PATH、Git 别名、GPU 监控等）
- **`.tmux.conf`** — Tmux 配置（vi 模式、C-a 前缀、鼠标支持等）
- **`.vimrc`** — Vim 配置（缩进、搜索、编码、折叠等，插件已注释）
- **`.bash_private.example`** — 私有配置模板（密钥等，需手动复制填写，不进仓库）
- **`install.sh`** — 安装/卸载脚本（支持 --force、--uninstall、--dry-run）

## 安装与使用

### 快速安装

```bash
git clone git@github.com:wacodespace/dotfiles.git ~/dotfiles && bash ~/dotfiles/install.sh
```

### 脚本选项

```bash
# 正常安装（自动备份）
bash ~/dotfiles/install.sh

# 强制覆盖（不备份）
bash ~/dotfiles/install.sh --force

# 预览模式（只显示操作，不执行）
bash ~/dotfiles/install.sh --dry-run

# 卸载（恢复备份）
bash ~/dotfiles/install.sh --uninstall

# 查看帮助
bash ~/dotfiles/install.sh --help
```

### 安装过程

1. 自动备份已有配置（加时间戳后缀）
2. 创建符号链接指向仓库文件
3. 设置 Git 全局 HTTPS → SSH 重写规则

安装后执行 `source ~/.bashrc` 或重新打开终端即可生效。

### AI CLI 一键安装

`.bashrc` 内置了安装与启动函数，可在新机器上直接安装并启动常用 AI 命令行工具：

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

行为说明：

- `icc`：安装 `Claude Code`
- `icx`：安装 `Codex CLI`
- `cc`：启动 `Claude Code`
- `cx`：启动 `Codex CLI`
- 若系统缺少 `nvm` / `node` / `npm`，会自动安装 `nvm` 并切换到 `Node.js LTS`
- `icc` 优先尝试 Claude 官方原生安装脚本；若脚本因区域限制不可用或返回网页内容，会自动回退到 `npm` 安装
- `icx` 通过 `npm install -g @openai/codex` 安装
- `cc` / `cx` 会把附加参数原样透传给 `claude` / `codex`

首次使用前请先加载配置：

```bash
source ~/.bashrc
```

安装完成后，可分别运行 `claude` 或 `codex` 继续完成登录/认证。

## 私有配置（密钥）

仓库中不存储任何密钥。涉及密钥的配置（如 OSS）通过 `~/.bash_private` 加载，该文件需在每台新机器上手动创建：

```bash
cp ~/dotfiles/.bash_private.example ~/.bash_private
vim ~/.bash_private   # 填入真实密钥
```

`~/.bash_private` 已被 `.gitignore` 排除，不会意外提交到仓库。

## 主要特性

### .bashrc
- 整理后的分组别名（导航、Git、GPU 监控、工具）
- 去重后的 PATH
- Git HTTPS → SSH 自动重写（`git config --global url."git@github.com:".insteadOf "https://github.com/"`)
- docker → pouch 包装函数
- `icc` / `icx` 一键安装 Claude Code 与 Codex CLI
- `cc` / `cx` 快速启动 Claude Code 与 Codex CLI
- 自动补齐 `nvm`、`Node.js LTS` 与 `npm` 运行环境

### .tmux.conf
- `C-a` 前缀键
- vi 模式 + hjkl 面板导航
- Alt+h/l 窗口切换
- 鼠标支持
- 分屏/新窗口保持当前路径
- 清爽的状态栏

### .vimrc
- `;` 作为 Leader 键（`;q` 退出、`;w` 保存、`;l` 取消高亮）
- 4 空格缩进、Tab 展开为空格
- UTF-8 编码自动识别
- 语法折叠（默认不折叠）
- Tab/尾部空格可视化
- 插件部分已注释（vim-plug + gruvbox + NERDTree + airline）
