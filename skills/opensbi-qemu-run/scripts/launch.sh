#!/bin/bash
# launch.sh — 启动 QEMU virt 运行 OpenSBI 固件
#
# 用法:
#   bash launch.sh [选项]
#
# 选项 (全部可选；默认 socket 模式 + fw_dynamic.bin):
#   --bios PATH       OpenSBI 固件（默认 build/platform/generic/firmware/fw_dynamic.bin）
#   --kernel PATH     可选 kernel/U-Boot 二进制
#   --initrd PATH     可选 initramfs
#   --append "STR"    内核命令行（需配合 --kernel）
#   --mem SIZE        内存大小（默认 512M）
#   --smp N           HART 数（默认 2）
#   --interactive     前台 -nographic 模式（默认 socket 模式）
#   --sock PATH       socket 路径（默认 /tmp/qemu_opensbi.sock）
#   --log PATH        QEMU 串口 logfile（默认 /tmp/qemu_opensbi.log）
#   --gdb PORT        追加 -gdb tcp::PORT -S
#   --toolchain T     xuantie | upstream（选择 QEMU，默认由 ~/.agent_cfg/riscv_env.sh 决定）
#   --extra "ARGS"    末尾追加的原始 QEMU 参数
#
# 环境变量:
#   QEMU_RISCV64      qemu-system-riscv64 路径（覆盖全局配置）
#
# socket 模式：后台启动 QEMU，输出同时落到 logfile（防止 banner 早于 client 连接时丢失），
#              脚本立即返回并打印 PID/SOCK/LOG。
# 交互模式：    前台 exec QEMU，按 Ctrl-A x 退出。

set -euo pipefail

# ---- 加载全局 RISC-V 工具链配置 ----
[ -f ~/.agent_cfg/riscv_env.sh ] && source ~/.agent_cfg/riscv_env.sh

QEMU="${QEMU_RISCV64:-${RISCV_QEMU_64:-/mnt/ssd/workarea/chenp/qemu/xuantie-qemu-x86_64-Ubuntu-20.04-CI/bin/qemu-system-riscv64}}"
XLEN="64"
BIOS=""
KERNEL=""
INITRD=""
APPEND=""
MEM="512M"
SMP="2"
MODE="socket"
SOCK="/tmp/qemu_opensbi.sock"
LOG="/tmp/qemu_opensbi.log"
GDB=""
EXTRA=""

while [ $# -gt 0 ]; do
    case "$1" in
        --bios)        BIOS="$2"; shift 2 ;;
        --kernel)      KERNEL="$2"; shift 2 ;;
        --initrd)      INITRD="$2"; shift 2 ;;
        --append)      APPEND="$2"; shift 2 ;;
        --mem)         MEM="$2"; shift 2 ;;
        --smp)         SMP="$2"; shift 2 ;;
        --interactive) MODE="interactive"; shift ;;
        --sock)        SOCK="$2"; shift 2 ;;
        --log)         LOG="$2"; shift 2 ;;
        --gdb)         GDB="$2"; shift 2 ;;
        --xlen)        XLEN="$2"; shift 2 ;;
        --toolchain)   export RISCV_TOOLCHAIN="$2"; source ~/.agent_cfg/riscv_env.sh 2>/dev/null; shift 2 ;;
        --extra)       EXTRA="$2"; shift 2 ;;
        -h|--help)     sed -n '2,30p' "$0"; exit 0 ;;
        *)             echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

# ---- QEMU 路径解析（根据 xlen 选择 32/64 位）----
if [ "$XLEN" = "32" ] && [ -n "${RISCV_QEMU_32:-}" ]; then
    QEMU="$RISCV_QEMU_32"
elif [ -n "${RISCV_QEMU_64:-}" ]; then
    QEMU="$RISCV_QEMU_64"
fi

# ---- preflight ----
if [ ! -x "$QEMU" ]; then
    echo "ERROR: QEMU 不可执行: $QEMU" >&2
    echo "       设置环境变量 QEMU_RISCV64 指向 qemu-system-riscv64" >&2
    exit 1
fi

if [ -z "$BIOS" ]; then
    BIOS="build/platform/generic/firmware/fw_dynamic.bin"
fi
if [ ! -f "$BIOS" ]; then
    echo "ERROR: BIOS 文件不存在: $BIOS" >&2
    echo "       先执行 opensbi-build 生成固件" >&2
    exit 1
fi

if [ -n "$KERNEL" ] && [ ! -f "$KERNEL" ]; then
    echo "ERROR: KERNEL 文件不存在: $KERNEL" >&2; exit 1
fi
if [ -n "$INITRD" ] && [ ! -f "$INITRD" ]; then
    echo "ERROR: INITRD 文件不存在: $INITRD" >&2; exit 1
fi

# ---- build qemu argv ----
ARGS=(-M virt -m "$MEM" -smp "$SMP" -bios "$BIOS" -display none)
[ -n "$KERNEL" ] && ARGS+=(-kernel "$KERNEL")
[ -n "$INITRD" ] && ARGS+=(-initrd "$INITRD")
[ -n "$APPEND" ] && ARGS+=(-append "$APPEND")
[ -n "$GDB" ]    && ARGS+=(-gdb "tcp::${GDB}" -S)

if [ "$MODE" = "interactive" ]; then
    ARGS+=(-serial mon:stdio -nographic)
    # shellcheck disable=SC2086
    [ -n "$EXTRA" ] && ARGS+=($EXTRA)
    echo "=== QEMU (interactive) ===" >&2
    echo "  bios=$BIOS" >&2
    [ -n "$KERNEL" ] && echo "  kernel=$KERNEL" >&2
    echo "  按 Ctrl-A x 退出" >&2
    exec "$QEMU" "${ARGS[@]}"
fi

# socket 模式
if ! command -v socat >/dev/null; then
    echo "ERROR: socat 未安装（apt install socat）" >&2; exit 1
fi

# 清理同 socket 的残留实例（仅匹配本 socket 路径，避免误杀）
pkill -f "qemu-system-riscv64.*${SOCK}" 2>/dev/null || true
rm -f "$SOCK" "$LOG"

# logfile=...,logappend=off 确保 banner 即使在 client 连上前打印也能被捕获
ARGS+=(-chardev "socket,id=serial0,path=${SOCK},server=on,wait=off,logfile=${LOG},logappend=off")
ARGS+=(-serial chardev:serial0)
# shellcheck disable=SC2086
[ -n "$EXTRA" ] && ARGS+=($EXTRA)

nohup "$QEMU" "${ARGS[@]}" >/dev/null 2>&1 &
PID=$!

# 等待 socket 文件出现（最多 2s）
for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -S "$SOCK" ] && break
    sleep 0.2
done

if [ ! -S "$SOCK" ]; then
    echo "ERROR: socket 未在 2s 内创建（QEMU 可能已退出）" >&2
    kill "$PID" 2>/dev/null || true
    exit 1
fi

echo "QEMU_PID=$PID"
echo "SOCK=$SOCK"
echo "LOG=$LOG"
echo "BIOS=$BIOS"
