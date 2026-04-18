# git-bridge

## 用法

### 内部：导出 main 与指定分支的 bundle（给外部用）

```powershell
./internal-export.ps1 -BranchName "branch-name"
```

### 外部：用 main 与分支 bundle 对齐仓库并检出开发分支（开工前）

```bash
./external-align-before-dev.sh "branch-name"
```

### 外部：用 main.bundle 更新 main，并把 main 合并进开发分支

```bash
./external-sync-main.sh "branch-name"
```

### 外部：把开发分支打成回传 bundle（给内部合并）

```bash
./external-export.sh "branch-name"
```

### 内部：导入外部 bundle 到指定分支，再把 main 合并进该分支

```powershell
./internal-import-and-merge.ps1 -BranchName "branch-name"
```
