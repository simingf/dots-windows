# Diagnostic + recovery for Windows Terminal "Failed to load settings" /
# "still opens in WinPS 5.1 instead of PS7" problems.
#
# Writes output to scripts\wt-debug.out (next to this script). Commit and push
# that file so Claude can read it. Safe / read-mostly: only mutating action is
# killing running WT processes so the next launch re-discovers profiles.

$out = Join-Path $PSScriptRoot 'wt-debug.out'
Start-Transcript -Path $out -Force | Out-Null

Write-Host "=== WT package dirs ==="
Get-ChildItem "$env:LOCALAPPDATA\Packages\" -Filter "*WindowsTerminal*" -ErrorAction SilentlyContinue |
    ForEach-Object {
        $p = "$($_.FullName)\LocalState\settings.json"
        $exists = Test-Path $p
        $size   = if ($exists) { (Get-Item $p).Length } else { 0 }
        Write-Host "$p  exists=$exists  size=$size"
    }

Write-Host ""
Write-Host "=== Contents (if any) ==="
Get-ChildItem "$env:LOCALAPPDATA\Packages\" -Filter "*WindowsTerminal*" -ErrorAction SilentlyContinue |
    ForEach-Object {
        $p = "$($_.FullName)\LocalState\settings.json"
        if (Test-Path $p) {
            Write-Host ""
            Write-Host "--- $p ---"
            Get-Content $p -Raw
        }
    }

Write-Host ""
Write-Host "=== Symlink/file status of repo target ==="
$repoTarget = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $repoTarget) {
    Get-Item $repoTarget -Force | Select-Object FullName, LinkType, Target, Length | Format-List | Out-String | Write-Host
}

Write-Host "=== pwsh on PATH? ==="
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshCmd) {
    $pwshCmd | Select-Object Source, Version | Format-List | Out-String | Write-Host
} else {
    Write-Host "pwsh NOT found. PS7 not installed - run apply.ps1 to install via winget."
}

Write-Host "=== pwsh.exe in standard locations? ==="
@(
    "$env:ProgramFiles\PowerShell\7\pwsh.exe",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Microsoft.PowerShell_*\pwsh.exe"
) | ForEach-Object {
    Get-ChildItem $_ -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.FullName)" }
}

Write-Host ""
Write-Host "=== Killing any running WT processes (so next launch re-discovers PS7) ==="
$procs = Get-Process WindowsTerminal, OpenConsole -ErrorAction SilentlyContinue
if ($procs) {
    $procs | ForEach-Object { Write-Host "  killing $($_.ProcessName) (PID $($_.Id))"; $_ | Stop-Process -Force }
} else {
    Write-Host "  none running"
}

Stop-Transcript | Out-Null
Write-Host ""
Write-Host "Wrote $out - commit and push it so Claude can read." -ForegroundColor Yellow
