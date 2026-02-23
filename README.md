# dotfiles

个人开发环境配置文件，适用于 Linux 容器环境（AMD ROCm / NVIDIA GPU 开发）。

## 包含文件

- **`.bashrc`** — Shell 配置（别名、PATH、Git 别名、GPU 监控等）
- **`.tmux.conf`** — Tmux 配置（vi 模式、C-a 前缀、鼠标支持等）
- **`.vimrc`** — Vim 配置（缩进、搜索、编码、折叠等，插件已注释）
- **`install.sh`** — 一键安装脚本

## 一键安装

```bash
git clone git@github.com:<你的用户名>/dotfiles.git ~/dotfiles && bash ~/dotfiles/install.sh
```

安装脚本会：
1. 自动备份已有的 `~/.bashrc`、`~/.tmux.conf`、`~/.vimrc`（加时间戳后缀）
2. 创建符号链接指向仓库中的配置文件
3. 设置 Git 全局 HTTPS → SSH 重写规则

安装后执行 `source ~/.bashrc` 或重新打开终端即可生效。

## 主要特性

### .bashrc
- 整理后的分组别名（导航、Git、GPU 监控、工具）
- 去重后的 PATH
- Git HTTPS → SSH 自动重写（`git config --global url."git@github.com:".insteadOf "https://github.com/"`)
- docker → pouch 包装函数

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
