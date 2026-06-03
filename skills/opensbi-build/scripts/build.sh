#!/bin/bash
# build.sh — 编译 OpenSBI（PLATFORM=generic，支持 RV32/RV64）
#
# 用法:
#   bash build.sh [选项]
#
# 选项 (全部可选):
#   --repo PATH          OpenSBI 仓库根（默认当前目录）
#   --platform NAME      默认 generic
#   --xlen 32|64         RV32 或 RV64（默认 64）
#   --fw-type TYPE       dynamic | jump | payload | all（默认 dynamic）
#   --payload PATH       fw_payload 用的 Image / U-Boot 二进制（type=payload 时必填）
#   --jump-addr ADDR     fw_jump 入口地址（type=jump 时可选）
#   --debug              传 DEBUG=1 + BUILD_INFO=y（默认已开，等效 no-op）
#   --no-debug           关闭 DEBUG / BUILD_INFO（生成 release 优化版本）
#   --clean              先 make distclean
#   --jobs N             -jN（默认 $(nproc)）
#   --toolchain T        xuantie | upstream（默认由 ~/.agent_cfg/riscv_env.sh 决定）
#   --cross-compile P    覆盖 CROSS_COMPILE（也可用同名环境变量）
#   --extra "VAR=VAL"    追加到 make 命令行的原始 KV（可多次）
#
# 工具链配置:
#   全局路径定义在 ~/.agent_cfg/riscv_env.sh（xuantie / upstream 两套）
#   通过 --toolchain 或 RISCV_TOOLCHAIN 环境变量选择
#
# 优先级:
#   1. CLI --cross-compile（最高）
#   2. $CROSS_COMPILE 环境变量
#   3. ~/.agent_cfg/riscv_env.sh 中 RISCV_CROSS_COMPILE
#
# 退出码: make 的退出码透传。失败时打印最后 30 行日志辅助定位。

set -uo pipefail

# ---- 加载全局 RISC-V 工具链配置 ----
[ -f ~/.agent_cfg/riscv_env.sh ] && source ~/.agent_cfg/riscv_env.sh

REPO=""
PLATFORM="generic"
XLEN="64"
FW_TYPE="dynamic"
PAYLOAD=""
JUMP_ADDR=""
DEBUG_FLAGS=("DEBUG=1" "BUILD_INFO=y")
CLEAN="false"
JOBS=""
CROSS_OVERRIDE=""
EXTRA=()

while [ $# -gt 0 ]; do
    case "$1" in
        --repo)           REPO="$2"; shift 2 ;;
        --platform)       PLATFORM="$2"; shift 2 ;;
        --xlen)           XLEN="$2"; shift 2 ;;
        --fw-type)        FW_TYPE="$2"; shift 2 ;;
        --payload)        PAYLOAD="$2"; shift 2 ;;
        --jump-addr)      JUMP_ADDR="$2"; shift 2 ;;
        --debug)          DEBUG_FLAGS=("DEBUG=1" "BUILD_INFO=y"); shift ;;
        --no-debug)       DEBUG_FLAGS=(); shift ;;
        --clean)          CLEAN="true"; shift ;;
        --jobs)           JOBS="$2"; shift 2 ;;
        --toolchain)      export RISCV_TOOLCHAIN="$2"; shift 2 ;;
        --cross-compile)  CROSS_OVERRIDE="$2"; shift 2 ;;
        --extra)          EXTRA+=("$2"); shift 2 ;;
        -h|--help)        sed -n '2,33p' "$0"; exit 0 ;;
        *)                echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

# ---- repo 定位 ----
if [ -z "$REPO" ]; then
    REPO="$(pwd)"
fi
if [ ! -f "$REPO/Makefile" ] || [ ! -f "$REPO/lib/sbi/sbi_init.c" ]; then
    echo "ERROR: $REPO 不是 OpenSBI 仓库（缺 Makefile 或 lib/sbi/sbi_init.c）" >&2
    echo "       用 --repo 指定，例如 /mnt/ssd/workarea/chenp/riscv/opensbi_xuantie" >&2
    exit 1
fi

# ---- 参数校验 ----
case "$XLEN" in
    32|64) ;;
    *) echo "ERROR: --xlen 只支持 32 或 64（当前 $XLEN）" >&2; exit 2 ;;
esac

case "$FW_TYPE" in
    dynamic|jump|payload|all) ;;
    *) echo "ERROR: --fw-type 只支持 dynamic|jump|payload|all（当前 $FW_TYPE）" >&2; exit 2 ;;
esac

if [ "$FW_TYPE" = "payload" ] || [ "$FW_TYPE" = "all" ]; then
    if [ -n "$PAYLOAD" ] && [ ! -f "$PAYLOAD" ]; then
        echo "ERROR: payload 不存在: $PAYLOAD" >&2; exit 1
    fi
    if [ "$FW_TYPE" = "payload" ] && [ -z "$PAYLOAD" ]; then
        echo "ERROR: --fw-type payload 必须配合 --payload PATH" >&2; exit 2
    fi
fi

