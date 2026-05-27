# dots-windows — Claude Instructions

Personal Windows dotfiles. **`~/dots-macos` is the source of truth**; this repo mirrors a subset.

For repo layout, bootstrap, and concepts (ASCII-only PowerShell, LF line endings, what's not ported), see [`README.md`](./README.md). For the canonical sync contract, see `~/dots-macos/CLAUDE.md`.

## Behavior

When the user asks you to edit a file in this repo, route based on its sync class:

- **Byte-identical** with Mac (`nvim/`, `vscode/*.json`, `lazygit/config.yml`, `ohmyposh/zen.toml`, `gh/config.yml`, `ripgrep/rg.conf`): edit `~/dots-macos/<path>` instead — never this repo's copy. Then run `~/dots-macos/scripts/sync-dotfiles.py --apply` as part of the same task.
- **Partial** (`powershell/profile.ps1`, `claude/CLAUDE.md`): edit here. If the change is generic enough to belong on Mac too, also edit `~/dots-macos/<path>` — translating zsh→PowerShell or dropping Roblox-specific bits as appropriate.
- **Windows-only** (`windowsterminal/`, `scripts/apply.ps1`): edit here.

Default: shared files must stay aligned. Don't end a task that touched a byte-identical file without running the sync script. **Never run git operations against this repo from the Mac** — see Constraints.

## Sync workflow (run from the Mac)

When the user says **"sync dotfiles"**:

```bash
~/dots-macos/scripts/sync-dotfiles.py --apply    # byte-identical files
```

The user commits/pushes from the **Windows box**, not the Mac (see constraints below).

## Windows-side partials

The sync script only handles byte-identical files. Two files in this repo intentionally diverge from Mac and require LLM judgment to mirror:

- **`powershell/profile.ps1`** — hand-translated subset of `~/dots-macos/.zshrc`. When mirroring a new shared alias/function: translate zsh→PowerShell, skipping Mac-only tools (`eza`, `trash`, `pbcopy`, oh-my-posh, homebrew, tmux, sapling, conda/nvm). The file's header documents what was intentionally skipped.
- **`claude/CLAUDE.md`** — the global Claude config. Roblox-specific bits (Sapling, Silencer, github.rbx.com paths, work role line) live only on Mac; Windows uses `Set-Clipboard` instead of `pbcopy`. When mirroring shared rules, drop the work-only sections and substitute Windows equivalents.

## Constraints

- **No work content.** This repo is public on github.com/simingf. Roblox code, paths, hostnames, screenshots, etc. must not appear here.
- **No git operations from the Mac.** No `commit` / `push` / `pull` / `fetch` from this Mac on this repo. Roblox's Silencer MITM proxy intercepts `github.com` TLS and forcibly auths as the work GitHub identity, which 403s on `simingf/*` repos. Edit files locally; the user pushes from the Windows box.

## Editing conventions

- **`.ps1` files: pure ASCII only.** Windows PowerShell 5.1 mis-decodes non-ASCII bytes and throws confusing parser errors lines later (see README's "ASCII-only PowerShell scripts" for the check command).
- **Byte-identical files: LF line endings.** Don't let editors re-save as CRLF.
- **`init.lua` runtime guards**: `IS_SSH` (false on Windows) and `HAS_DOTNET` (false unless dotnet is on PATH). The same `init.lua` works on Mac, Linux dev box, and Windows.

## Doc structure (keep aligned with siblings)

This repo has both `README.md` (human-facing overview) and `CLAUDE.md` (operational rules). The split policy is canonical in `~/dots-macos/CLAUDE.md`. In short:

- README: summary + sibling refs, bootstrap, layout (path-mapping table), "Things you can ask Claude", concepts (ASCII-only, LF endings, what's not ported), TODO.
- CLAUDE.md: source-of-truth pointer, sync workflow + commands, Windows-specific partials (the LLM-judgment files), constraints (no work content, no git from Mac), editing conventions, this doc-structure section.

When you make a change that affects sync or doc structure, update both files here AND propagate the matching changes to `~/dots-macos` and `~/dots-linux`.
