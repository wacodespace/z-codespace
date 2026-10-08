# AGENTS.md

Shared instructions for every coding agent working in this repo: Codex, Grok, Claude Code
(via `CLAUDE.md`, which imports this file), and others.

z-codespace is a dotfiles / dev-environment repo. `install.sh` symlinks `configs/` and
`skills/` into `$HOME` per profile (macos-desktop, ubuntu-desktop, ubuntu-server).

## Shared skills

`skills/<name>/SKILL.md` is the single source for every agent's skills. `install.sh`
(or `install.sh --skills` on its own) symlinks each skill directory into:

| Path | Read by |
|---|---|
| `~/.agents/skills/<name>` | Codex, Grok |
| `~/.claude/skills/<name>` | Claude Code |

Executables in `skills/<name>/bin/` are symlinked into `~/.local/bin`.

Those paths are symlinks, so editing a skill through any of them edits the file in this repo.

Rules:
- **Keep skills current.** When you work on a task a skill covers and find something it
  gets wrong or leaves out (a new pitfall, a changed command, a better approach), update
  that `SKILL.md` (and its `bin/` tools) in the same session. Then tell the user what you
  changed and why.
- **Edit the repo copy**, never a standalone copy somewhere else. Don't create
  agent-specific copies under `.claude/skills`, `.codex/skills`, `.grok/skills`, etc.
- **A new skill** goes in `skills/<kebab-name>/SKILL.md`, with `name` and `description`
  frontmatter. Then run `bash install.sh --skills` to link it.
- Write skills in English, and keep them agent-neutral. Don't rely on tools or slash
  commands that only one agent has.

## Repo conventions

- Commit messages are in English, imperative mood, one logical change per commit.
- Don't commit or push unless the user asks. Leave unrelated uncommitted changes alone.
- Never commit secrets or machine-specific files. `.bash_private`,
  `configs/site/ssh_config.site`, `**/.claude/settings.local.json` and auth/token files are
  all off-limits (see `.gitignore`).
- Shell scripts must work with the bash on both macOS and Linux. Use the helpers in
  `scripts/lib.sh` (`safe_link`, `log_*`, `detect_os`).
