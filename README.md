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

`apply.ps1` does, in order: symlinks → `RIPGREP_CONFIG_PATH` → winget installs (Git, gh, Neovim, ripgrep, fd, lazygit, oh-my-posh, VS Code, zoxide, eza, fzf, PS7) → JetBrainsMono Nerd Font → PSFzf module → baseline `git config` → VS Code extensions. Idempotent — re-running is cheap.

Flags:

- `-LinksOnly` — skip everything past env vars (the fast re-run path).
- `-GitUserName "Name"` / `-GitUserEmail "email"` — pre-fill git identity.

Manual after a successful run: `gh auth login` (interactive browser flow), shell restart for the new `$PROFILE` to load. Symlinks need Developer Mode on, or run `apply.ps1` as admin.

## Layout

One top-level directory per app. The symlink script (`scripts/apply.ps1`) maps each into its Windows install path:

| Repo path                      | Windows install path                                  |
| ------------------------------ | ----------------------------------------------------- |
| `nvim/`                        | `%LOCALAPPDATA%\nvim\`                                |
| `powershell/profile.ps1`       | `$PROFILE.CurrentUserAllHosts`                        |
| `ohmyposh/zen.toml`            | loaded from PowerShell profile via `oh-my-posh init pwsh --config ...` |
| `gh/config.yml`                | `%APPDATA%\GitHub CLI\config.yml`                     |
| `ripgrep/rg.conf`              | location set by `$env:RIPGREP_CONFIG_PATH`            |
| `lazygit/config.yml`           | `%APPDATA%\lazygit\config.yml`                        |
| `vscode/settings.json`         | `%APPDATA%\Code\User\settings.json`                   |
| `vscode/keybindings.json`      | `%APPDATA%\Code\User\keybindings.json`                |
| `claude/CLAUDE.md`             | `%USERPROFILE%\.claude\CLAUDE.md` (global Claude config) |
| `windowsterminal/settings.json`| `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |

## Things you can ask Claude (run from the Mac)

- **"sync my dotfiles"** — runs `~/dots-macos/scripts/sync-dotfiles.py --apply` (byte-identical files).
- **"port this Mac alias to Windows"** — translate a `~/dots-macos/.zshrc` change into PowerShell inside `powershell/profile.ps1`, skipping Mac-only tools.
- **"update the global Claude config"** — hand-mirror `~/dots-macos/.claude/CLAUDE.md` → `claude/CLAUDE.md`, dropping Roblox-specific bits and using `Set-Clipboard` instead of `pbcopy`.

Git operations on this repo happen on the Windows box, not the Mac (Silencer MITM proxy intercepts `github.com` TLS) — Claude on the Mac edits files only; the user pushes from Windows.

## Concepts

### ASCII-only PowerShell scripts

Windows PowerShell 5.1 reads `.ps1` files as the OS ANSI codepage unless the file has a UTF-8 BOM. Any em-dash (`—`), box-drawing char (`─`), or other non-ASCII byte gets mis-decoded and the parser throws confusing _"missing closing bracket"_ errors a few lines later. Check before committing:

```bash
LC_ALL=C grep -nP '[^\x00-\x7f]' scripts/apply.ps1 powershell/profile.ps1
```

(macOS editors tend to strip BOMs on save, so just sticking to ASCII is the durable fix.)

### LF line endings

The byte-identical files are stored with LF endings (Mac side normalized). Don't let Windows re-save them as CRLF — it would break the byte-identical sync.

### Not ported from dots-macos

- `.zshrc`, `.tmux.conf` — PowerShell setup; no zsh/tmux on native Windows.
- `kitty/`, `ghostty/`, `aerospace/`, `karabiner/`, `borders/`, `linearmouse/`, `portpal/` — macOS-only.
- `Brewfile`, `manual/` — macOS-only.
- `.gitconfig` — too many macOS-specific paths (GCM, Homebrew gh, `/Users/sfeng`); written fresh by `apply.ps1`.
- `Library/Preferences/sapling/` — macOS-only.

## TODO

- [ ] Decide whether a checked-in Windows `.gitconfig` is worth it (currently configured manually per `apply.ps1` step).
- [ ] Port more `.zshrc` functions as the need arises — easier to translate one-at-a-time than guess up front.
