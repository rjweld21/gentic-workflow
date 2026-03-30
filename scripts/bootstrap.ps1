#
# Gentic Workflow — Bootstrap Script (Windows PowerShell)
#
# Usage (run in PowerShell):
#   irm https://raw.githubusercontent.com/rjweld21/gentic-workflow/master/scripts/bootstrap.ps1 | iex
#
# Or with a custom install directory:
#   $env:GENTIC_DIR = "C:\Tools\gentic-workflow"; irm https://raw.githubusercontent.com/rjweld21/gentic-workflow/master/scripts/bootstrap.ps1 | iex
#
# What this does:
#   1. Clones the gentic-workflow repo
#   2. Creates a directory junction at ~/.claude/workflow/ → the repo
#   3. Creates ~/.claude/skills/ and junctions for the two included skills
#
# After running, start a new Claude Code session and use:
#   /initialize-workflow  — to configure your board and projects
#   /using-workflow       — to load workflow context into a session
#

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/rjweld21/gentic-workflow.git"
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

# Use GENTIC_DIR env var if set, otherwise default
if ($env:GENTIC_DIR) {
    $InstallDir = $env:GENTIC_DIR
} else {
    $InstallDir = Join-Path $env:USERPROFILE "gentic-workflow"
}

Write-Host "=== Gentic Workflow Bootstrap ===" -ForegroundColor Cyan
Write-Host ""

# --- Step 1: Clone the repo ---
if (Test-Path $InstallDir) {
    Write-Host "[1/3] Repo already exists at $InstallDir — pulling latest..." -ForegroundColor Yellow
    git -C $InstallDir pull --ff-only
} else {
    Write-Host "[1/3] Cloning gentic-workflow to $InstallDir..." -ForegroundColor Green
    git clone $RepoUrl $InstallDir
}

# --- Step 2: Create workflow junction ---
Write-Host "[2/3] Setting up ~/.claude/workflow junction..." -ForegroundColor Green

if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
}

$WorkflowLink = Join-Path $ClaudeDir "workflow"

if (Test-Path $WorkflowLink) {
    $item = Get-Item $WorkflowLink
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "  Junction already exists — removing and recreating..."
        cmd /c "rmdir `"$WorkflowLink`""
    } else {
        Write-Host "  WARNING: $WorkflowLink is a real directory, not a junction." -ForegroundColor Red
        Write-Host "  Back it up and remove it, then re-run this script."
        Write-Host "  Skipping junction creation."
        $WorkflowLink = $null
    }
}

if ($WorkflowLink) {
    cmd /c "mklink /J `"$WorkflowLink`" `"$InstallDir`""
    Write-Host "  $WorkflowLink -> $InstallDir"
}

# --- Step 3: Create skill junctions ---
Write-Host "[3/3] Installing skills to ~/.claude/skills/..." -ForegroundColor Green

$SkillsDir = Join-Path $ClaudeDir "skills"
if (-not (Test-Path $SkillsDir)) {
    New-Item -ItemType Directory -Path $SkillsDir | Out-Null
}

foreach ($skill in @("initialize-workflow", "using-workflow")) {
    $target = Join-Path $ClaudeDir "workflow" "skills" $skill
    $link = Join-Path $SkillsDir $skill

    if (Test-Path $link) {
        $item = Get-Item $link
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            cmd /c "rmdir `"$link`""
        } else {
            Write-Host "  WARNING: $link is a real directory — skipping." -ForegroundColor Red
            continue
        }
    }

    cmd /c "mklink /J `"$link`" `"$target`""
    Write-Host "  $link -> $target"
}

# --- Done ---
Write-Host ""
Write-Host "=== Bootstrap complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Start a new Claude Code session and run:"
Write-Host "  /initialize-workflow   — to set up your board and projects" -ForegroundColor White
Write-Host "  /using-workflow        — to load workflow context into any session" -ForegroundColor White
Write-Host ""
