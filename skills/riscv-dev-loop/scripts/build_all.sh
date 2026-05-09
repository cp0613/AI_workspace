#!/bin/bash
# 全量编译 (内核 + 根文件系统镜像)
# 用法: build_all.sh [BUILDROOT_DIR] [DEFCONFIG]
# 注意: 如果测试涉及加载 ko，则需要使用此方式，保证根文件系统镜像被更新

BUILDROOT_DIR="${1:-/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX}"
DEFCONFIG="${2:-qemu_cxl_defconfig}"

cd "$BUILDROOT_DIR" || exit 1

echo "=== 全量编译 (defconfig=$DEFCONFIG) ==="
make CONF="$DEFCONFIG"
