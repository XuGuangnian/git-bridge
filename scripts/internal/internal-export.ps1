param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,

    # 不指定 -OutputDir 时默认为 "."，即当前工作目录（bundle 写到当前目录）。
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "."
)

$ErrorActionPreference = "Stop"

function Require-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git 未安装或不在 PATH 中。"
    }
}

function Ensure-InsideGitRepo {
    $null = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "当前目录不是 git 仓库。"
    }
}

function Ensure-BranchExists([string]$Name) {
    git show-ref --verify --quiet "refs/heads/$Name"
    if ($LASTEXITCODE -ne 0) {
        throw "本地分支不存在: $Name"
    }
}

function Ensure-CleanWorktree {
    $status = git status --porcelain
    if ($status) {
        throw "当前工作区不干净，请先提交或清理变更。"
    }
}

Require-Git
Ensure-InsideGitRepo
Ensure-CleanWorktree
Ensure-BranchExists "main"
Ensure-BranchExists $BranchName

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$MainBundle = Join-Path $OutputDir "main.bundle"
$BranchBundle = Join-Path $OutputDir "$BranchName.bundle"

Write-Host "导出 main.bundle ..."
git bundle create $MainBundle main
if ($LASTEXITCODE -ne 0) { throw "导出 main.bundle 失败。" }

Write-Host "导出 $BranchName.bundle ..."
git bundle create $BranchBundle $BranchName
if ($LASTEXITCODE -ne 0) { throw "导出 $BranchName.bundle 失败。" }

Write-Host ""
Write-Host "导出完成："
Write-Host "  $MainBundle"
Write-Host "  $BranchBundle"