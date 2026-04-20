# git-bridge

[中文说明](./README.zh-CN.md)

## Usage

### Internal: export `main.bundle`, and optionally the target branch bundle for external use

```powershell
./internal-export.ps1
./internal-export.ps1 -BranchName "branch-name"
```

### External: align the repository with `main` and branch bundles, then check out the development branch

```bash
./external-align-before-dev.sh "branch-name"
```

### External: update `main` from `main.bundle`, then merge `main` into the development branch

```bash
./external-sync-main.sh "branch-name"
```

### External: export the development branch as a return bundle for internal merge

```bash
./external-export.sh "branch-name"
```

### Internal: import the external bundle into the target branch, then merge `main` into that branch

```powershell
./internal-import-and-merge.ps1 -BranchName "branch-name"
```
