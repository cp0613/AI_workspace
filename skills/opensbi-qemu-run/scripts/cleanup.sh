#!/bin/bash
# cleanup.sh — 收尾：停止 QEMU、删除 socket 与 logfile
#
# 用法:
#   bash cleanup.sh [SOCK] [LOG]
#
# 参数:
#   SOCK  socket 路径（默认 /tmp/qemu_opensbi.sock）
#   LOG   logfile 路径（默认 /tmp/qemu_opensbi.log）
#
# pkill 模式严格匹配 socket 路径，避免误杀其他 QEMU 实例。

set -uo pipefail

SOCK="${1:-/tmp/qemu_opensbi.sock}"
LOG="${2:-/tmp/qemu_opensbi.log}"

pkill -f "qemu-system-riscv64.*${SOCK}" 2>/dev/null || true
sleep 0.2

# 二次确认 + SIGKILL 回收
if pgrep -f "qemu-system-riscv64.*${SOCK}" >/dev/null 2>&1; then
    pkill -9 -f "qemu-system-riscv64.*${SOCK}" 2>/dev/null || true
    sleep 0.2
fi

rm -f "$SOCK" "$LOG"
echo "cleaned: SOCK=$SOCK LOG=$LOG"
exit 0
