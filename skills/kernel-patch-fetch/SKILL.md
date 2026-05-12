---
name: "kernel-patch-fetch"
description: "通过 NNTP 从 lore.kernel.org 的多个内核邮件列表获取指定日期的 patch 提交记录，按过滤规则筛选后输出 JSON 报表或 Markdown 文档。当用户需要拉取内核邮件列表 patch、获取指定日期的内核补丁记录、将多邮件列表数据转为 Markdown 时使用此技能。"
---

# Kernel Patch 拉取器

通过 NNTP 协议从 lore.kernel.org 的多个内核邮件列表获取指定日期的 patch 提交记录，支持按规则过滤，输出 JSON 报表或 Markdown 文档内容。

## 监控的邮件列表

| 邮件列表 | NNTP Group | 过滤规则 |
|----------|-----------|----------|
| Linux RISC-V | org.infradead.lists.linux-riscv | 全部 patch |
| LKML (主线内核) | org.kernel.vger.linux-kernel | 仅含 fix/improve/enhance/optimize 等关键字 |
| Linux Perf Users | org.kernel.vger.linux-perf-users | 仅含 riscv 关键字 |

## 工作流程

### 获取 Patch 并输出 JSON

```bash
python3 scripts/fetch_patches.py --format json --output /tmp/riscv_patches.json
```

### 获取 Patch 并输出 Markdown（默认）

```bash
python3 scripts/fetch_patches.py --md-output /tmp/riscv_patches.md
```

### 同时输出 JSON 和 Markdown

```bash
python3 scripts/fetch_patches.py --format both \
  --output /tmp/riscv_patches.json \
  --md-output /tmp/riscv_patches.md
```

## 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--date` | str | 昨天 | 指定日期 (YYYY-MM-DD) |
| `--output` | str | stdout | JSON 输出文件路径 |
| `--md-output` | str | stdout | Markdown 输出文件路径 |
| `--format` | str | json | 输出格式: `json` / `markdown` / `both` |
| `--lists` | str | 全部 | 逗号分隔的列表 ID，如 `linux-riscv,lkml` |
| `--server` | str | nntp.lore.kernel.org | NNTP 服务器地址 |

## 输出格式

### JSON 结构

```json
{
  "date": "2026-05-10",
  "total_count": 25,
  "mailing_lists": [
    {
      "id": "linux-riscv",
      "display_name": "Linux RISC-V",
      "filter": "all",
      "total_count": 21,
      "patches": [...],
      "summary": { "patch_new": 6, "patch_update": 14, "rfc": 0, "discussion": 1 }
    }
  ]
}
```

### Markdown 结构

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

---

*数据来源: [lore.kernel.org](https://lore.kernel.org/)*
```

## 注意事项

- NNTP 协议支持按日期范围精确获取，无条数限制（Atom feed 每次最多 25 条）
- LKML 流量极大，默认往前扫描 2000 条以覆盖完整一天
- 脚本幂等：重复执行同一日期不会重复获取
