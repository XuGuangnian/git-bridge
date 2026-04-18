param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,

    # 不指定 -BundlePath 时，默认使用当前工作目录下的「<分支名>-dev.bundle」（与 external-export.sh 命名一致）。
    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]$BundlePath = ""
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

if ([string]::IsNullOrWhiteSpace($BundlePath)) {
    $BundlePath = Join-Path $PWD "$BranchName-dev.bundle"
}

if (-not (Test-Path $BundlePath)) {
    throw "bundle 文件不存在: $BundlePath"
}

Write-Host "切换到分支 $BranchName ..."
git checkout $BranchName
if ($LASTEXITCODE -ne 0) { throw "切换分支失败：$BranchName" }

Write-Host "导入外部 bundle ..."
git fetch $BundlePath $BranchName
if ($LASTEXITCODE -ne 0) { throw "fetch bundle 失败。" }

Write-Host "合并外部开发结果 ..."
git merge FETCH_HEAD
if ($LASTEXITCODE -ne 0) { throw "合并外部开发结果失败，请手动处理冲突。" }

Write-Host "合并 main 到 $BranchName ..."
git merge main
if ($LASTEXITCODE -ne 0) { throw "合并 main 失败，请手动处理冲突。" }

Write-Host ""
Write-Host "已完成："
Write-Host "  1. 外部 bundle 已合并到 $BranchName"
Write-Host "  2. main 已合并到 $BranchName"
Write-Host ""
Write-Host "以下最终合并到 main 的操作请手动执行："
Write-Host "  git checkout main"
Write-Host "  git merge --no-ff $BranchName"

# 最终合并到 main 不放入脚本，手动执行：
# git checkout main
# git merge --no-ff $BranchName