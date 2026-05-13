---
name: riscv-tech-proposal
description: 根据用户提供的技术描述和文档链接，撰写符合 RISC-V 国际社区规范的技术提案（Tech Proposal），输出为 Markdown 格式。当用户要求撰写 proposal、技术提案、RISC-V 扩展提案、ISA 提案、架构特性提案时使用。用户需提供技术点描述、规范文档链接等输入。
---

# RISC-V Tech Proposal 撰写

## 概述

根据用户提供的技术点描述和参考资料，撰写符合 RISC-V 国际社区规范的英文技术提案，输出为 Markdown 文件。

## Proposal 结构模板

所有 proposal 必须包含以下章节，顺序和标题如下：

```
1. Proposer          — 提案人信息
2. Introduction      — 提案概述（1-2段）
3. Motivation and Problem Statement  — 动机与问题陈述
4. Definitions       — 关键术语定义表
5. Background        — 技术背景与行业现状
6. Proposed Solution — 具体技术方案
7. Objectives        — 提案目标与交付物
8. Exclusions (Optional) — 不在范围内的内容
9. Collaborations    — 合作 SIG/TG
10. Sponsoring Organizations — 赞助组织
11. Milestones       — 里程碑计划（可选）
12. References       — 参考文献列表
```

详细模板见 [proposal-template.md](proposal-template.md)。

## 各章节撰写要点

### 1. Proposer
- 包含 Name 和 Organization/Affiliation
- 如有多位作者，列出所有

### 2. Introduction
- 1-2 段概述提案核心内容
- 用一句话说清"我们在做什么"
- 第二段说明为什么重要、预期影响

### 3. Motivation and Problem Statement
- 分子章节阐述不同维度的痛点（如：可扩展性、虚拟化、性能等）
- 每个痛点用具体场景和量化数据支撑
- 必须包含 **Why Existing Extensions Are Insufficient** 小节，逐一分析现有 RISC-V 扩展为何无法满足需求

### 4. Definitions
- 表格形式，两列：Term | Definition
- 列出所有缩写和专业术语
- 如：RERI, KFM, FFM, ACPI, CSR 等

### 5. Background
- 分子章节提供技术背景：
  - 相关 RISC-V 现有机制详述
  - 其他架构（x86/ARM）的同类解决方案
  - Linux 内核中的相关子系统现状
- 引用规范文档和实际代码实现

### 6. Proposed Solution
- 核心技术方案的详细描述
- 可包含：
  - 架构设计（寄存器定义、接口规范、数据结构）
  - 硬件/软件交互流程
  - 与现有机制的兼容性说明
  - 图表说明（如拓扑图、流程图、寄存器布局图）

### 7. Objectives
- 以 bullet list 列出具体目标
- 每个 objective 使用动词开头（Define, Implement, Enable, Ensure 等）
- 区分必须项和可选项

### 8. Exclusions (Optional)
- 明确说明不在本次提案范围内的内容
- 如适用则填写，否则写 "None"

### 9. Collaborations
- 列出需要合作的 RISC-V SIG/TG
- 常见：Datacenter SIG, Platform Runtime Services TG, Linux SIG, Hypervisor SIG 等

### 10. Sponsoring Organizations
- 列出支持此提案的组织
- 格式：组织名称列表

### 11. Milestones
- 表格形式，两列：Milestone | Description
- 通常 5-7 个里程碑：TG Formation → Spec Draft → Community Review → PoC → Ratification

### 12. References
- 编号列表，格式：`[N] Title: URL` 或 `[N] Title, Document Identifier`
- 引用来源包括：RISC-V 规范、学术论文、Linux 内核文档、社区补丁、厂商规范

## 写作规范

1. **语言**：英文撰写（RISC-V 国际社区标准）
2. **时态**：Introduction 用现在时，Background 用过去时描述现状，Proposed Solution 用将来时
3. **风格**：正式技术文档，避免口语化
4. **引用**：在正文中用 `[N]` 标注引用，在 References 中给出完整链接
5. **术语一致性**：首次出现时给出全称+缩写，后续使用缩写
6. **客观性**：问题陈述用数据和场景支撑，避免主观评价

## 工作流程

1. 收集用户输入：技术点描述、文档链接、提案人信息
2. 如用户提供了文档链接，使用 search_web / fetch_content 获取参考资料内容
3. 搜索相关 RISC-V 规范、Linux 内核代码、社区讨论作为支撑材料
4. 按模板结构撰写 proposal 各章节（Markdown 格式）
5. 输出文件到用户指定目录，默认保存到 `<skill_dir>/../../knowledge/gen/proposal/`，文件名格式：`<Proposal Title> Proposal of Work.md`

## 输出格式

输出为标准 Markdown 文件，使用以下 Markdown 语法规范：

- 章节标题使用 `##`（对应 H2），子章节使用 `###`（对应 H3）
- Definitions 使用 Markdown 表格：`| Term | Definition |`
- Milestones 使用 Markdown 表格：`| Milestone | Description |`
- References 使用编号列表：`1. Title: URL`
- 文件名格式：`<Proposal Title> Proposal of Work.md`
- 文件保存到 `<skill_dir>/../../knowledge/gen/proposal/` 目录
