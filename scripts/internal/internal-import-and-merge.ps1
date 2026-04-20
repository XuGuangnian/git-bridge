param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,

    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]$BundlePath = ""
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
Ensure-BranchExists $BranchName

if ([string]::IsNullOrWhiteSpace($BundlePath)) {
    $BundlePath = Join-Path $PWD "$BranchName-dev.bundle"
}

if (-not (Test-Path $BundlePath)) {
    throw "Bundle file does not exist: $BundlePath"
}

Write-Host "Switching to branch $BranchName ..."
git checkout $BranchName
if ($LASTEXITCODE -ne 0) { throw "Failed to switch branch: $BranchName" }

Write-Host "Importing external bundle ..."
git fetch $BundlePath $BranchName
if ($LASTEXITCODE -ne 0) { throw "Failed to fetch bundle." }

Write-Host "Merging external development changes ..."
git merge FETCH_HEAD
if ($LASTEXITCODE -ne 0) { throw "Failed to merge external development changes. Resolve conflicts manually." }

Write-Host "Merging main into $BranchName ..."
git merge main
if ($LASTEXITCODE -ne 0) { throw "Failed to merge main. Resolve conflicts manually." }

Write-Host ""
Write-Host "Completed:"
Write-Host "  1. External bundle merged into $BranchName"
Write-Host "  2. main merged into $BranchName"
Write-Host ""
Write-Host "Run the following commands manually to merge into main:"
Write-Host "  git checkout main"
Write-Host "  git merge --no-ff $BranchName"
