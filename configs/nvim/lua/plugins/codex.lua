-- Codex CLI 集成
-- ============================================================
--
-- 作用:
--   Visual 模式选中代码后，把文件路径、行号、选中内容和当前仓库根目录
--   发送给 Codex CLI 做一次上下文分析。
--
-- 依赖:
--   - codex CLI
--     安装: icx
--   - toggleterm.nvim
-- ============================================================

local function git_root()
  local cwd = vim.fn.getcwd()
  local root = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and root[1] and root[1] ~= "" then
    return root[1]
  end
  return cwd
end

local function visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]

  if start_line <= 0 or end_line <= 0 then
    return nil
  end
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  return {
    start_line = start_line,
    end_line = end_line,
    text = table.concat(lines, "\n"),
  }
end

local function send_selection_to_codex()
  if vim.fn.executable("codex") ~= 1 then
    vim.notify("未找到 codex CLI。请先运行 icx 安装。", vim.log.levels.ERROR)
    return
  end

  local selection = visual_selection()
  if not selection or selection.text == "" then
    vim.notify("没有可发送给 Codex 的选中内容。", vim.log.levels.WARN)
    return
  end

  local root = git_root()
  local file = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype
  local prompt = table.concat({
    "请基于当前仓库上下文理解下面这段代码。",
    "",
    "请重点说明：",
    "1. 这段代码的职责和执行流程。",
    "2. 它依赖的模块、函数、数据结构或外部环境。",
    "3. 它和当前仓库中其他相关代码的关系。",
    "4. 可能的风险、隐含假设或值得继续阅读的文件。",
    "",
    "Repository root: " .. root,
    "File: " .. file,
    "Filetype: " .. filetype,
    "Lines: " .. selection.start_line .. "-" .. selection.end_line,
    "",
    "```" .. filetype,
    selection.text,
    "```",
  }, "\n")

  local tmp = vim.fn.tempname() .. ".md"
  vim.fn.writefile(vim.split(prompt, "\n", { plain = true }), tmp)

  local command = table.concat({
    "codex exec",
    "--sandbox read-only",
    "-C",
    vim.fn.shellescape(root),
    "-",
    "<",
    vim.fn.shellescape(tmp),
  }, " ")

  local Terminal = require("toggleterm.terminal").Terminal
  Terminal:new({
    cmd = command,
    direction = "vertical",
    size = 90,
    close_on_exit = false,
    hidden = false,
    display_name = "Codex Selection",
  }):toggle()
end

return {
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<leader>x", nil, desc = "Codex" },
      { "<leader>xs", send_selection_to_codex, mode = "v", desc = "发送选中代码给 Codex" },
    },
  },
}
