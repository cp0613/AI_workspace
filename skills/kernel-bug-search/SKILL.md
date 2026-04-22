---
name: kernel-bug-search
description: "[project] 根据关键字、错误日志、panic 堆栈或 commit 信息，在上游社区邮件列表 (lore.kernel.org) 中检索类似的 bug report 和 bug fix patch，输出终端摘要并保存详细报告。支持 LKML、linux-riscv 和 opensbi 邮件列表。当用户提供内核错误日志、crash dump、bug 描述、SBI/固件问题、或要求搜索上游社区是否有类似问题和修复补丁时使用。"
---

# Kernel Bug Search

在 Linux 内核上游邮件列表中搜索类似的 bug report 和 fix patch。

## 触发条件

当用户提供以下内容之一时使用此 skill:
- 内核 panic/oops 日志
- 错误信息或关键字
- Bug 描述
- 函数名或符号
- 使用 `/kernel-bug-search` 命令

## 执行流程

### Step 1: 提取搜索关键字

从用户输入中提取有效搜索关键字:

**如果是一段日志/堆栈**:
1. 提取关键错误信息 (如 `BUG:`, `WARNING:`, `Unable to handle`, `Oops:` 后面的内容)
2. 提取关键函数名 (栈回溯中最相关的 2-3 个函数名)
3. 提取子系统标识 (如 `mm`, `riscv`, `sched`, `net` 等)
4. 去除地址、时间戳等无意义的数字

**如果是关键字/描述**:
1. 直接使用用户提供的关键字
2. 补充可能的技术术语

**关键字优化原则**:
- 组合 2-4 个关键词，避免过长查询
- 准备多组关键字用于多轮搜索
- 优先使用错误类型 + 子系统 + 关键函数名的组合

### Step 2: 搜索 lore.kernel.org

使用 WebFetch 工具搜索以下邮件列表:

**搜索 URL 格式**:
```
https://lore.kernel.org/{list}/?q={query}&x=A
```

**必搜列表**:
- `lkml` - Linux 内核主邮件列表
- `linux-riscv` - RISC-V 子系统邮件列表
- `opensbi` - OpenSBI 邮件列表

**可选列表** (根据子系统判断):
- `linux-mm` - 内存管理
- `linux-block` - 块设备
- `linux-fsdevel` - 文件系统
- `linux-net` - 网络

**搜索语法 (Xapian)**:
- `s:keyword` - 搜索主题
- `f:author` - 按作者过滤
- `b:keyword` - 搜索正文
- `AND`, `OR` - 逻辑运算符
- `+keyword` - 必须包含
- `-keyword` - 排除
- `rt:20240101..20260422` - 日期范围 (YYYYMMDD)
- `d:keyword` - 搜索日期相关

**触发 opensbi 列表的关键词**:
- `OpenSBI`, `SBI`, `M-mode`, `mscratch`, `medeleg`, `mideleg`
- `fw_dynamic`, `fw_jump`, `fw_payload`, `fw_base`
- `sbi_ecall`, `sbi_hsm`, `sbi_pmu`, `sbi_domain`, `sbi_init`
- `cold-boot-harts`, `opensbi-config`
- 涉及 `platform/generic/`、`lib/sbi/`、`lib/utils/fdt/` 等 OpenSBI 源码路径

**OpenSBI 专用查询模板** (list=opensbi):
- 按平台: `s:generic`, `s:thead`, `s:qemu_virt`, `s:sifive`, `s:starfive`
- 按子系统: `fw_dynamic`, `sbi_pmu`, `sbi_hsm`, `sbi_domain`, `fdt_helper`, `fdt_driver`
- 按版本/系列: `s:[PATCH v` + 关键词，过滤补丁系列
- 典型 bug 关键词: `regression`, `panic in M-mode`, `boot fail`, `coldboot stuck`, `pmp violation`

**并行搜索策略**:
1. 使用多个 WebFetch 并行调用，搜索不同邮件列表和不同关键字组合
2. 每个搜索使用 prompt: "从搜索结果中提取所有匹配的邮件条目，对每个条目提取: 1)标题 2)作者 3)日期 4)链接URL 5)简短摘要。如果没有结果请说明。"

### Step 3: 分析搜索结果

对搜索结果进行分类:

| 类别 | 识别方式 |
|------|----------|
| Bug Report | 标题含 `BUG`, `WARNING`, `Oops`, `crash`, `panic`, `regression` |
| Fix Patch | 标题含 `fix`, `Fix`, `[PATCH]`, `resolve`, `repair` |
| Discussion | 标题含 `RFC`, `question`, `issue`, 或不属于以上两类 |

### Step 4: 获取关键邮件详情

对最相关的 3-5 个结果，使用 WebFetch 获取邮件详情页面:
```
https://lore.kernel.org/{list}/{message-id}/
```

提取:
- 完整的补丁内容 (如果是 fix patch)
- Bug 的根因分析
- 修复方案描述
- 相关的 commit hash

### Step 5: 生成报告

**终端摘要** (直接输出):
```
## 搜索结果摘要

### 搜索关键字: xxx

### Bug Reports (N 个)
1. [标题](链接) - 作者, 日期
   摘要: ...

### Fix Patches (N 个)
1. [标题](链接) - 作者, 日期
   修复方案: ...

### 相关讨论 (N 个)
1. [标题](链接) - 作者, 日期
```

**详细报告** (保存文件):
保存到 `<skill_dir>/../../knowledge/gen/bugsearch/` 目录，文件名基于搜索关键字生成 (如 `crash-hotplug-riscv.md`)。

报告模板:

```markdown
# 内核上游社区 Bug 检索报告

## 检索信息
- **关键字**: {keywords}
- **搜索时间**: {date}
- **搜索范围**: LKML, linux-riscv, opensbi (按相关性自动选择)
- **输入内容**: {用户原始输入的摘要}

## 检索结果概览

| 类别 | 数量 | 关键发现 |
|------|------|----------|
| Bug Report | N | ... |
| Fix Patch | N | ... |
| 相关讨论 | N | ... |

## Bug Reports

### 1. {标题}
- **链接**: {url}
- **作者**: {author}
- **日期**: {date}
- **邮件列表**: {list}
- **摘要**: {summary}
- **影响范围**: {affected versions/architectures}

## Fix Patches

### 1. {标题}
- **链接**: {url}
- **作者**: {author}
- **日期**: {date}
- **Commit**: {hash} (如果已合入)
- **修复方案**: {description}
- **关键代码变更**:
  ```diff
  {patch_diff_excerpt}
  ```

## 相关讨论

### 1. {标题}
- **链接**: {url}
- **摘要**: {summary}

## 分析与建议
{基于搜索结果的综合分析，包括:}
- 该问题在上游的状态 (已修复/讨论中/未报告)
- 推荐的修复方案或参考补丁
- 可能需要的后续操作
```

## 无结果处理

如果搜索无结果:
1. 尝试缩减关键字范围 (去掉限制性词语)
2. 尝试使用同义词或相关术语
3. 扩大搜索到 `all` 列表: `https://lore.kernel.org/all/?q={query}&x=A`
4. 如果仍无结果，建议用户:
   - 调整关键字重新搜索
   - 该问题可能尚未被上游报告
   - 建议向相关邮件列表提交 bug report

## 注意事项

- lore.kernel.org 可能响应较慢，如果 WebFetch 超时，使用 WebSearch 作为备选: `site:lore.kernel.org {keywords}`
- 搜索结果单页上限 200 条，使用 `o=200` 参数翻页
- 优先展示最近 1-2 年的结果，较旧的结果标注日期
- 始终提供原始链接，方便用户自行查看完整讨论
