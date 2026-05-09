#!/bin/bash
# 增量编译内核 (通过 buildroot)
# 用法: build_kernel.sh [BUILDROOT_DIR] [DEFCONFIG]

BUILDROOT_DIR="${1:-/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX}"
DEFCONFIG="${2:-qemu_cxl_defconfig}"

cd "$BUILDROOT_DIR" || exit 1

echo "=== 增量编译内核 (defconfig=$DEFCONFIG) ==="
make CONF="$DEFCONFIG" linux-dirclean
make CONF="$DEFCONFIG" linux-rebuild
make CONF="$DEFCONFIG" linux-reinstall
