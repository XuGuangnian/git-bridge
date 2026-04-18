#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "用法: $0 <branch-name> [output-dir]"
  echo "示例: $0 branch-name ./out"
  exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi

BRANCH_NAME="$1"
# 第二个参数省略时为 "."，即把 bundle 写到当前工作目录。
OUTPUT_DIR="${2:-.}"

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

branch_exists() {
  git show-ref --verify --quiet "refs/heads/$1"
}

require_git_repo
require_clean_worktree

branch_exists "$BRANCH_NAME" || {
  echo "错误：本地分支不存在: $BRANCH_NAME"
  exit 1
}

mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/${BRANCH_NAME}-dev.bundle"

echo "导出 $BRANCH_NAME -> $OUTPUT_FILE"
git bundle create "$OUTPUT_FILE" "$BRANCH_NAME"

echo "导出完成：$OUTPUT_FILE"