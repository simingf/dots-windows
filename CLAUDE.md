# dots-windows — Claude Instructions

Personal Windows dotfiles. **`~/dots-macos` is the source of truth** — for the canonical sync contract and doc-structure rules, see `~/dots-macos/CLAUDE.md`.

For repo layout, bootstrap, and concepts (ASCII-only PowerShell, LF line endings, what's not ported), see [`README.md`](./README.md).

## Behavior

Route file edits by sync class:

- **Byte-identical** with Mac (`AppData/Local/nvim/`, `AppData/Roaming/Code/User/*.json`, `AppData/Roaming/lazygit/config.yml`, `AppData/Roaming/GitHub CLI/config.yml`, `ohmyposh/zen.toml`, `ripgrep/rg.conf`, `.claude/CLAUDE.md`): edit the Mac source, never this repo's copy. Run `~/dots-macos/scripts/sync-dotfiles.py --apply` in the same task.
- **Partial** (`Documents/PowerShell/Profile.ps1`): edit here. If generic enough for Mac too, also edit `~/dots-macos/<path>` — translate zsh→PowerShell.
- **Windows-only** (`AppData/Local/Packages/Microsoft.WindowsTerminal_…/`, `scripts/apply.ps1`): edit here.

**Never run git operations against this repo from the Mac** — see Constraints.

## Sync workflow (run from the Mac)

```bash
~/dots-macos/scripts/sync-dotfiles.py --apply    # byte-identical files
```

User commits/pushes from the **Windows box** (not the Mac — see constraints).

## Windows-side partials

- **`Documents/PowerShell/Profile.ps1`** — hand-translated subset of `~/dots-macos/.zshrc`. When mirroring a shared alias/function: translate zsh→PowerShell, skip Mac-only tools (`eza`, `trash`, `pbcopy`, oh-my-posh, homebrew, tmux, sapling, conda/nvm). Profile header documents intentional skips.

## Constraints

- **No work content.** This repo is public on github.com/simingf. No Roblox code, paths, hostnames, screenshots.
- **No git operations from the Mac.** Roblox's Silencer MITM proxy intercepts `github.com` TLS and forcibly auths as the work GitHub identity, which 403s on `simingf/*` repos. Edit files locally; user pushes from the Windows box.

## Editing conventions

- **`.ps1` files: pure ASCII only.** Windows PowerShell 5.1 mis-decodes non-ASCII bytes and throws confusing parser errors lines later (see README's check command).
- **Byte-identical files: LF line endings.** Don't let editors re-save as CRLF.
- **`init.lua` runtime guards**: `IS_SSH` (false on Windows) and `HAS_DOTNET` (false unless dotnet on PATH).

When changing the sync workflow, doc structure, or shared editing conventions, propagate to all 3 repos.
