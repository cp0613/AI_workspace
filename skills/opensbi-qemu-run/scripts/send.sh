#!/bin/bash
# send.sh — 通过 socat 向 QEMU 串口 socket 发送一行命令
#
# 用法:
#   bash send.sh <CMD> [SOCK]
#
# 参数:
#   CMD   要发送的命令字符串（脚本会自动追加换行）
#   SOCK  socket 路径（默认 /tmp/qemu_opensbi.sock）
#
# 示例:
#   bash send.sh ""          # 仅发回车
#   bash send.sh "help"      # 在 U-Boot/Linux shell 里发命令
#
# 注意：本脚本只负责"发"，不读响应。读取请配合 read.sh，
#       或在 send 之前已有 read.sh 在后台 tail logfile。

set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "用法: bash send.sh <CMD> [SOCK]" >&2
    exit 2
fi

CMD="$1"
SOCK="${2:-/tmp/qemu_opensbi.sock}"

if [ ! -S "$SOCK" ]; then
    echo "ERROR: socket 不存在: $SOCK" >&2
    echo "       先用 launch.sh 启动 QEMU socket 模式" >&2
    exit 1
fi

if ! command -v socat >/dev/null; then
    echo "ERROR: socat 未安装（apt install socat）" >&2
    exit 1
fi

printf '%s\n' "$CMD" | socat - "UNIX-CONNECT:${SOCK}"
