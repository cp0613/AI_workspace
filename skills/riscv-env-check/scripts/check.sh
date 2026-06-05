#!/bin/bash
# check.sh — 校验 ~/.agent_cfg/riscv_env.sh 及其中定义的 TOOLCHAIN / QEMU 路径
#
# 用法:
#   bash check.sh [选项]
#
# 选项:
#   --toolchain T    只检查 xuantie | upstream（默认全部检查）
#   --xlen N         只检查 32 | 64（默认全部检查）
#   --quiet          仅输出错误，不打印 OK 行
#
# 退出码:
#   0  全部通过
#   1  env.sh 不存在
#   2  存在无效路径
#
# 环境变量:
#   RISCV_ENV  覆盖 env.sh 路径（默认 ~/.agent_cfg/riscv_env.sh）

set -uo pipefail

ENV_FILE="${RISCV_ENV:-$HOME/.agent_cfg/riscv_env.sh}"
FILTER_TC=""
FILTER_XLEN=""
QUIET="false"

while [ $# -gt 0 ]; do
    case "$1" in
        --toolchain) FILTER_TC="$2"; shift 2 ;;
        --xlen)      FILTER_XLEN="$2"; shift 2 ;;
        --quiet)     QUIET="true"; shift ;;
        -h|--help)   sed -n '2,18p' "$0"; exit 0 ;;
        *)           echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

# ---- Step 1: env.sh 存在性检查 ----
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE 不存在" >&2
    echo "" >&2
    echo "请创建该文件以配置 RISC-V 工具链和 QEMU 路径。" >&2
    echo "可使用以下命令生成模板：" >&2
    echo "" >&2
    echo "  bash $(dirname "$0")/gen-template.sh" >&2
    echo "" >&2
    echo "生成后请编辑模板，填入实际路径。" >&2
    exit 1
fi

# ---- Step 2: source env.sh ----
source "$ENV_FILE"

# ---- Step 3: 逐项验证 ----
ERRORS=0
CHECKED=0

check_gcc() {
    local label="$1" prefix="$2"
    local gcc="${prefix}gcc"

    CHECKED=$((CHECKED + 1))

    if [ -z "$prefix" ]; then
        echo "  WARN  $label: 路径为空" >&2
        ERRORS=$((ERRORS + 1))
        return
    fi

    if [ -x "$gcc" ]; then
        if [ "$QUIET" != "true" ]; then
            local ver
            ver="$("$gcc" --version 2>/dev/null | head -1)"
            echo "  OK    $label: $ver"
        fi
    elif command -v "$(basename "$gcc")" >/dev/null 2>&1; then
        if [ "$QUIET" != "true" ]; then
            local ver
            ver="$($(basename "$gcc") --version 2>/dev/null | head -1)"
            echo "  OK    $label: $ver (via PATH)"
        fi
    else
        echo "  FAIL  $label: $gcc 不存在或不可执行" >&2
        ERRORS=$((ERRORS + 1))
    fi
}

check_qemu() {
    local label="$1" path="$2"

    CHECKED=$((CHECKED + 1))

    if [ -z "$path" ]; then
        echo "  WARN  $label: 路径为空" >&2
        ERRORS=$((ERRORS + 1))
        return
    fi

    if [ -x "$path" ]; then
        if [ "$QUIET" != "true" ]; then
            local ver
            ver="$("$path" --version 2>/dev/null | head -1)"
            echo "  OK    $label: $ver"
        fi
    else
        echo "  FAIL  $label: $path 不存在或不可执行" >&2
        ERRORS=$((ERRORS + 1))
    fi
}

should_check() {
    local tc="$1" xlen="$2"
    if [ -n "$FILTER_TC" ] && [ "$FILTER_TC" != "$tc" ]; then
        return 1
    fi
    if [ -n "$FILTER_XLEN" ] && [ "$FILTER_XLEN" != "$xlen" ]; then
        return 1
    fi
    return 0
}

echo "=== RISC-V 环境检查 ==="
echo "  配置文件: $ENV_FILE"
echo "  默认工具链: ${RISCV_TOOLCHAIN:-xuantie}"
echo ""

echo "--- Xuantie 工具集 ---"
should_check xuantie 64 && check_gcc  "XUANTIE_CROSS_COMPILE_64" "$XUANTIE_CROSS_COMPILE_64"
should_check xuantie 32 && check_gcc  "XUANTIE_CROSS_COMPILE_32" "$XUANTIE_CROSS_COMPILE_32"
should_check xuantie 64 && check_qemu "XUANTIE_QEMU_64"          "$XUANTIE_QEMU_64"
should_check xuantie 32 && check_qemu "XUANTIE_QEMU_32"          "$XUANTIE_QEMU_32"

echo ""
echo "--- Upstream 工具集 ---"
should_check upstream 64 && check_gcc  "UPSTREAM_CROSS_COMPILE_64" "$UPSTREAM_CROSS_COMPILE_64"
should_check upstream 32 && check_gcc  "UPSTREAM_CROSS_COMPILE_32" "$UPSTREAM_CROSS_COMPILE_32"
should_check upstream 64 && check_qemu "UPSTREAM_QEMU_64"          "$UPSTREAM_QEMU_64"
should_check upstream 32 && check_qemu "UPSTREAM_QEMU_32"          "$UPSTREAM_QEMU_32"

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "=== 检查完毕: $CHECKED 项中有 $ERRORS 项失败 ==="
    echo "请修正 $ENV_FILE 中的路径后重试。" >&2
    exit 2
else
    echo "=== 检查完毕: $CHECKED 项全部通过 ==="
fi
exit 0
