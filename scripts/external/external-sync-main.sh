#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <branch-name> [main-bundle-path]"
  echo "  main-bundle-path defaults to ./main.bundle in the current directory"
  echo "Example: $0 branch-name"
  echo "Example: $0 branch-name /mnt/d/bundles/main.bundle"
  exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi

BRANCH_NAME="$1"
MAIN_BUNDLE="${2:-./main.bundle}"

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

branch_exists "main" || {
  echo "Error: local main does not exist. Run external-align-before-dev.sh first."
  exit 1
}

branch_exists "$BRANCH_NAME" || {
  echo "Error: local branch does not exist: $BRANCH_NAME"
  exit 1
}

echo "Updating main ..."
git checkout main
git fetch "$MAIN_BUNDLE" main
git merge --ff-only FETCH_HEAD || git merge FETCH_HEAD

echo "Merging main into $BRANCH_NAME ..."
git checkout "$BRANCH_NAME"
git merge main

echo "Sync completed. Current branch: $(git branch --show-current)"
