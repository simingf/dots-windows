#Requires -Version 5.1
# Apply dots-windows.
#
# Default: link configs, set env vars, install tools (winget), font, PSFzf,
# baseline git config, VS Code extensions. Idempotent - safe to re-run.
#
# Flags:
#   -LinksOnly                Skip everything except symlinks + env vars.
#   -GitUserName  <name>      `git config --global user.name <name>`
#   -GitUserEmail <email>     `git config --global user.email <email>`
#
# Symlinks need Developer Mode on, or run this script as Administrator.

[CmdletBinding()]
param(
    [switch] $LinksOnly,
    [string] $GitUserName  = '',
    [string] $GitUserEmail = ''
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Info($msg) { Write-Host "    $msg" }
function Warn($msg) { Write-Host "!!  $msg" -ForegroundColor Yellow }

# -- 0. Precheck: can we create symlinks? ------------------------------------
function Test-CanSymlink {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if ($isAdmin) { return $true }
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    $val = (Get-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
    return ($val -eq 1)
}

if (-not (Test-CanSymlink)) {
    Write-Host ""
    Warn "Cannot create symlinks: not running as Administrator and Developer Mode is off."
    Warn "Pick one, then re-run apply.ps1:"
    Warn "  1. (recommended) Settings > System > For developers > Developer Mode = On"
    Warn "  2. Close this window, right-click PowerShell, Run as administrator"
    exit 1
}

function New-Link {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Target
    )
    if (-not (Test-Path -LiteralPath $Source)) {
        Warn "Source missing, skipping: $Source"
        return
    }
    $parent = Split-Path -Parent $Target
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (Test-Path -LiteralPath $Target) {
        $existing = Get-Item -LiteralPath $Target -Force
        if ($existing.LinkType -eq 'SymbolicLink' -and $existing.Target -contains $Source) {
            Info "OK    $Target"
            return
        }
        $backup = "$Target.bak"
        Warn "Backing up $Target -> $backup"
        Move-Item -LiteralPath $Target -Destination $backup -Force
    }
    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
        Info "Linked $Target -> $Source"
    } catch {
        Warn "Failed to link ${Target}: $($_.Exception.Message)"
        Warn "Enable Developer Mode (Settings > For developers) or run as Administrator, then re-run."
        throw
    }
}

# -- 1. Symlinks -------------------------------------------------------------
Step "Repo: $Repo"

Step "Symlinks"
New-Link -Source "$Repo\nvim"                      -Target "$env:LOCALAPPDATA\nvim"
New-Link -Source "$Repo\vscode\settings.json"      -Target "$env:APPDATA\Code\User\settings.json"
New-Link -Source "$Repo\vscode\keybindings.json"   -Target "$env:APPDATA\Code\User\keybindings.json"
New-Link -Source "$Repo\gh\config.yml"             -Target "$env:APPDATA\GitHub CLI\config.yml"
New-Link -Source "$Repo\lazygit\config.yml"        -Target "$env:APPDATA\lazygit\config.yml"
New-Link -Source "$Repo\claude\CLAUDE.md"          -Target "$env:USERPROFILE\.claude\CLAUDE.md"
New-Link -Source "$Repo\powershell\profile.ps1"    -Target $PROFILE.CurrentUserAllHosts

# -- 2. Env vars -------------------------------------------------------------
Step "Env vars (User scope)"
$rgPath = Join-Path $Repo 'ripgrep\rg.conf'
[Environment]::SetEnvironmentVariable('RIPGREP_CONFIG_PATH', $rgPath, 'User')
Info "RIPGREP_CONFIG_PATH = $rgPath"

if ($LinksOnly) {
    Write-Host ""
    Step "Done (LinksOnly)"
    return
}

# -- 3. winget tools ---------------------------------------------------------
function Winget-Install {
    param([Parameter(Mandatory)] [string] $Id)
    & winget install --id $Id --silent --accept-source-agreements --accept-package-agreements 2>&1 |
        Out-Null
    # Exit codes: 0 = installed, -1978335135 = already installed, -1978335189 = no upgrade
    if ($LASTEXITCODE -eq 0 -or
        $LASTEXITCODE -eq -1978335135 -or
        $LASTEXITCODE -eq -1978335189) {
        Info "OK    $Id"
    } else {
        Warn "winget install $Id failed (exit $LASTEXITCODE) - continuing"
    }
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Warn "winget not found - skipping tool installs."
    Warn "Install App Installer from Microsoft Store, then re-run."
} else {
    Step "winget tools"
    @(
        'Microsoft.PowerShell',         # PS7 (skip if you only want WinPS 5.1)
        'Git.Git',
        'GitHub.cli',
        'Neovim.Neovim',
        'BurntSushi.ripgrep.MSVC',
        'sharkdp.fd',
        'JesseDuffield.lazygit',
        'JanDeDobbeleer.OhMyPosh',
        'Microsoft.VisualStudioCode',
        'ajeetdsouza.zoxide',
        'eza-community.eza',
        'junegunn.fzf'
    ) | ForEach-Object { Winget-Install $_ }

    # winget put binaries on PATH (in registry), but the running session still
    # has the pre-install PATH. Refresh from User+Machine so the next steps
    # can find oh-my-posh, git, code, etc.
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' +
                [Environment]::GetEnvironmentVariable('PATH','User')
}

