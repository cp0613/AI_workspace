---
name: retrospective
description: 任务完成后（尤其是 commit/PR 前后）自动输出执行复盘：列举失误、总结经验、提出 skill 优化建议，并追加到持久化日志。当用户完成一次迭代（编译+测试+提交）、要求复盘、或说"回顾一下"时使用。
---

# 执行复盘（Retrospective）

每次任务迭代完成后，对本轮执行过程做结构化复盘，输出失误、经验和 skill 优化建议。

## 触发条件

以下任一情况应主动触发复盘：

- 用户明确要求：复盘 / retrospective / 回顾一下 / 总结一下
- 一次完整的 编码→编译→测试→提交 迭代结束
- 遇到了非预期的错误并最终解决
- 用户纠正了 agent 的做法

## 复盘结构

输出以下三个部分，使用中文：

### 1. 失误与问题（Mistakes）

列举本次执行中的具体失误，每条包含：

| 字段 | 说明 |
|------|------|
| **现象** | 发生了什么（编译错误、逻辑 bug、重复劳动等） |
| **原因** | 为什么会发生（假设错误、API 理解不到位、遗漏边界条件等） |
| **耗时** | 这个失误导致了多少额外步骤 |
| **教训** | 下次如何避免（可引用为 rule） |

没有失误时写"无"，不要编造。

### 2. 经验沉淀（Learnings）

本次执行中发现的值得记住的技术事实或工作流模式：

- 新发现的 API / 函数 / 代码路径
- 验证方法（如何构造测试场景）
- 工具使用技巧

### 3. Skill 优化建议（Skill Improvements）

针对本次使用的 skill，提出具体可操作的改进建议：

| 字段 | 说明 |
|------|------|
| **目标 Skill** | 哪个 skill 需要改进 |
| **当前问题** | 现在的不足 |
| **建议方案** | 具体怎么改（新增参数、脚本逻辑、文档补充等） |
| **优先级** | high / medium / low |

## 持久化（两层结构）

| 文件 | 用途 | 写入方式 |
|------|------|----------|
| `~/.agent_cfg/retrospective/log.md` | 原始日志，追加记录，供人回溯 | `bash scripts/save.sh` |
| `~/.agent_cfg/retrospective/rules.md` | 活跃规则，从日志提炼，agent 自动加载 | agent 手动编辑追加 |

**闭环机制**：在项目 `CLAUDE.md` 中加一行引用 rules.md，agent 每次启动自动读取，避免重复犯错：

```markdown
<!-- CLAUDE.md 中添加 -->
执行任务前，先读取 ~/.agent_cfg/retrospective/rules.md 中的活跃规则并遵守。
```

```bash
# 保存日志
bash scripts/save.sh "<TASK_TITLE>" "<RETROSPECTIVE_CONTENT>"
```

## 执行流程

### Step 1：收集上下文

回顾本轮执行过程：
- 使用了哪些 skill
- 编译/测试了几次
- 遇到了哪些错误
- 用户有没有纠正

### Step 2：输出复盘

按上述三段结构输出，每段至少覆盖要点，保持简洁（每条 1-2 行）。

### Step 3：持久化

调用 `scripts/save.sh` 将复盘追加到日志文件。

### Step 4：提炼规则到 rules.md

从本次复盘中提取可复用的教训，以编号规则（`[RXXX]`）追加到 `~/.agent_cfg/retrospective/rules.md`。规则格式：

```markdown
### [R003] 规则标题
- 来源: YYYY-MM-DD 任务名
- 原因: 为什么需要这条规则
- 适用: 什么场景下生效
```

只提炼有通用价值的教训，一次性的偶发问题不需要入 rules。

### Step 5：更新相关 Skill（可选）

如果某条 Skill 优化建议优先级为 high 且改动明确，征求用户同意后直接修改对应 SKILL.md 或脚本。

## 示例输出

```
## Retrospective: ISA Extension Validation Framework

### 失误与问题
1. **Plan 中未包含伪代码** — 多字母 token 解析的边界条件在实现时才暴露，
   导致 plan→code 多了一轮思考。教训：涉及字符串解析的 plan 应附伪代码。

### 经验沉淀
- `fdt_parse_cbom_block_size()` 内部会先校验 `device_type=="cpu"`，
  只能在 cpu 节点上调用
- 测试 FDT fixup 的方法：dumpdtb → sed 删属性 → dtc 重编 → -dtb 注入

### Skill 优化建议
| 目标 Skill | 当前问题 | 建议方案 | 优先级 |
|------------|----------|----------|--------|
| opensbi-qemu-run | 测试 DT 修改需手动 3 步 | 新增 `--dtb-patch` 参数 | medium |
| opensbi-build | 编译成功后无改动摘要 | 编译后自动 `git diff --stat` | low |
```

## 此 skill 不做的事

- 不修改代码（除非用户同意更新 skill）
- 不重复执行已完成的任务
- 不给出空洞的"一切顺利"（没有失误就写"无"，但必须有经验和建议）

## 关联 skill

所有 skill 都可能被复盘引用。特别关联：
- `opensbi-build` — 编译相关失误
- `buildroot-build` — 编译相关失误
- `opensbi-qemu-run` — 测试验证相关失误
- `riscv-dev-loop` — 端到端迭代相关失误
