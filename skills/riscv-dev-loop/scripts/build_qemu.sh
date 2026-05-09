#!/bin/bash
# 增量编译 QEMU (通过 buildroot)
# 用法: build_qemu.sh [BUILDROOT_DIR] [DEFCONFIG] [PACKAGE_QEMU]

BUILDROOT_DIR="${1:-/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX}"
DEFCONFIG="${2:-qemu_cxl_defconfig}"
PACKAGE_QEMU="${3:-host-qemu-local}"

cd "$BUILDROOT_DIR" || exit 1

echo "=== 增量编译 QEMU (defconfig=$DEFCONFIG, package=$PACKAGE_QEMU) ==="
make CONF="$DEFCONFIG" "$PACKAGE_QEMU"-dirclean
make CONF="$DEFCONFIG" "$PACKAGE_QEMU"-rebuild
make CONF="$DEFCONFIG" "$PACKAGE_QEMU"-reinstall
