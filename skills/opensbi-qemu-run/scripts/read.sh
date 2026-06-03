#!/bin/bash
# read.sh — 从 QEMU logfile 读取串口输出
#
# 用法:
#   bash read.sh [SECS] [LOG] [PATTERN]
#
# 参数:
#   SECS     最长等待秒数（默认 5）
#   LOG      logfile 路径（默认 /tmp/qemu_opensbi.log）
#   PATTERN  可选正则；命中后立即返回（默认空 = 读满 SECS 秒）
#
# 行为：
#   - 通过 tail -F 从文件头开始流式输出，line-buffered
#   - 提供 PATTERN 时，sed -u 在命中行后退出（typical: "Boot HART ID"）
#   - 不提供 PATTERN 时，timeout 在 SECS 秒后 SIGTERM tail
#   - 返回码恒为 0（timeout 触发或 pattern 命中都视为成功）

SECS="${1:-5}"
LOG="${2:-/tmp/qemu_opensbi.log}"
PATTERN="${3:-}"

# 等待 logfile 出现（最多 SECS 秒）；tail -F 也能等，但提前判错可以给更友好的提示
WAITED=0
TICK_MS=200
MAX_TICKS=$(( SECS * 5 ))   # 200ms * 5 = 1s
while [ ! -f "$LOG" ] && [ "$WAITED" -lt "$MAX_TICKS" ]; do
    sleep 0.2
    WAITED=$(( WAITED + 1 ))
done
if [ ! -f "$LOG" ]; then
    echo "ERROR: logfile 在 ${SECS}s 内未生成: $LOG" >&2
    echo "       确认 launch.sh 已成功启动 socket 模式 QEMU" >&2
    exit 1
fi

if [ -n "$PATTERN" ]; then
    # sed 命中后退出；tail 收到 SIGPIPE 自动结束；timeout 兜底
    timeout "$SECS" tail -F -n +1 "$LOG" 2>/dev/null | sed -u "/${PATTERN}/q" || true
else
    timeout "$SECS" tail -F -n +1 "$LOG" 2>/dev/null || true
fi
