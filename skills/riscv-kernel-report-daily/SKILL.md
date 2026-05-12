---
name: "riscv-kernel-report-daily"
description: "每天从 lore.kernel.org 的多个内核邮件列表获取昨天的 patch 提交记录，按过滤规则筛选后整理成报表并写入语雀知识库。当用户提到内核补丁日报、linux-riscv 邮件列表监控、内核补丁追踪、LKML patch 报表、语雀内核动态时使用此技能。"
---

# Kernel Patch 日报生成器

从多个内核邮件列表获取昨天的 patch 提交记录，按规则过滤后整理为结构化报表，写入语雀知识库。

> 本 skill 为组合式 skill，内部调用两个子 skill 协同工作：
> - **[kernel-patch-fetch]**：负责通过 NNTP 拉取 patch 数据并生成 Markdown 报表
> - **[yuque-doc-writer]**：负责将 Markdown 内容写入语雀知识库

## 监控的邮件列表

| 邮件列表 | NNTP Group | 过滤规则 |
|----------|-----------|----------|
| Linux RISC-V | org.infradead.lists.linux-riscv | 全部 patch |
| LKML (主线内核) | org.kernel.vger.linux-kernel | 仅含 fix/improve/enhance/optimize 等关键字 |
| Linux Perf Users | org.kernel.vger.linux-perf-users | 仅含 riscv 关键字 |

## 环境变量

| 变量 | 必需 | 说明 |
|------|------|------|
| `YUQUE_TOKEN` | 是 | 语雀团队 Token |
| `YUQUE_API_HOST` | 否 | 语雀 API 地址（默认 `https://yuque-api.antfin-inc.com`） |
| `YUQUE_WEB_HOST` | 否 | 语雀页面地址（默认 `https://aliyuque.antfin.com`） |

## 工作流程

本 skill 通过调用两个子 skill 完成日报生成：

### Step 1: 获取 Patch 数据并生成 Markdown

调用 **[kernel-patch-fetch]** 子 skill：

```bash
python3 <skill_dir>/../kernel-patch-fetch/scripts/fetch_patches.py \
  --format markdown --md-output /tmp/riscv_patches.md
```

参数：
- `--date YYYY-MM-DD`：指定日期（默认昨天）
- `--format markdown`：直接输出 Markdown 格式
- `--md-output FILE`：保存 Markdown 到文件
- `--lists IDs`：逗号分隔的列表 ID（默认全部）

### Step 2: 写入语雀文档

调用 **[yuque-doc-writer]** 子 skill：

```bash
python3 <skill_dir>/../yuque-doc-writer/scripts/yuque_doc_write.py \
  --md-file /tmp/riscv_patches.md --date $(date -d yesterday +%Y-%m-%d)
```

参数：
- `--token`：语雀 Token（不传则读取 `YUQUE_TOKEN` 环境变量）
- `--md-file`：Step 1 输出的 Markdown 文件路径
- `--date`：文档日期（用于确定年月文件夹）
- `--folder`：指定语雀文件夹名称（已存在则直接写入，不存在则新建）；不指定则按 --date 自动生成年月文件夹
- `--repo`：知识库 slug（默认 `riscv-kernel-report-daily`）

脚本会自动确保知识库和指定文件夹存在，创建当天文档并归入对应文件夹。已存在则跳过。

### 完整一键执行

```bash
export YUQUE_TOKEN="your_token"

# Step 1: 获取 patch 并生成 Markdown
python3 <skill_dir>/../kernel-patch-fetch/scripts/fetch_patches.py \
  --format markdown --md-output /tmp/riscv_patches.md && \
\
# Step 2: 写入语雀
python3 <skill_dir>/../yuque-doc-writer/scripts/yuque_doc_write.py \
  --md-file /tmp/riscv_patches.md \
  --date $(date -d yesterday +%Y-%m-%d)
```

### 管道式执行（不生成中间文件）

```bash
export YUQUE_TOKEN="your_token"
DATE=$(date -d yesterday +%Y-%m-%d)

python3 <skill_dir>/../kernel-patch-fetch/scripts/fetch_patches.py \
  --format markdown --date $DATE | \
python3 <skill_dir>/../yuque-doc-writer/scripts/yuque_doc_write.py \
  --stdin --date $DATE
```

## 报表格式

每份文档以邮件列表为一级标题，patch 类型为二级标题：

```markdown
**共 25 条记录**

| 邮件列表 | 过滤规则 | 数量 |
|----------|----------|------|
| Linux RISC-V | 全部 | 21 |
| LKML (主线内核) | fix/improve 相关 | 3 |
| Linux Perf Users | riscv 相关 | 1 |

## Linux RISC-V（21 条）
### 新补丁 (6)
- [riscv: Add support for Zvkb extension](link) — Author
### 补丁更新 (14)
- [PATCH v3] riscv: fix memory mapping issue — Author

## LKML (主线内核)（3 条）
### 新补丁 (3)
- [fix: resolve race condition in scheduler](link) — Author

## Linux Perf Users（1 条）
### 新补丁 (1)
- [perf: riscv: Add cycle counter support](link) — Author
```

## 子 skill 详情

### kernel-patch-fetch

- **路径**: `<skill_dir>/../kernel-patch-fetch/`
- **功能**: 通过 NNTP 从 lore.kernel.org 获取 patch 数据，支持输出 JSON 或 Markdown
- **脚本**: `scripts/fetch_patches.py`

### yuque-doc-writer

- **路径**: `<skill_dir>/../yuque-doc-writer/`
- **功能**: 将 Markdown 内容写入语雀知识库，支持自动创建知识库和指定文件夹
- **脚本**: `scripts/yuque_doc_write.py`

## 注意事项

- NNTP 协议无条数限制，LKML 每天 600+ 封邮件均可完整覆盖
- 语雀 Token 长期有效，无需定期刷新
- 如果所有邮件列表均无匹配 patch，文档内容会简要说明
- 脚本幂等：重复执行不会创建重复文档