# ---- 工具链解析 ----
# --toolchain 会重新触发 env.sh 的 case 分支（已在上面 export RISCV_TOOLCHAIN）
if [ "${RISCV_TOOLCHAIN:-}" != "" ] && [ -f ~/.agent_cfg/riscv_env.sh ]; then
    source ~/.agent_cfg/riscv_env.sh
fi

if [ -n "$CROSS_OVERRIDE" ]; then
    CROSS="$CROSS_OVERRIDE"
elif [ -n "${CROSS_COMPILE:-}" ]; then
    CROSS="$CROSS_COMPILE"
elif [ "$XLEN" = "32" ] && [ -n "${RISCV_CROSS_COMPILE_32:-}" ]; then
    CROSS="$RISCV_CROSS_COMPILE_32"
elif [ -n "${RISCV_CROSS_COMPILE_64:-}" ]; then
    CROSS="$RISCV_CROSS_COMPILE_64"
else
    CROSS="/rvhome/chenp/toolchain/gcc/Xuantie-900-gcc-linux-6.6.36-glibc-x86_64-V3.4.0/bin/riscv64-unknown-linux-gnu-"
fi

GCC_BIN="${CROSS}gcc"
if [ ! -x "$GCC_BIN" ]; then
    # 允许 GCC 在 PATH 中（前缀里不一定是绝对路径）
    if ! command -v "$(basename "$GCC_BIN")" >/dev/null 2>&1; then
        echo "ERROR: 找不到 ${GCC_BIN}" >&2
        echo "       覆盖方法：--cross-compile <prefix> 或 export CROSS_COMPILE=<prefix>" >&2
        exit 1
    fi
fi

# ---- 并行 ----
if [ -z "$JOBS" ]; then
    JOBS="$(nproc 2>/dev/null || echo 4)"
fi

# ---- 组装 FW_*=y 标志 ----
FW_FLAGS=()
case "$FW_TYPE" in
    dynamic) FW_FLAGS+=("FW_DYNAMIC=y") ;;
    jump)    FW_FLAGS+=("FW_JUMP=y") ;;
    payload) FW_FLAGS+=("FW_PAYLOAD=y" "FW_PAYLOAD_PATH=$PAYLOAD") ;;
    all)
        FW_FLAGS+=("FW_DYNAMIC=y" "FW_JUMP=y")
        if [ -n "$PAYLOAD" ]; then
            FW_FLAGS+=("FW_PAYLOAD=y" "FW_PAYLOAD_PATH=$PAYLOAD")
        fi
        ;;
esac
if [ -n "$JUMP_ADDR" ]; then
    FW_FLAGS+=("FW_JUMP_ADDR=$JUMP_ADDR")
fi

# ---- 打印 plan ----
echo "=== OpenSBI build ==="
echo "  REPO       : $REPO"
echo "  PLATFORM   : $PLATFORM"
echo "  XLEN       : $XLEN"
echo "  FW_TYPE    : $FW_TYPE${PAYLOAD:+ (payload=$PAYLOAD)}"
echo "  CROSS      : $CROSS"
echo "  GCC ver    : $("$GCC_BIN" --version 2>/dev/null | head -1)"
echo "  JOBS       : $JOBS"
echo "  DEBUG      : $([ "${#DEBUG_FLAGS[@]}" -gt 0 ] && echo "on (${DEBUG_FLAGS[*]})" || echo off)"
[ "$CLEAN" = "true" ] && echo "  CLEAN      : make distclean first"
echo "===================="

cd "$REPO" || exit 1

# ---- distclean ----
if [ "$CLEAN" = "true" ]; then
    echo "--- make distclean ---"
    make distclean
fi

# ---- 编译 ----
LOG_TMP="$(mktemp -t opensbi_build_XXXX.log)"
trap 'rm -f "$LOG_TMP"' EXIT

set +e
make PLATFORM="$PLATFORM" \
     PLATFORM_RISCV_XLEN="$XLEN" \
     CROSS_COMPILE="$CROSS" \
     "${DEBUG_FLAGS[@]}" \
     "${FW_FLAGS[@]}" \
     "${EXTRA[@]}" \
     -j"$JOBS" > "$LOG_TMP" 2>&1
RC=$?
set -e

# 过滤 linker 噪声（removing unused section 及并行输出的碎片行）
grep -v "removing unused section\|ld\.bfd:\|\.a(.*\.o)" "$LOG_TMP" | grep -v "^'" | grep -v "^$" || true

if [ "$RC" -ne 0 ]; then
    echo "=== BUILD FAILED (rc=$RC) ===" >&2
    echo "--- 最后 30 行日志 ---" >&2
    tail -n 30 "$LOG_TMP" >&2
    exit "$RC"
fi

# ---- 报告产物 ----
OUT_DIR="$REPO/build/platform/$PLATFORM/firmware"
echo "=== Artifacts ==="
for img in fw_dynamic fw_jump fw_payload; do
    BIN="$OUT_DIR/$img.bin"
    ELF="$OUT_DIR/$img.elf"
    if [ -f "$BIN" ]; then
        SZ="$(stat -c%s "$BIN" 2>/dev/null || echo ?)"
        echo "  $BIN  (${SZ} B)"
    fi
    [ -f "$ELF" ] && echo "  $ELF"
done
exit 0
