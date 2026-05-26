# Capture nvim startup errors + Mason state for diagnosis.
# Writes to scripts\nvim-debug.out next to this script. Commit + push so
# Claude can read.

$out = Join-Path $PSScriptRoot 'nvim-debug.out'
Start-Transcript -Path $out -Force | Out-Null

Write-Host "=== nvim --version ==="
nvim --version 2>&1 | Select-Object -First 5

Write-Host ""
Write-Host "=== Tools Mason expects on PATH ==="
@('git', 'curl', 'tar', 'unzip', 'go', 'gofmt', 'python', 'pip', 'cargo', 'npm', 'node', 'ruff', 'clang-format') | ForEach-Object {
    $cmd = Get-Command $_ -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("  {0,-10} {1}" -f $_, $cmd.Source)
    } else {
        Write-Host ("  {0,-10} MISSING" -f $_)
    }
}

Write-Host ""
Write-Host "=== Headless nvim startup (captures notify/error output) ==="
# +qa exits cleanly, +messages dumps any error notifications, +Lazy log shows plugin install errors
nvim --headless +'lua vim.defer_fn(function() print("---MESSAGES---"); vim.cmd("messages"); vim.cmd("qa") end, 1000)' 2>&1

Write-Host ""
Write-Host "=== Mason data dir contents ==="
$masonDir = "$env:LOCALAPPDATA\nvim-data\mason"
if (Test-Path $masonDir) {
    Write-Host "  $masonDir"
    Get-ChildItem $masonDir -Directory | ForEach-Object { Write-Host "    $($_.Name)" }
    Write-Host ""
    Write-Host "  bin/:"
    Get-ChildItem "$masonDir\bin" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "    $($_.Name)" }
} else {
    Write-Host "  $masonDir does not exist (mason hasn't run successfully yet)"
}

Write-Host ""
Write-Host "=== Lazy plugin state ==="
$lazyDir = "$env:LOCALAPPDATA\nvim-data\lazy"
if (Test-Path $lazyDir) {
    Get-ChildItem $lazyDir -Directory | Select-Object -ExpandProperty Name | Sort-Object
} else {
    Write-Host "  $lazyDir does not exist"
}

Stop-Transcript | Out-Null
Write-Host ""
Write-Host "Wrote $out - commit and push it." -ForegroundColor Yellow
