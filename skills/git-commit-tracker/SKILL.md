---
name: git-commit-tracker
description: 跟踪多个远程 git 仓库的提交历史，支持仓库别名管理，自动 clone/pull 远程仓库，以 git log --oneline 格式输出自上次查询以来的新增提交。当用户要求查看最新提交、提交历史、变更日志、周报、日报，或使用关键词"提交记录"、"commit log"、"最新变更"时使用。
---

# Git 提交历史跟踪

跟踪多个远程 git 仓库的提交历史，自动管理本地镜像，输出自上次查询以来的增量提交记录。

## 目录结构

```
<knowledge_dir>                                   # 知识库根目录 (<knowledge_dir>)
├── gitsrc/                                       # 本地 clone 镜像
│   ├── linux/
│   └── qemu/
└── gen/repo_commit_tracker/                      # 数据目录 (<tracker_dir>)
    ├── git-tracker-repos.json                    # 仓库注册表
    ├── git-tracker-linux.json                    # linux 状态
    ├── git-tracker-qemu.json                     # qemu 状态
    ├── git-log-linux.log                         # linux 提交历史日志
    └── git-log-qemu.log                          # qemu 提交历史日志
```

**路径约定**：
- `<knowledge_dir>` 指代 `<skill_dir>/../../knowledge/`
- `<tracker_dir>` 指代 `<skill_dir>/../../knowledge/gen/repo_commit_tracker/`

## 仓库注册

### 注册文件

`<tracker_dir>/git-tracker-repos.json`：

```json
{
  "repos": {
    "riscv-linux": {
      "url": "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git",
      "branch": "master",
      "paths": ["arch/riscv/", "drivers/irqchip/irq-riscv*"]
    },
    "linux": {
      "url": "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git",
      "branch": "master"
    },
    "qemu": {
      "url": "https://gitlab.com/qemu-project/qemu.git",
      "branch": "master",
      "paths": ["target/riscv/"]
    }
  }
}
```

字段说明：
- `branch`：可选，默认跟踪远程默认分支
- `paths`：可选，目录/文件过滤列表，只跟踪涉及这些路径的提交。支持 glob 通配符。不设置则跟踪全部提交

### 管理操作

| 用户请求 | 操作 |
|----------|------|
| "添加仓库 xxx url yyy" | 注册别名和 URL，首次查询时自动 clone |
| "添加仓库 xxx url yyy 分支 zzz" | 同上，指定跟踪分支 |
| "添加仓库 xxx url yyy 目录 a/ b/" | 同上，指定关注目录 |
| "设置 xxx 关注目录 a/ b/" | 更新已注册仓库的 paths 过滤 |
| "清除 xxx 的目录过滤" | 移除 paths，恢复跟踪全部提交 |
| "删除仓库 xxx" | 移除注册、删除状态文件和 `<knowledge_dir>/gitsrc/<别名>/` |
| "仓库列表" | 显示所有仓库的别名、URL、分支、上次查询时间 |
| "重命名仓库 old new" | 更新别名，重命名 gitsrc 子目录和状态文件 |

## 状态文件

每个仓库独立存放：`<tracker_dir>/git-tracker-<别名>.json`

```json
{
  "alias": "linux",
  "url": "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git",
  "branch": "master",
  "local_path": "<knowledge_dir>/gitsrc/linux",
  "last_commit": "<commit-hash>",
  "last_query_time": "2025-04-14T10:30:00+08:00"
}
```

## 工作流程

### 1. 确定目标仓库

- **别名**："查看 mainline 的提交记录"
- **无指定**：提示用户选择已注册仓库，或列出可用仓库

### 2. 同步本地镜像

本地目录：`<knowledge_dir>/gitsrc/<别名>/`

**首次（目录不存在）**：
```bash
mkdir -p <knowledge_dir>/gitsrc
git clone --single-branch --branch <branch> <url> <knowledge_dir>/gitsrc/<别名>
```

