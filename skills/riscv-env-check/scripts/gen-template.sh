#!/bin/bash
# gen-template.sh — 生成 ~/.agent_cfg/riscv_env.sh 模板
#
# 用法:
#   bash gen-template.sh [--output PATH]
#
# 选项:
#   --output PATH  输出路径（默认 ~/.agent_cfg/riscv_env.sh）
#
# 如果目标文件已存在，不会覆盖（除非加 --force）。

set -euo pipefail

OUTPUT="$HOME/.agent_cfg/riscv_env.sh"
FORCE="false"

while [ $# -gt 0 ]; do
    case "$1" in
        --output) OUTPUT="$2"; shift 2 ;;
        --force)  FORCE="true"; shift ;;
        -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
        *)         echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

if [ -f "$OUTPUT" ] && [ "$FORCE" != "true" ]; then
    echo "ERROR: $OUTPUT 已存在，不会覆盖。" >&2
    echo "       使用 --force 强制覆盖，或手动编辑该文件。" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

cat > "$OUTPUT" << 'TEMPLATE'
#!/bin/bash
# ~/.agent_cfg/riscv_env.sh — RISC-V TOOLCHAIN 与 QEMU 全局配置
#
# 使用方式:
#   source ~/.agent_cfg/riscv_env.sh
#
# 所有变量均可被环境变量覆盖（已设置则不覆盖）。
# 脚本中通过 RISCV_TOOLCHAIN=xuantie|upstream 选择活跃配置。

# ============================================================
# Xuantie 工具集
# ============================================================
# 64 位交叉编译器前缀（以 - 结尾）
: "${XUANTIE_CROSS_COMPILE_64:=/path/to/xuantie/bin/riscv64-unknown-linux-gnu-}"
# 32 位交叉编译器前缀（xuantie multilib 可与 64 位相同）
: "${XUANTIE_CROSS_COMPILE_32:=$XUANTIE_CROSS_COMPILE_64}"
# 64 位 QEMU
: "${XUANTIE_QEMU_64:=/path/to/xuantie-qemu/bin/qemu-system-riscv64}"
# 32 位 QEMU
: "${XUANTIE_QEMU_32:=/path/to/xuantie-qemu/bin/qemu-system-riscv32}"

# ============================================================
# Upstream 工具集（32/64 位独立前缀）
# ============================================================
: "${UPSTREAM_CROSS_COMPILE_64:=/path/to/upstream/bin/riscv64-linux-gnu-}"
: "${UPSTREAM_CROSS_COMPILE_32:=/path/to/upstream/bin/riscv32-linux-gnu-}"
: "${UPSTREAM_QEMU_64:=/path/to/upstream-qemu/bin/qemu-system-riscv64}"
: "${UPSTREAM_QEMU_32:=/path/to/upstream-qemu/bin/qemu-system-riscv32}"

# ============================================================
# 活跃配置选择: xuantie (默认) | upstream
# ============================================================
: "${RISCV_TOOLCHAIN:=xuantie}"

case "$RISCV_TOOLCHAIN" in
    xuantie)
        RISCV_CROSS_COMPILE_64="$XUANTIE_CROSS_COMPILE_64"
        RISCV_CROSS_COMPILE_32="$XUANTIE_CROSS_COMPILE_32"
        RISCV_QEMU_64="$XUANTIE_QEMU_64"
        RISCV_QEMU_32="$XUANTIE_QEMU_32"
        ;;
    upstream)
        RISCV_CROSS_COMPILE_64="$UPSTREAM_CROSS_COMPILE_64"
        RISCV_CROSS_COMPILE_32="$UPSTREAM_CROSS_COMPILE_32"
        RISCV_QEMU_64="$UPSTREAM_QEMU_64"
        RISCV_QEMU_32="$UPSTREAM_QEMU_32"
        ;;
    *)
        echo "WARNING: unknown RISCV_TOOLCHAIN='$RISCV_TOOLCHAIN', falling back to xuantie" >&2
        RISCV_CROSS_COMPILE_64="$XUANTIE_CROSS_COMPILE_64"
        RISCV_CROSS_COMPILE_32="$XUANTIE_CROSS_COMPILE_32"
        RISCV_QEMU_64="$XUANTIE_QEMU_64"
        RISCV_QEMU_32="$XUANTIE_QEMU_32"
        ;;
esac

export XUANTIE_CROSS_COMPILE_64 XUANTIE_CROSS_COMPILE_32 XUANTIE_QEMU_64 XUANTIE_QEMU_32
export UPSTREAM_CROSS_COMPILE_64 UPSTREAM_CROSS_COMPILE_32 UPSTREAM_QEMU_64 UPSTREAM_QEMU_32
export RISCV_TOOLCHAIN RISCV_CROSS_COMPILE_64 RISCV_CROSS_COMPILE_32 RISCV_QEMU_64 RISCV_QEMU_32
TEMPLATE

echo "模板已生成: $OUTPUT"
echo "请编辑该文件，将 /path/to/... 替换为实际路径。"
echo "完成后运行以下命令验证:"
echo ""
echo "  bash $(dirname "$0")/check.sh"
