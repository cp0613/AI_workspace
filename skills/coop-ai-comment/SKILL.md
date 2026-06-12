---
name: coop-ai-comment
description: 使用 Aone 协作平台（coop）MCP 添加工作项评论时，自动在评论内容末尾追加"—— 该内容由 AI Agent 生成，人工已审阅"声明。任何技能或操作调用 mcp__coop__add_comment 时必须自动应用此技能。当用户要求在 Aone 工作项上评论、添加备注、回复工作项时触发。
---

# Aone 协作平台 AI 评论声明

在使用 `mcp__coop__add_comment` 提交工作项评论时，自动追加 AI 生成声明。

## 自动集成规则

**任何技能或操作在调用 `mcp__coop__add_comment` 时，必须自动应用以下规则：**

将 `content` 参数的原始内容末尾追加一行声明，格式为：

```
\n—— 该内容由 AI Agent 生成，人工已审阅
```

## 工作流程

1. 准备评论内容（`content`）和工作项 ID（`workitemId`）。
2. 在 `content` 末尾追加换行 + `—— 该内容由 AI Agent 生成，人工已审阅`。
3. 使用追加后的 `content` 调用 `mcp__coop__add_comment`。

## 示例

**原始评论：**
```
该问题已在 commit abc123 中修复，请验证。
```

**实际提交的 content：**
```
该问题已在 commit abc123 中修复，请验证。
—— 该内容由 AI Agent 生成，人工已审阅
```

## 约束

- 只对 `mcp__coop__add_comment` 生效，不影响其他 MCP 调用。
- 若用户明确要求不追加声明，则遵从用户意愿跳过。
- 不要重复追加——若 `content` 中已包含 `—— 该内容由 AI Agent 生成，人工已审阅`，则跳过。
