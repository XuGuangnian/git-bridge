#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <branch-name> [main-bundle-path [branch-bundle-path]]"
  echo "  Branch only: defaults to ./main.bundle and ./<branch-name>.bundle"
  echo "  Two args: specify main.bundle, branch bundle still defaults to ./<branch-name>.bundle"
  echo "Example: $0 branch-name"
  echo "Example: $0 branch-name /mnt/d/bundles/main.bundle /mnt/d/bundles/branch-name.bundle"
  exit 1
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage
fi

BRANCH_NAME="$1"
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

require_file() {
  local f="$1"
  [[ -f "$f" ]] || {
    echo "Error: file does not exist: $f"
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

echo "Syncing main ..."
if branch_exists "main"; then
  git checkout main
else
  git checkout --orphan main
  git reset --hard
fi

git fetch "$MAIN_BUNDLE" main
git merge --ff-only FETCH_HEAD || git merge FETCH_HEAD

echo "Importing branch $BRANCH_NAME ..."
git fetch "$BRANCH_BUNDLE" "$BRANCH_NAME"

if branch_exists "$BRANCH_NAME"; then
  git checkout "$BRANCH_NAME"
  git reset --hard FETCH_HEAD
else
  git checkout -b "$BRANCH_NAME" FETCH_HEAD
fi

echo "Done. Current branch: $(git branch --show-current)"