大型仓库（如 linux 内核）clone 时间较长，使用 `--depth` 控制：
- 如果用户未指定，首次 clone 使用 `--depth 500` 做浅克隆
- 用户可要求完整克隆："完整克隆 mainline"

**后续（目录已存在）**：
```bash
git -C <knowledge_dir>/gitsrc/<别名> pull --ff-only
```

如果 pull 失败（如分支分叉），执行：
```bash
git -C <knowledge_dir>/gitsrc/<别名> fetch origin <branch>
git -C <knowledge_dir>/gitsrc/<别名> reset --hard origin/<branch>
```

### 3. 获取提交历史

```bash
LOCAL="<knowledge_dir>/gitsrc/<别名>"
```

如果仓库注册了 `paths` 过滤，所有 git log 命令末尾追加 `-- <path1> <path2> ...`。

**有上次记录时**（增量查询）：
```bash
# 无 paths 过滤
git -C $LOCAL log --oneline <last_commit>..HEAD

# 有 paths 过滤
git -C $LOCAL log --oneline <last_commit>..HEAD -- arch/riscv/ drivers/irqchip/irq-riscv*
```

如果 last_commit 不可达（浅克隆截断或 rebase），回退为最近 50 条并提示用户。

**首次查询时**：
```bash
git -C $LOCAL log --oneline -50 -- <paths...>
```

用户指定时间范围或条数时：
```bash
git -C $LOCAL log --oneline --since="2025-04-07" --until="2025-04-14" -- <paths...>
git -C $LOCAL log --oneline -N -- <paths...>
```

### 4. 输出格式

```
## 提交历史 [<别名>]（自 <上次时间> 以来）

仓库: <别名>
远程: <url>
分支: <branch>
关注目录: <path1>, <path2>（如有设置，否则省略此行）
范围: <last_commit_short>..HEAD
新增提交: N 条

<git log --oneline 输出>

---
上次查询: <上次时间> (<last_commit_short>)
本次查询: <当前时间> (<current_commit_short>)
```

### 5. 更新状态

```bash
git -C $LOCAL rev-parse HEAD
```

写入 `<tracker_dir>/git-tracker-<别名>.json`。

### 6. 保存日志文件

每次查询完成后，将本次获取的提交历史**插入到文件头部**（最新记录在最前）：

```
<tracker_dir>/git-log-<别名>.log
```

日志文件格式（每次在文件头部插入一个带时间戳的段落）：

```
========== 查询时间: <YYYY-MM-DD HH:MM:SS> ==========
分支: <branch>
范围: <last_commit_short>..HEAD
新增提交: N 条

<git log --oneline 输出>

```

写入方式：读取原有内容，将新记录拼接在前，再写回文件。

- 首次查询时创建文件
- 如果本次无新增提交，不插入内容
- 日志文件保持纯文本格式，方便 grep 搜索

## 批量查询

- "查看所有仓库的提交记录" -> 遍历所有仓库，逐个 pull + 输出
- "查看 mainline 和 qemu 的提交" -> 只操作指定仓库

批量时按仓库分段输出。可并行执行多个仓库的 pull 操作以节省时间。

## 附加功能

| 用户请求 | 处理方式 |
|----------|----------|
| "重置 xxx 的跟踪" | 删除状态文件，下次从当前 HEAD 开始 |
| "重新克隆 xxx" | 删除 gitsrc 子目录，下次重新 clone |
| "按作者过滤" | 加 `--author=<name>` |
| "显示详细信息" | 用 `git log --format="%h %ad %an: %s" --date=short` |
| "加深历史 xxx" | `git -C $LOCAL fetch --deepen=N` |

## 注意事项

- 大型仓库默认浅克隆（`--depth 500`），需要更多历史时用户手动加深
- clone/pull 需要网络访问，如失败应显示 git 错误信息并提示检查网络或 URL
- 输出保持简洁，不做额外的内容分析或分类
