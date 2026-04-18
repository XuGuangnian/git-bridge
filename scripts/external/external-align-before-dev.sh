#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "用法: $0 <branch-name> [main-bundle-path [branch-bundle-path]]"
  echo "  仅分支名：默认 ./main.bundle 与 ./<分支名>.bundle"
  echo "  两个参数：指定 main.bundle，分支 bundle 仍默认 ./<分支名>.bundle"
  echo "示例: $0 branch-name"
  echo "示例: $0 branch-name /mnt/d/bundles/main.bundle /mnt/d/bundles/branch-name.bundle"
  exit 1
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage
fi

BRANCH_NAME="$1"
# 省略路径参数时，在当前工作目录下按约定文件名查找（与 internal-export.ps1 输出一致，文件名直接使用分支名）。
if [[ $# -eq 1 ]]; then
  MAIN_BUNDLE="./main.bundle"
  BRANCH_BUNDLE="./${BRANCH_NAME}.bundle"
elif [[ $# -eq 2 ]]; then
  MAIN_BUNDLE="$2"
  BRANCH_BUNDLE="./${BRANCH_NAME}.bundle"
else
  MAIN_BUNDLE="$2"
  BRANCH_BUNDLE="$3"
fi

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
require_file "$BRANCH_BUNDLE"

echo "同步 main ..."
if branch_exists "main"; then
  git checkout main
else
  git checkout --orphan main
  git reset --hard
fi

git fetch "$MAIN_BUNDLE" main
git merge --ff-only FETCH_HEAD || git merge FETCH_HEAD

echo "导入分支 $BRANCH_NAME ..."
git fetch "$BRANCH_BUNDLE" "$BRANCH_NAME"

if branch_exists "$BRANCH_NAME"; then
  git checkout "$BRANCH_NAME"
  git reset --hard FETCH_HEAD
else
  git checkout -b "$BRANCH_NAME" FETCH_HEAD
fi

echo "完成。当前分支：$(git branch --show-current)"