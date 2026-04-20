# git-bridge

[English README](./README.md)

## 用法

### 内部：导出 `main.bundle`，也可以选择同时导出目标分支 bundle 给外部使用

```powershell
./internal-export.ps1
./internal-export.ps1 -BranchName "branch-name"
```

### 外部：使用 `main.bundle` 和分支 bundle 对齐仓库，并检出开发分支

```bash
./external-align-before-dev.sh "branch-name"
```

### 外部：使用 `main.bundle` 更新 `main`，再把 `main` 合并到开发分支

```bash
./external-sync-main.sh "branch-name"
```

### 外部：将开发分支导出为回传 bundle，供内部合并

```bash
./external-export.sh "branch-name"
```

### 内部：将外部 bundle 导入目标分支，再把 `main` 合并到该分支

```powershell
./internal-import-and-merge.ps1 -BranchName "branch-name"
```
