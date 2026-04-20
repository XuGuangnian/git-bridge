param(
    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]$BranchName,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "."
)

$ErrorActionPreference = "Stop"

function Require-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git is not installed or not available in PATH."
    }
}

function Ensure-InsideGitRepo {
    $null = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Current directory is not a git repository."
    }
}

function Ensure-BranchExists([string]$Name) {
    git show-ref --verify --quiet "refs/heads/$Name"
    if ($LASTEXITCODE -ne 0) {
        throw "Local branch does not exist: $Name"
    }
}

function Ensure-CleanWorktree {
    $status = git status --porcelain
    if ($status) {
        throw "Working tree is not clean. Commit or clean changes first."
    }
}

Require-Git
Ensure-InsideGitRepo
Ensure-CleanWorktree
Ensure-BranchExists "main"

$ExportBranchBundle = -not [string]::IsNullOrWhiteSpace($BranchName)
if ($ExportBranchBundle) {
    Ensure-BranchExists $BranchName
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$MainBundle = Join-Path $OutputDir "main.bundle"

Write-Host "Exporting main.bundle ..."
git bundle create $MainBundle main
if ($LASTEXITCODE -ne 0) { throw "Failed to export main.bundle." }

if ($ExportBranchBundle) {
    $BranchBundle = Join-Path $OutputDir "$BranchName.bundle"

    Write-Host "Exporting $BranchName.bundle ..."
    git bundle create $BranchBundle $BranchName
    if ($LASTEXITCODE -ne 0) { throw "Failed to export $BranchName.bundle." }
}

Write-Host ""
Write-Host "Export completed:"
Write-Host "  $MainBundle"
if ($ExportBranchBundle) {
    Write-Host "  $BranchBundle"
}
