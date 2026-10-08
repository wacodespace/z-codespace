---
name: codex-account-switch
description: Switch the ChatGPT account that OpenAI Codex (CLI and the ChatGPT/Codex desktop app) is logged in with on macOS, without repeating the browser login. Use when the user has several Codex/ChatGPT subscriptions (e.g. Plus and Pro) and wants to set up, use, or troubleshoot fast account switching, or asks whether CC Switch / CODEX_HOME can do it.
---

# Codex account switching (macOS)

## How it works

Codex stores its ChatGPT login in `$CODEX_HOME/auth.json` (default `~/.codex/auth.json`):
`auth_mode`, `tokens.{id_token, access_token, refresh_token, account_id}`, `last_refresh`.
The CLI and the desktop app read the same file. So each account only has to log in in the browser **once**: save
its `auth.json` as a profile, then switch by swapping that file.

The one non-obvious rule: **refresh tokens rotate.** Each time Codex refreshes, the old
refresh token in a saved copy can stop working. A plain snapshot goes stale, and then
the browser login comes back. The bundled script fixes this by writing the live (refreshed)
`auth.json` back to the outgoing profile before every switch.

## Recommended approach: `scripts/codex-switch`

Install it:

```bash
mkdir -p ~/.local/bin
cp scripts/codex-switch ~/.local/bin/codex-switch
chmod +x ~/.local/bin/codex-switch
```

Make sure `~/.local/bin` is on `PATH`.

One-time setup, run by the user. Each account logs in once in the browser:

```bash
codex-switch login plus    # removes the local auth.json, runs `codex login`, saves it as "plus"
codex-switch login pro     # same for the other account
```

If an account is already logged in, `codex-switch save plus` keeps that login instead of
doing it again.

**Never run `codex logout` to change accounts.** It doesn't just delete the local file: it
also revokes the tokens on OpenAI's side, which kills the saved copy of that profile.
`codex-switch login` only deletes the local file. To do it by hand:
`rm ~/.codex/auth.json && codex login`.

### New device

Run `codex-switch login <name>` once for each account on every device. **Don't copy
profile files from another machine.** Both machines would then share one refresh token,
and since tokens rotate, whichever machine refreshes first makes the other one's copy
invalid. Each device that logs in on its own gets an independent set of tokens.

Daily use:

```bash
codex-switch pro      # or: codex-switch use pro
codex-switch          # current profile + live account email/plan
codex-switch list
```

What the script guarantees:
- It refuses to switch while Codex is running: the `codex` CLI, or the desktop app's
  `Codex Framework` helpers inside ChatGPT.app or Codex.app. A running process keeps tokens
  in memory and can write the old account back over the swapped file. `--force` overrides this.
- Before switching, it writes refreshed tokens back to the outgoing profile, but only if
  the live login's `account_id` matches that profile. If the user ran `codex login` by hand in
  between, the live file is stashed as `~/.codex-profiles/.unsaved-*.json.bak` and no profile gets overwritten.
- `login` writes back the current login first, the same way. If the browser login fails or is
  cancelled, it restores the previous profile, so the user is never left logged out.
- It does atomic writes with mode 0600. Profiles live in `~/.codex-profiles/` (mode 700),
  or in `$CODEX_PROFILES_DIR` if set. It respects `$CODEX_HOME`.
- It never prints tokens. Status shows only email and plan, decoded from `id_token`.

## Alternatives, and when to pick them

| Need | Use |
|---|---|
| Switch between accounts, with shared history/config/MCP | `codex-switch` (default) |
| Two accounts logged in **at the same time** in different terminals | One `CODEX_HOME` per account, e.g. `alias codex-pro='CODEX_HOME=~/.codex-pro codex'`. History and config split per dir, so `config.toml` has to be kept in sync by hand. Awkward for the desktop app. |
| Already use CC Switch for third-party API providers | Keep CC Switch for providers only. It *can* store a ChatGPT `auth.json` per Codex provider, but its snapshots are not kept fresh in the background, so they go stale. Its "Codex App Enhancement / preserve official login" setting deliberately keeps `auth.json` from being overwritten, which conflicts with switching between official accounts. |

## Agent rules

- Never `cat`, echo, log, or commit `auth.json` or profile files. To check which account is
  active, decode only the `email` and `chatgpt_plan_type` claims, or run `codex-switch status`.
- The browser login is the user's job. Hand them `codex-switch login <name>` to run; don't
  automate the login itself.
- Never suggest `codex logout` as a step in switching accounts (see above).
- Before switching, ask the user to quit Codex. Don't kill their processes without asking.
- If a switch lands on a login prompt, that profile's refresh token is dead. Fix it with
  `codex-switch login <name>`, which overwrites the dead profile.
- Don't use this to share one subscription between several people. That breaks OpenAI's
  terms. It is meant for one person switching between their own accounts.
