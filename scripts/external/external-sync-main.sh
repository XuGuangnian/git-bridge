#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "用法: $0 <branch-name> [main-bundle-path]"
  echo "  main-bundle-path 省略时默认当前目录下的 ./main.bundle"
  echo "示例: $0 branch-name"
  echo "示例: $0 branch-name /mnt/d/bundles/main.bundle"
  exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi

BRANCH_NAME="$1"
# 省略第二个参数时相对于当前工作目录使用约定文件名（与 internal-export.ps1 的 main.bundle 一致）。
MAIN_BUNDLE="${2:-./main.bundle}"

require_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "错误：当前目录不是 git 仓库"
    exit 1
  }
}

require_clean_worktree() {
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "错误：当前工作区不干净，请先提交或清理变更"
    exit 1
  fi
}

require_file() {
  local f="$1"
  [[ -f "$f" ]] || {
    echo "错误：文件不存在: $f"
    exit 1
  }
}

branch_exists() {
  git show-ref --verify --quiet "refs/heads/$1"
}

require_git_repo
require_clean_worktree
require_file "$MAIN_BUNDLE"

branch_exists "main" || {
  echo "错误：本地 main 不存在，请先执行 external-align-before-dev.sh"
  exit 1
}

branch_exists "$BRANCH_NAME" || {
  echo "错误：本地分支不存在: $BRANCH_NAME"
  exit 1
}

echo "更新 main ..."
git checkout main
git fetch "$MAIN_BUNDLE" main
git merge --ff-only FETCH_HEAD || git merge FETCH_HEAD

echo "将 main 合并到 $BRANCH_NAME ..."
git checkout "$BRANCH_NAME"
git merge main

echo "同步完成。当前分支：$(git branch --show-current)"