#!/bin/bash
# 运行 QEMU (通过 buildrootX 的 scripts 目录下的启动脚本)
# 用法: run_qemu.sh [BUILDROOT_DIR] [QEMU_RUN_SCRIPT]

BUILDROOT_DIR="${1:-/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX}"
QEMU_RUN="${2:-run_aia_mainline_cxl.sh}"

cd "$BUILDROOT_DIR" || exit 1

echo "=== 启动 QEMU (script=$QEMU_RUN) ==="
bash scripts/"$QEMU_RUN"
