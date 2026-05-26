# dots-windows

Windows-side dotfiles. Companion to [dots-macos](https://github.com/simingf/dots-macos).
Native PowerShell setup (no WSL).

## Apply

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

`apply.ps1` does, in order: symlinks → `RIPGREP_CONFIG_PATH` → winget installs (Git, gh, Neovim, ripgrep, fd, lazygit, oh-my-posh, VS Code, zoxide, eza, fzf, PS7) → JetBrainsMono Nerd Font → PSFzf module → baseline `git config` → VS Code extensions. It's idempotent — re-running is cheap.

Flags:
- `-LinksOnly` — skip everything past env vars (the fast re-run path)
- `-GitUserName "Name"` / `-GitUserEmail "email"` — pre-fill git identity

Only steps left manual after a successful run: `gh auth login` (interactive browser flow) and a shell restart for the new `$PROFILE` to load.

Symlinks need Developer Mode on, or run the script as admin.

## Layout

One top-level directory per app. The symlink script maps each into its Windows install path:

| Repo path                      | Windows install path                                  |
| ------------------------------ | ----------------------------------------------------- |
| `nvim/`                        | `%LOCALAPPDATA%\nvim\`                                |
| `powershell/profile.ps1`       | `$PROFILE.CurrentUserAllHosts`                        |
| `ohmyposh/zen.toml`            | loaded from the PowerShell profile via `oh-my-posh init pwsh --config ...` |
| `gh/config.yml`                | `%APPDATA%\GitHub CLI\config.yml`                     |
| `ripgrep/rg.conf`              | location set by `$env:RIPGREP_CONFIG_PATH`            |
| `lazygit/config.yml`           | `%APPDATA%\lazygit\config.yml`                        |
| `vscode/settings.json`         | `%APPDATA%\Code\User\settings.json`                   |
| `vscode/keybindings.json`      | `%APPDATA%\Code\User\keybindings.json`                |
| `claude/CLAUDE.md`             | `%USERPROFILE%\.claude\CLAUDE.md`                     |
| `windowsterminal/settings.json`| `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |

## Sync contract with dots-macos

dots-macos is the source of truth. Refresh shared files with plain `cp` on macOS:

```bash
cp -r ~/dots-macos/.config/nvim/*                                  ~/dots-windows/nvim/
cp    ~/dots-macos/.config/ohmyposh/zen.toml                       ~/dots-windows/ohmyposh/
cp    ~/dots-macos/.config/gh/config.yml                           ~/dots-windows/gh/
cp    ~/dots-macos/.config/ripgrep/rg.conf                         ~/dots-windows/ripgrep/
cp    "$HOME/dots-macos/Library/Application Support/lazygit/config.yml"        ~/dots-windows/lazygit/
cp    "$HOME/dots-macos/Library/Application Support/Code/User/settings.json"   ~/dots-windows/vscode/
cp    "$HOME/dots-macos/Library/Application Support/Code/User/keybindings.json" ~/dots-windows/vscode/
cp    ~/dots-macos/.claude/CLAUDE.md                               ~/dots-windows/claude/
```

`powershell/profile.ps1` is a hand-translated subset of `dots-macos/.zshrc` — sync changes manually, not via `cp`. The file's header comment lists what was intentionally skipped (Homebrew, eza/trash/pbcopy, tmux, Sapling, conda/nvm, etc.).

## Not ported from dots-macos

- `.zshrc`, `.tmux.conf` — PowerShell setup; no zsh/tmux on native Windows
- `kitty/`, `ghostty/`, `aerospace/`, `karabiner/`, `borders/`, `linearmouse/`, `portpal/` — macOS-only
- `Brewfile`, `scripts/`, `manual/` — macOS-only tooling
- `.gitconfig` — too many macOS-specific paths (GCM, Homebrew gh, /Users/sfeng); write fresh
- `Library/Preferences/sapling/` — macOS-only

## Gotchas

**Keep `.ps1` files pure ASCII.** Windows PowerShell 5.1 reads scripts as the OS ANSI codepage unless the file has a UTF-8 BOM. Any em-dash (`—`), box-drawing char (`─`), or other non-ASCII byte gets mis-decoded and the parser then throws confusing _"missing closing bracket"_ errors a few lines later. Check before committing:

```bash
LC_ALL=C grep -nP '[^\x00-\x7f]' scripts/apply.ps1 powershell/profile.ps1
```

(macOS editors tend to strip BOMs on save, so just sticking to ASCII is the durable fix.)

## TODO

- [ ] Decide whether a checked-in Windows `.gitconfig` is worth it (currently configured manually per `apply.ps1` step 4)
- [ ] Port more `.zshrc` functions as the need arises — they're easier to translate one-at-a-time than guess up front