# -- 4. Nerd Font ------------------------------------------------------------
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Step "JetBrainsMono Nerd Font"
    & oh-my-posh font install JetBrainsMono 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Info "OK" }
    else { Warn "oh-my-posh font install failed (exit $LASTEXITCODE)" }
} else {
    Warn "oh-my-posh not on PATH yet - open a new shell after winget step, then re-run."
}

# -- 5. PowerShell modules ---------------------------------------------------
Step "PowerShell modules"
if (-not (Get-Module -ListAvailable -Name PSFzf)) {
    if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    Install-Module PSFzf -Scope CurrentUser -Force
    Info "Installed PSFzf"
} else {
    Info "OK    PSFzf"
}

# -- 6. git baseline config --------------------------------------------------
if (Get-Command git -ErrorAction SilentlyContinue) {
    Step "git config (global)"
    git config --global push.autoSetupRemote true
    git config --global credential.helper manager
    # Per-host gh credential helpers
    git config --global 'credential.https://github.com.helper'      '!gh auth git-credential'
    git config --global 'credential.https://gist.github.com.helper' '!gh auth git-credential'

    if (-not $GitUserName) {
        $existing = git config --global --get user.name
        if ($existing) {
            Info "user.name already set: $existing"
        } else {
            $GitUserName = Read-Host '    git user.name  (blank to skip)'
        }
    }
    if (-not $GitUserEmail) {
        $existing = git config --global --get user.email
        if ($existing) {
            Info "user.email already set: $existing"
        } else {
            $GitUserEmail = Read-Host '    git user.email (blank to skip)'
        }
    }
    if ($GitUserName)  { git config --global user.name  $GitUserName  }
    if ($GitUserEmail) { git config --global user.email $GitUserEmail }
    Info "OK"
} else {
    Warn "git not on PATH yet - open a new shell after winget step, then re-run."
}

# -- 7. VS Code extensions ---------------------------------------------------
if (Get-Command code -ErrorAction SilentlyContinue) {
    Step "VS Code extensions"
    @('mvllow.rose-pine', 'vscode-icons-team.vscode-icons') | ForEach-Object {
        & code --install-extension $_ --force 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Info "OK    $_" } else { Warn "  $_ failed" }
    }
} else {
    Warn "code not on PATH yet - open a new shell after winget step, then re-run."
}

# -- 8. gh auth (browser flow) -----------------------------------------------
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Step "gh auth (github.com)"
    & gh auth status --hostname github.com 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Info "OK    already authenticated"
    } else {
        Info "Launching browser for github.com OAuth - copy the one-time code, click Authorize, return here."
        & gh auth login --hostname github.com --git-protocol https --web
        if ($LASTEXITCODE -ne 0) { Warn "gh auth login failed (exit $LASTEXITCODE)" }
    }
} else {
    Warn "gh not on PATH yet - open a new shell after winget step, then re-run."
}

# -- 9. Whatever's left ------------------------------------------------------
Write-Host ""
Write-Host "================ Still manual ================" -ForegroundColor Yellow
$leftovers = @()
if (Get-Command git -ErrorAction SilentlyContinue) {
    $haveName  = [bool](git config --global --get user.name)
    $haveEmail = [bool](git config --global --get user.email)
    if (-not $haveName -or -not $haveEmail) {
        $leftovers += @"
git identity not set - re-run apply.ps1 (it'll prompt) or:
  git config --global user.name  "Your Name"
  git config --global user.email "you@example.com"
"@
    }
}
$leftovers += @"
Restart PowerShell so RIPGREP_CONFIG_PATH and `$PROFILE` pick up. If
Microsoft.PowerShell (PS7) was newly installed, switch to it: type ``pwsh``.
"@

$leftovers | ForEach-Object { Write-Host ""; Write-Host $_ }
Write-Host ""
Write-Host "==============================================" -ForegroundColor Yellow
