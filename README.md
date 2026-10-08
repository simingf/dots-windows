# dots-windows

Personal Windows dotfiles. Mirrors a subset of `~/dots-macos`. Native PowerShell setup (no WSL).

Operational details (sync workflow, constraints, editing conventions) live in [`CLAUDE.md`](./CLAUDE.md).

## Sibling repos

- [dots-macos](https://github.com/simingf/dots-macos) — **source of truth**, all sync flows from there.
- [dots-linux](https://github.rbx.com/Roblox/dots-linux) — Coder Linux dev boxes (work).

## Bootstrap

A fresh Windows install has no git. Bootstrap it via winget first, then close and reopen PowerShell so `git` lands on PATH:

```powershell
winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
```

Then clone and run:

```powershell
git clone <this-repo> $env:USERPROFILE\dots-windows
cd $env:USERPROFILE\dots-windows
.\scripts\apply.ps1
```

If PowerShell complains _"running scripts is disabled on this system"_, set the execution policy once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

`apply.ps1` does, in order: symlinks (incl. `.config/git/ignore`) → `RIPGREP_CONFIG_PATH` → `YAZI_CONFIG_HOME` / `YAZI_FILE_ONE` → winget installs (Git, gh, Neovim, ripgrep, fd, lazygit, oh-my-posh, VS Code, zoxide, eza, fzf, yazi, glow, jq, PS7) → JetBrainsMono Nerd Font → PSFzf module → baseline `git config` (incl. `include.path` → `.config/git/common.inc`) → VS Code extensions. Idempotent — re-running is cheap.

Flags:

- `-LinksOnly` — skip everything past env vars (the fast re-run path).
- `-GitUserName "Name"` / `-GitUserEmail "email"` — pre-fill git identity.

Manual after a successful run: `gh auth login` (interactive browser flow), shell restart for the new `$PROFILE` to load. Symlinks need Developer Mode on, or run `apply.ps1` as admin.

## Layout

The repo mirrors `%USERPROFILE%`: each file lives at the same path it'll occupy on the Windows box, so the symlink script (`scripts/apply.ps1`) maps `$Repo\<path>` → `$env:USERPROFILE\<path>`. A few `.config/` files aren't symlinked at all — they're read straight from the repo via env var, `Profile.ps1`, or git `include.path` (marked "not installed" below).

| Repo path                                                                                          | Windows install path                                              |
| -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `AppData/Local/nvim/`                                                                              | `%LOCALAPPDATA%\nvim\`                                            |
| `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`          | same (under `%LOCALAPPDATA%`); copied not symlinked               |
| `AppData/Roaming/Code/User/{settings,keybindings}.json`                                            | same (under `%APPDATA%`)                                          |
| `AppData/Roaming/GitHub CLI/config.yml`                                                            | same (under `%APPDATA%`)                                          |
| `AppData/Roaming/lazygit/config.yml`                                                               | same (under `%APPDATA%`)                                          |
| `Documents/PowerShell/Profile.ps1`                                                                 | same (under `%USERPROFILE%`); also linked to `WindowsPowerShell\profile.ps1` for PS5.1 |
| `.claude/CLAUDE.md`                                                                                | same (under `%USERPROFILE%`); global Claude Code config           |
| `.claude/statusline-command.sh`                                                                    | same (under `%USERPROFILE%`); Claude Code status-line renderer    |
| `.claude/settings.json`                                                                            | same (under `%USERPROFILE%`); Windows-only - wires the status line + rose-pine theme (no work MCP allowlist) |
| `.claude/themes/rose-pine.json`                                                                    | same (under `%USERPROFILE%`); Claude Code custom theme |
| `.config/yazi/`                                                                                    | same (under `%USERPROFILE%`); `YAZI_CONFIG_HOME` points here |
| `.config/git/common.inc`                                                                           | not installed - pulled into global git config via `include.path` (pull/push defaults + rose-pine colors) |
| `.config/git/ignore`                                                                               | same (under `%USERPROFILE%`); git's default global excludesfile |
| `.config/ohmyposh/zen.toml`                                                                        | not installed - loaded from `Profile.ps1` via `oh-my-posh init pwsh --config $Repo\.config\ohmyposh\zen.toml` |
| `.config/ripgrep/rg.conf`                                                                          | not installed - `RIPGREP_CONFIG_PATH` env var points at `$Repo\.config\ripgrep\rg.conf` |

## Things you can ask Claude (run from the Mac)

- **"sync my dotfiles"** — runs `~/dots-macos/scripts/sync-dotfiles.py --apply` (byte-identical files).
- **"port this Mac alias to Windows"** — translate a change in the `~/dots-macos/.config/zsh/` modules into PowerShell inside `Documents/PowerShell/Profile.ps1`, skipping Mac-only tools and anything work-related.

Git operations on this repo happen on the Windows box, not the Mac (Silencer MITM proxy intercepts `github.com` TLS) — Claude on the Mac edits files only; the user pushes from Windows.

## Concepts

### ASCII-only PowerShell scripts

Windows PowerShell 5.1 reads `.ps1` files as the OS ANSI codepage unless the file has a UTF-8 BOM. Any em-dash (`—`), box-drawing char (`─`), or other non-ASCII byte gets mis-decoded and the parser throws confusing _"missing closing bracket"_ errors a few lines later. Check before committing:

```bash
LC_ALL=C grep -nP '[^\x00-\x7f]' scripts/apply.ps1 Documents/PowerShell/Profile.ps1
```

(macOS editors tend to strip BOMs on save, so just sticking to ASCII is the durable fix.)

### LF line endings

The byte-identical files are stored with LF endings (Mac side normalized). Don't let Windows re-save them as CRLF — it would break the byte-identical sync. `.gitattributes` pins `*.sh` to LF so a `core.autocrlf=true` checkout can't break the Git Bash status-line script.

### Not ported from dots-macos

- `.zshrc`, `.config/zsh/`, `.tmux.conf`, tmux scripts, Claude tmux hooks — PowerShell setup; no zsh/tmux on native Windows.
- Work-only shell helpers (`sup`/sapling, `metalg`/`activelg`, `pullrepos`, `ro`) and the Mac `.claude/settings.json` (work MCP allowlist) — this repo stays work-free.
- `kitty/`, `ghostty/`, `aerospace/`, `karabiner/`, `borders/`, `linearmouse/`, `portpal/` — macOS-only.
- `Brewfile`, `manual/` — macOS-only.
- `.gitconfig` — credentials are platform-specific; `apply.ps1` writes the Windows bits and includes the shared `.config/git/common.inc`.
- `Library/Preferences/sapling/` — macOS-only.

## TODO

- [ ] Port more zsh-module functions as the need arises — easier to translate one-at-a-time than guess up front.
