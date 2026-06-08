#!/bin/bash
# save.sh — 将复盘内容追加到持久化日志
#
# 用法:
#   bash save.sh <TASK_TITLE> <CONTENT>
#
# 参数:
#   TASK_TITLE  任务标题（如 "ISA Validation Framework"）
#   CONTENT     复盘正文（Markdown 格式）
#
# 日志位置: ~/.agent_cfg/retrospective/log.md
# 格式: 按日期倒序，最新在前

set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "用法: bash save.sh <TASK_TITLE> <CONTENT>" >&2
    exit 2
fi

TITLE="$1"
CONTENT="$2"
LOG_DIR="${HOME}/.agent_cfg/retrospective"
LOG_FILE="${LOG_DIR}/log.md"
DATE="$(date '+%Y-%m-%d %H:%M')"

mkdir -p "$LOG_DIR"

# 新条目
ENTRY="---

## [${DATE}] ${TITLE}

${CONTENT}
"

if [ -f "$LOG_FILE" ]; then
    # 插入到文件头部（最新在前）
    TMPFILE="$(mktemp)"
    {
        echo "$ENTRY"
        cat "$LOG_FILE"
    } > "$TMPFILE"
    mv "$TMPFILE" "$LOG_FILE"
else
    # 首次创建
    {
        echo "# Retrospective Log"
        echo ""
        echo "$ENTRY"
    } > "$LOG_FILE"
fi

RULES_FILE="${LOG_DIR}/rules.md"
echo "saved: ${LOG_FILE}"
echo "rules: ${RULES_FILE}"
echo "title: ${TITLE}"
echo "date:  ${DATE}"
echo ""
echo "ACTION: 请将本次教训提炼为规则，追加到 ${RULES_FILE}"
