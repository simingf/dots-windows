# PowerShell profile, translated from dots-macos/.zshrc.
# Symlinked to $PROFILE.CurrentUserAllHosts by scripts/apply.ps1, so it loads
# in pwsh, Windows PowerShell, and VS Code's integrated terminal.
#
# What was intentionally skipped from the zsh side:
#   - Homebrew shellenv               (no brew on Windows)
#   - eza/trash/pbcopy/kitten aliases (Mac-only tools - eza et al. work if
#                                      installed via scoop/cargo, see below)
#   - tmux helpers (tn/ta/tk/runall)  (no native tmux on Windows)
#   - DEC 2031 / mouse-tracking hooks (ghostty-specific, irrelevant here)
#   - conda / nvm lazy-loaders        (paths differ; add when miniconda/nvm-windows install)

# -- PSReadLine --------------------------------------------------------------
# History: 5000 entries, no dups (mirrors HISTSIZE/hist_ignore_all_dups).
Set-PSReadLineOption -MaximumHistoryCount 5000
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# Closer to `bindkey -e` (zsh emacs mode).
Set-PSReadLineOption -EditMode Emacs

# Replaces zsh-autosuggestions: gray inline ghost text from history + plugins.
# Needs PSReadLine 2.1+ (Source) / 2.2+ (ViewStyle). Windows PowerShell 5.1
# ships with 2.0.0 — skip there. pwsh (PS7) has a new enough version.
$psrl = Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue
if ($psrl.Parameters.ContainsKey('PredictionSource')) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
}
if ($psrl.Parameters.ContainsKey('PredictionViewStyle')) {
    Set-PSReadLineOption -PredictionViewStyle ListView
}

# Mirror zsh keybindings for history search.
Set-PSReadLineKeyHandler -Chord 'Ctrl+p' -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Chord 'Ctrl+n' -Function HistorySearchForward
# Tab cycles through completions (more zsh-ish than the default).
Set-PSReadLineKeyHandler -Chord 'Tab'        -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Shift+Tab'  -Function Complete

# -- Env vars ----------------------------------------------------------------
$env:EDITOR = 'nvim'
$env:RIPGREP_CONFIG_PATH = "$env:USERPROFILE\dots-windows\ripgrep\rg.conf"
Remove-Item env:GH_TOKEN -ErrorAction SilentlyContinue

# -- Prompt (oh-my-posh) -----------------------------------------------------
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:USERPROFILE\dots-windows\ohmyposh\zen.toml" |
        Invoke-Expression
}

# -- Tool integrations -------------------------------------------------------
# zoxide - `cd` becomes the smart jumper (mirror `zoxide init --cmd cd zsh`).
# After the jump, clear screen and re-list — same effect as a zsh chpwd hook.
# zoxide installs `cd` as an alias to __zoxide_z; aliases beat functions in PS
# resolution, so we drop it before defining our wrapper.
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
    Remove-Item alias:cd -Force -ErrorAction SilentlyContinue
    function cd {
        __zoxide_z @args
        Clear-Host
        ls
    }
}

# fzf integration via PSFzf (Ctrl+T file picker, Ctrl+R history fuzzy search).
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' `
                    -PSReadlineChordReverseHistory 'Ctrl+r'
}

# -- Aliases -----------------------------------------------------------------
# `exit` is a language keyword, not a cmdlet — Set-Alias can't target it,
# so wrap in a function. nvim is a real exe so Set-Alias is fine.
function e { exit }
Set-Alias -Name v -Value nvim

# `c`: clear and re-list (mirror dots-linux pattern, not Mac's conda dispatcher).
function c { Clear-Host; ls }

# Open current dir in Explorer (mirror Mac `f='open .'`).
function f { Invoke-Item . }

# Global npm packages (mirror Mac `npmg`).
function npmg { npm list -g --depth 0 }

# Competitive build+run (mirror Mac `cpr='make && ./sol'`).
function cpr {
    make
    if ($LASTEXITCODE -eq 0) { & "./sol" }
}

if (Get-Command btop -ErrorAction SilentlyContinue) { Set-Alias top btop }
if (Get-Command lazygit -ErrorAction SilentlyContinue) { Set-Alias lg lazygit }

