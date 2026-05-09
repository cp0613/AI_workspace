#!/bin/bash
# run_qemu_socket.sh - Start QEMU with serial socket for automated interaction
# Usage: ./run_qemu_socket.sh [commands_to_run]
#   If commands are provided, they will be executed via socat after boot
#   If no commands, QEMU starts and waits for manual socat connection
#
# Socket path: /mnt/ssd/workarea/chenp/xuantie_linux/buildrootX/tmp/qemu_cxl.sock
# Connect manually: socat -,rawer UNIX-CONNECT:/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX/tmp/qemu_cxl.sock

set -e

BR_DIR="/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX"
CONF="qemu_cxl_defconfig"
SOCKET_PATH="${BR_DIR}/tmp/qemu_cxl.sock"
QEMU="${BR_DIR}/${CONF}/host/bin/qemu-system-riscv64"

# Cleanup previous instances
pkill -f "qemu-system-riscv64.*qemu_cxl" 2>/dev/null || true
rm -f "${SOCKET_PATH}"
mkdir -p "${BR_DIR}/tmp"

# Start QEMU in background with serial over UNIX socket
${QEMU} \
    -M virt,pflash0=pflash0,pflash1=pflash1,aia=aplic-imsic,acpi=on,cxl=on \
    -cpu rv64,sscofpmf=true,svpbmt=true,v=true,vlen=256 \
    -smp 2 \
    -m 4G,maxmem=8G,slots=8 \
    -object memory-backend-ram,id=vmem0,share=on,size=4G \
    -device pxb-cxl,bus_nr=12,bus=pcie.0,id=cxl.1 \
    -device cxl-rp,port=0,bus=cxl.1,id=root_port13,chassis=0,slot=2 \
    -device cxl-type3,bus=root_port13,volatile-memdev=vmem0,id=cxl-vmem0 \
    -M cxl-fmw.0.targets.0=cxl.1,cxl-fmw.0.size=4G \
    -chardev socket,id=serial0,path=${SOCKET_PATH},server=on,wait=off \
    -serial chardev:serial0 \
    -display none \
    -blockdev node-name=pflash0,driver=file,read-only=on,filename=${BR_DIR}/${CONF}/build/edk2-edk2-stable202508/Build/RiscVVirtQemu/RELEASE_GCC5/FV/RISCV_VIRT_CODE.fd.padded \
    -blockdev node-name=pflash1,driver=file,filename=${BR_DIR}/${CONF}/build/edk2-edk2-stable202508/Build/RiscVVirtQemu/RELEASE_GCC5/FV/RISCV_VIRT_VARS.fd.padded \
    -bios ${BR_DIR}/${CONF}/images/fw_dynamic.bin \
    -kernel ${BR_DIR}/${CONF}/images/Image \
    -append "root=/dev/vda console=ttyS0 earlycon=sbi norandmaps loglevel=7 no5lvl" \
    -drive file=${BR_DIR}/${CONF}/images/rootfs.ext2,format=raw,id=hd0,if=none \
    -device virtio-blk-device,drive=hd0 &

QEMU_PID=$!
echo "QEMU started with PID ${QEMU_PID}, socket at ${SOCKET_PATH}"

# Wait for socket to appear
for i in $(seq 1 10); do
    [ -S "${SOCKET_PATH}" ] && break
    sleep 1
done

if [ ! -S "${SOCKET_PATH}" ]; then
    echo "ERROR: Socket ${SOCKET_PATH} not found after 10s"
    exit 1
fi

# If commands were provided, execute them via socat
if [ $# -gt 0 ]; then
    echo "Waiting for VM to boot (60s)..."
    sleep 60

    # Build command sequence: login + commands
    CMD_SEQ="root\n"
    for cmd in "$@"; do
        CMD_SEQ="${CMD_SEQ}${cmd}\n"
    done
    # Add exit command to close cleanly
    CMD_SEQ="${CMD_SEQ}echo COMMANDS_DONE\n"

    echo "Sending commands via socat..."
    RESULT=$(echo -e "${CMD_SEQ}" | socat -t 10 - UNIX-CONNECT:${SOCKET_PATH} 2>/dev/null || true)
    echo "${RESULT}"
else
    echo "No commands provided. Connect manually with:"
    echo "  socat -,rawer UNIX-CONNECT:${SOCKET_PATH}"
    echo "Press Ctrl+C to stop QEMU..."
    wait ${QEMU_PID}
fi
