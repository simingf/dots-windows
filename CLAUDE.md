# dots-windows — Claude Instructions

Personal Windows dotfiles. **`~/dots-macos` is the source of truth** — for the canonical sync contract and doc-structure rules, see `~/dots-macos/CLAUDE.md`.

For repo layout, bootstrap, and concepts (ASCII-only PowerShell, LF line endings, what's not ported), see [`README.md`](./README.md).

## Behavior

Route file edits by sync class:

- **Byte-identical** with Mac (`AppData/Local/nvim/`, `AppData/Roaming/Code/User/*.json`, `AppData/Roaming/lazygit/config.yml`, `AppData/Roaming/GitHub CLI/config.yml`, `.config/ohmyposh/zen.toml`, `.config/ripgrep/rg.conf`, `.config/yazi/`, `.config/git/{common.inc,ignore}`, `.claude/CLAUDE.md`, `.claude/statusline-command.sh`, `.claude/themes/rose-pine.json`): edit the Mac source, never this repo's copy. Run `~/dots-macos/scripts/sync-dotfiles.py --apply` in the same task.
- **Partial** (`Documents/PowerShell/Profile.ps1`): edit here. If generic enough for Mac too, also add it to the shared zsh modules in `~/dots-macos/.config/zsh/` — translate PowerShell→zsh.
- **Windows-only** (`AppData/Local/Packages/Microsoft.WindowsTerminal_…/`, `scripts/apply.ps1`, `.claude/settings.json`, `.gitattributes`): edit here. `.claude/settings.json` is a minimal Windows-only file (status line + theme) — the Mac one carries the work MCP allowlist, so never sync it.

**Never run git operations against this repo from the Mac** — see Constraints.

## Sync workflow (run from the Mac)

```bash
~/dots-macos/scripts/sync-dotfiles.py --apply    # byte-identical files
```

User commits/pushes from the **Windows box** (not the Mac — see constraints).

## Windows-side partials

- **`Documents/PowerShell/Profile.ps1`** — hand-translated subset of the `~/dots-macos/.config/zsh/` modules (shared ones: `50-aliases`, `60-functions`, `80-tools`, `00-env`). When mirroring a shared alias/function: translate zsh→PowerShell, skip Mac-only tools (`trash`, homebrew, tmux, conda/nvm) and all work-only helpers (sapling `sup`, work repo helpers). The rose-pine `LS_COLORS`, `FZF_DEFAULT_OPTS`, and PSReadLine colors are hand copies of `00-env.zsh` / `80-tools.zsh` — re-copy when the palette changes. Profile header documents intentional skips. eza is installed via winget (see apply.ps1) and aliased in the profile.

## Constraints

- **No work content.** This repo is public on github.com/simingf. No Roblox code, paths, hostnames, screenshots.
- **No git operations from the Mac.** Roblox's Silencer MITM proxy intercepts `github.com` TLS and forcibly auths as the work GitHub identity, which 403s on `simingf/*` repos. Edit files locally; user pushes from the Windows box.

## Editing conventions

- **`.ps1` files: pure ASCII only.** Windows PowerShell 5.1 mis-decodes non-ASCII bytes and throws confusing parser errors lines later (see README's check command).
- **Byte-identical files: LF line endings.** Don't let editors re-save as CRLF.
- **nvim runtime guards** (`lua/config/env.lua`): `IS_SSH` (false on Windows) and `HAS_DOTNET` (false unless dotnet on PATH).

When changing the sync workflow, doc structure, or shared editing conventions, propagate to all 3 repos.