# eza if installed (`scoop install eza` / `cargo install eza`).
# PS resolves aliases before functions, so the built-in `ls` alias (for
# Get-ChildItem) shadows our function unless we drop it first.
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza --icons=auto --hyperlink @args }
    function ll { eza -la --git --icons=auto --hyperlink @args }
    function lt { eza --tree --level=2 -a --git-ignore --icons=auto --hyperlink @args }
}

# -- which (mirror zsh) ------------------------------------------------------
# Alias -> target, function -> body, exe -> path, cmdlet -> note.
function which {
    param([Parameter(Mandatory)] [string] $Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) { Write-Error "$Name not found"; return }
    switch ($cmd.CommandType) {
        'Alias'       { "${Name}: aliased to $($cmd.Definition)" }
        'Function'    { "${Name} () {`n$($cmd.Definition)`n}" }
        'Cmdlet'      { "${Name}: cmdlet" }
        'Application' { $cmd.Source }
        default       { "${Name}: $($cmd.CommandType) - $($cmd.Definition)" }
    }
}

# -- Directory navigation ----------------------------------------------------
# Route through `cd` so the zoxide+clear+ls wrapper fires.
function .. { cd .. }
function ... { cd ../.. }

function doc  { cd "$env:USERPROFILE\Documents" }
function dow  { cd "$env:USERPROFILE\Downloads" }
function des  { cd "$env:USERPROFILE\Desktop" }
function dots { cd "$env:USERPROFILE\dots-windows" }
# `cf` on mac jumped to ~/.config; on Windows the closest analog is the dots repo.
function cf   { cd "$env:USERPROFILE\dots-windows" }

# -- Config-edit shortcuts ---------------------------------------------------
# `zrc` kept as the muscle-memory name even though we're editing pwsh's profile.
function zrc { nvim $PROFILE.CurrentUserAllHosts }
function nrc { nvim "$env:LOCALAPPDATA\nvim\init.lua" }
function rs  { Clear-Host; & (Get-Process -Id $PID).Path -NoLogo }   # restart shell
function ch  {
    $h = (Get-PSReadLineOption).HistorySavePath
    if (Test-Path $h) { Remove-Item $h -Force }
    Clear-Host
}

# -- Clipboard ---------------------------------------------------------------
# `pwd` shadows the built-in alias for interactive use (also copies path);
# scripts should use Get-Location directly.
function pwd {
    $p = (Get-Location).Path
    $p | Set-Clipboard
    Write-Output $p
}

# Mac compatibility shims so muscle-memory pipelines work on Windows.
function pbcopy  { $input | Set-Clipboard }
function pbpaste { Get-Clipboard }

# -- Update / upgrade --------------------------------------------------------
if (Get-Command topgrade -ErrorAction SilentlyContinue) {
    function up { topgrade -t -y --no-retry }
}

# -- Editors -----------------------------------------------------------------
# Pick code or cursor via fzf, like the zsh `k` function.
function k {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Error 'fzf not installed'; return
    }
    $editor = "code","cursor" | fzf --height=4 --prompt='editor: '
    if (-not $editor) { return }
    if ($args.Count -eq 0) { & $editor . } else { & $editor @args }
}

# Claude Code with permission prompts off (yolo mode).
function kk { claude --dangerously-skip-permissions @args }

# -- Python shorthand --------------------------------------------------------
function p {
    if ($args.Count -eq 0) { Write-Output 'python: no file given'; return }
    python @args
}

# -- PR fetch (mirror gotopr) ------------------------------------------------
function gotopr {
    param([Parameter(Mandatory)] [string] $Url)
    if ($Url -notmatch 'https://([^/]+)/([^/]+)/([^/]+)/pull/(\d+)') {
        Write-Error "Could not parse URL: $Url"; return
    }
    $h, $org, $repo, $pr = $Matches[1..4]
    Write-Host "==> PR #$pr in $h/$org/$repo"

    $gitRoot = "$env:USERPROFILE\git"
    if (-not (Test-Path $gitRoot)) { New-Item -ItemType Directory $gitRoot | Out-Null }
    Set-Location $gitRoot

    if (Test-Path $repo) {
        Set-Location $repo
        git fetch --prune
    } else {
        git clone "https://$h/$org/$repo.git"
        Set-Location $repo
    }
    gh pr checkout $pr
}
