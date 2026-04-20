#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <branch-name> [output-dir]"
  echo "Example: $0 branch-name ./out"
  exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi

BRANCH_NAME="$1"
OUTPUT_DIR="${2:-.}"

require_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "Error: current directory is not a git repository"
    exit 1
  }
}

require_clean_worktree() {
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Error: working tree is not clean. Commit or clean changes first."
    exit 1
  fi
}

branch_exists() {
  git show-ref --verify --quiet "refs/heads/$1"
}

require_git_repo
require_clean_worktree

branch_exists "$BRANCH_NAME" || {
  echo "Error: local branch does not exist: $BRANCH_NAME"
  exit 1
}

mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/${BRANCH_NAME}-dev.bundle"

echo "Exporting $BRANCH_NAME -> $OUTPUT_FILE"
git bundle create "$OUTPUT_FILE" "$BRANCH_NAME"

echo "Export completed: $OUTPUT_FILE"
