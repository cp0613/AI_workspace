---
name: "yuque-doc-writer"
description: "将 Markdown 文档写入语雀知识库，支持自动创建知识库、指定文件夹分类、文档幂等创建。当用户需要将 Markdown 内容发布到语雀、创建语雀知识库文档、管理语雀文档目录时使用此技能。"
---

# 语雀文档写入器

将 Markdown 文档内容写入语雀知识库，自动按指定文件夹组织文档结构。

## 文档组织结构

```
riscv-kernel-report-daily (知识库)
├── 2026-01/                          (文件夹)
│   ├── Kernel Patch 日报 (2026-01-01)  (DOC)
│   ├── Kernel Patch 日报 (2026-01-02)
│   └── ...
├── 2026-05/
│   ├── Kernel Patch 日报 (2026-05-09)
│   └── ...
└── ...
```

## 环境变量

注：适用于阿里内网语雀

| 变量 | 必需 | 说明 |
|------|------|------|
| `YUQUE_TOKEN` | 是 | 语雀团队 Token |
| `YUQUE_API_HOST` | 否 | 语雀 API 地址（默认 `https://yuque-api.antfin-inc.com`） |
| `YUQUE_WEB_HOST` | 否 | 语雀页面地址（默认 `https://aliyuque.antfin.com`） |

### 语雀 Token 获取方式

1. 登录 `https://aliyuque.antfin.com/`
2. 点击 **团队**，如果没有可管理的团队需要先点击右上角 **新建团队**
3. 在团队主页右上角点击 **设置**，**更多设置**
4. 在左侧菜单栏点击开发者栏目 **Token**
5. 点击 **新建**，勾选知识库读写、文档读写权限
6. 复制生成的 Token

## 工作流程

### 写入 Markdown 文件到语雀

```bash
python3 scripts/yuque_doc_write.py --md-file /tmp/riscv_patches.md --date 2026-05-10
```

### 从 stdin 读取 Markdown 内容

```bash
cat report.md | python3 scripts/yuque_doc_write.py --date 2026-05-10 --stdin
```

## 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--token` | str | `YUQUE_TOKEN` | 语雀 Token |
| `--api-host` | str | `YUQUE_API_HOST` | 语雀 API 地址 |
| `--web-host` | str | `YUQUE_WEB_HOST` | 语雀页面地址 |
| `--md-file` | str | - | Markdown 文件路径 |
| `--stdin` | flag | False | 从 stdin 读取 Markdown 内容 |
| `--title` | str | 自动 | 文档标题（默认: `文档 (YYYY-MM-DD)`） |
| `--slug` | str | 日期 | 文档 slug（默认: `YYYY-MM-DD`） |
| `--date` | str | - | 文档日期 (YYYY-MM-DD)，未指定 --folder 时用于自动生成年月文件夹 |
| `--folder` | str | 自动 | 指定语雀文件夹名称（已存在则直接写入，不存在则新建）；不指定则按 --date 自动生成年月文件夹 |
| `--repo` | str | `riscv-kernel-report-daily` | 知识库 slug |

## 完整示例

```bash
export YUQUE_TOKEN="your_token"

# 按日期自动归入年月文件夹（如 2026-05/）
python3 scripts/yuque_doc_write.py \
  --md-file /tmp/riscv_patches.md \
  --date 2026-05-10

# 指定自定义文件夹（已存在则直接写入，不存在则新建）
python3 scripts/yuque_doc_write.py \
  --md-file /tmp/report.md \
  --date 2026-05-10 \
  --folder "自定义目录名"

# 指定文档标题/文件名
python3 scripts/yuque_doc_write.py \
  --md-file /tmp/report.md \
  --date 2026-05-10 \
  --title "自定义文档标题"

# 仅指定文件夹，不指定日期（需手动提供 --title 和 --slug）
python3 scripts/yuque_doc_write.py \
  --md-file /tmp/report.md \
  --folder "自定义目录名" \
  --title "我的文档" \
  --slug my-doc-slug

# 从 stdin 读取并写入
python3 scripts/fetch_patches.py --format markdown | \
  python3 scripts/yuque_doc_write.py --date 2026-05-10 --stdin
```

## 注意事项

- `--date` 和 `--folder` 至少需要指定其一
- `--folder` 优先级高于 `--date`：同时指定时使用 `--folder` 的值作为文件夹名
- 未指定 `--date` 时，必须手动提供 `--title` 和 `--slug`
- 脚本幂等：重复执行不会创建重复文档
- 如果文档已存在则跳过创建
- 自动确保知识库和指定文件夹存在
- 文档创建后自动归入指定文件夹
