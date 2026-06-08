---
name: git_migrate
description: 将 Git 仓库（含全部分支、tag、提交历史）迁移到新的 GitLab 仓库。当用户提到迁移代码仓库、mirror push、推送到 GitLab、代码搬迁时触发此技能。
---

# git_migrate

Git 仓库完整迁移工具 — 将源仓库的所有分支、tag 和提交历史迁移到目标仓库。

## 触发方式

```
把 git@gerrit.example.com:group/repo.git 迁移到 git@gitlab.example.com:team/repo.git
```

或只指定目标（将当前本地仓库作为源）：

```
把当前仓库迁移到 git@gitlab.example.com:team/repo.git
```

## 前置条件

| 条件 | 说明 |
|------|------|
| 目标仓库已创建 | GitLab 上创建**空仓库**（不勾选 Initialize with README）|
| SSH 免密 | 对源和目标仓库均配置了 SSH key（`ssh -T git@host` 能通过）|

## 执行逻辑

Agent 收到请求后，判断输入模式并执行：

### 模式 A：提供了源 URL 和目标 URL

直接 bare clone 源仓库再 mirror push。

```bash
WORK_DIR=$(mktemp -d)
git clone --bare <SOURCE_URL> "$WORK_DIR/repo.git"
git -C "$WORK_DIR/repo.git" push --mirror <DEST_URL>
rm -rf "$WORK_DIR"
```

> `--bare` clone 只包含 `refs/heads/*` 和 `refs/tags/*`，没有 `refs/remotes/origin/*`，所以 `--mirror` push 是安全的。

### 模式 B：只提供了目标 URL（从本地仓库迁移）

用户未指定源 URL 时，Agent 应：

1. **确认当前目录是 git 仓库**（检查 `.git` 目录或 `git rev-parse --git-dir`）
2. **询问用户**：是否将当前本地仓库迁移到目标地址
3. 用户确认后执行：

```bash
git fetch origin --prune

# 为所有远程分支创建本地跟踪分支
git branch -r | grep -v HEAD | sed 's|origin/||' | while read branch; do
    git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null || \
        git branch --track "$branch" "origin/$branch" 2>/dev/null
done

# 推送
git remote add migrate_dest <DEST_URL> 2>/dev/null || git remote set-url migrate_dest <DEST_URL>
git push migrate_dest --all
git push migrate_dest --tags

# 清理临时 remote
git remote remove migrate_dest
```

> 本地仓库不能用 `--mirror` push（会推 `refs/remotes/origin/*` 被 GitLab 拒绝），所以用 `--all` + `--tags` 分步推。

## 验证

无论哪种模式，最后都验证：

```bash
SRC_BRANCHES=$(git ls-remote <SOURCE_OR_ORIGIN> | grep -c 'refs/heads/' || true)
DST_BRANCHES=$(git ls-remote <DEST_URL> | grep -c 'refs/heads/' || true)
SRC_TAGS=$(git ls-remote <SOURCE_OR_ORIGIN> | grep 'refs/tags/' | grep -cv '\^{}' || true)
DST_TAGS=$(git ls-remote <DEST_URL> | grep 'refs/tags/' | grep -cv '\^{}' || true)

echo "Branches: source=$SRC_BRANCHES dest=$DST_BRANCHES"
echo "Tags:     source=$SRC_TAGS dest=$DST_TAGS"
```

分支数和 tag 数应一致（annotated tag 在 ls-remote 中会多一条 `^{}` 记录，属正常）。

## 常见问题

| 问题 | 原因 | 解决方式 |
|------|------|---------|
| `Permission denied (publickey)` | SSH key 未配置 | 确认 `ssh -T git@<host>` 能通 |
| `remote rejected` | 目标仓库非空 | 删除重建空仓库 |
| `repository not found` | URL 错误或无权限 | 检查 URL 和 SSH key |
| 大仓库超时 | 网络慢 | 确认 SSH 连接稳定，或分批推送 |
| Protected branch 拒绝 | GitLab 保护规则 | 目标仓库设置中关闭 branch protection |
| `refs/remotes/origin/*` 被拒绝 | 非 bare 仓库用了 `--mirror` | 改用 `--all` + `--tags`（模式 B）|

