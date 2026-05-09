#!/usr/bin/env python3
"""Auto-start QEMU with CXL, wait for boot, run commands, output results."""
import socket, time, subprocess, sys, os

SOCK_PATH = '/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX/tmp/qemu_cxl.sock'
OUT_FILE = '/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX/tmp/qemu_cxl_result.txt'
BR_DIR = '/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX'

def read_all(s, timeout=5):
    s.settimeout(timeout)
    data = b''
    while True:
        try:
            chunk = s.recv(65536)
            if chunk:
                data += chunk
            else:
                break
        except socket.timeout:
            break
    return data.decode('utf-8', errors='replace')

def send_cmd(s, cmd, wait=3):
    s.send((cmd + '\n').encode())
    time.sleep(wait)

# Kill any existing QEMU
subprocess.run(['pkill', '-f', 'qemu-system-riscv64.*qemu_cxl'], capture_output=True)
time.sleep(2)
if os.path.exists(SOCK_PATH):
    os.unlink(SOCK_PATH)

# Start QEMU
qemu_cmd = [
    f'{BR_DIR}/qemu_cxl_defconfig/host/bin/qemu-system-riscv64',
    '-M', 'virt,pflash0=pflash0,pflash1=pflash1,aia=aplic-imsic,acpi=on,cxl=on',
    '-cpu', 'rv64,sscofpmf=true,svpbmt=true,v=true,vlen=256',
    '-smp', '2',
    '-m', '4G,maxmem=8G,slots=8',
    '-object', 'memory-backend-ram,id=vmem0,share=on,size=4G',
    '-device', 'pxb-cxl,bus_nr=12,bus=pcie.0,id=cxl.1',
    '-device', 'cxl-rp,port=0,bus=cxl.1,id=root_port13,chassis=0,slot=2',
    '-device', 'cxl-type3,bus=root_port13,volatile-memdev=vmem0,id=cxl-vmem0',
    '-M', 'cxl-fmw.0.targets.0=cxl.1,cxl-fmw.0.size=4G',
    '-chardev', f'socket,id=serial0,path={SOCK_PATH},server=on,wait=off',
    '-serial', 'chardev:serial0',
    '-display', 'none',
    '-blockdev', f'node-name=pflash0,driver=file,read-only=on,filename={BR_DIR}/qemu_cxl_defconfig/build/edk2-edk2-stable202508/Build/RiscVVirtQemu/RELEASE_GCC5/FV/RISCV_VIRT_CODE.fd.padded',
    '-blockdev', f'node-name=pflash1,driver=file,filename={BR_DIR}/qemu_cxl_defconfig/build/edk2-edk2-stable202508/Build/RiscVVirtQemu/RELEASE_GCC5/FV/RISCV_VIRT_VARS.fd.padded',
    '-bios', f'{BR_DIR}/qemu_cxl_defconfig/images/fw_dynamic.bin',
    '-kernel', f'{BR_DIR}/qemu_cxl_defconfig/images/Image',
    '-append', 'root=/dev/vda console=ttyS0 earlycon=sbi norandmaps loglevel=7 no5lvl',
    '-drive', f'file={BR_DIR}/qemu_cxl_defconfig/images/rootfs.ext2,format=raw,id=hd0,if=none',
    '-device', 'virtio-blk-device,drive=hd0',
]

print(f"Starting QEMU from {BR_DIR}...")
proc = subprocess.Popen(qemu_cmd, cwd=BR_DIR, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print(f"QEMU PID: {proc.pid}")

# Wait for socket
for i in range(30):
    if os.path.exists(SOCK_PATH):
        break
    time.sleep(1)
else:
    print("ERROR: Socket never appeared!")
    sys.exit(1)

time.sleep(3)

# Connect
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(SOCK_PATH)
print("Connected to serial socket")

# Wait for login prompt
print("Waiting for login prompt (60-90s for EDK2+kernel)...")
login_found = False
for attempt in range(60):
    data = read_all(s, timeout=3)
    if data and 'login' in data.lower():
        login_found = True
        print(f"Login prompt found after ~{attempt*3}s!")
        break
    if attempt % 10 == 9:
        print(f"  Still waiting... ({attempt*3}s)")

if not login_found:
    print("WARNING: No login prompt, trying anyway...")

# Login
s.send(b'root\n')
time.sleep(5)
login_echo = read_all(s, timeout=3)

if '# ' in login_echo or '$ ' in login_echo or 'root@' in login_echo:
    print("Shell prompt detected!")
else:
    print("No shell prompt yet, waiting more...")
    time.sleep(10)
    read_all(s, timeout=2)

# Send commands
cmds = [
    ('ls /sys/bus/cxl/devices/', 4),
    ('cxl list', 4),
    ('ls /sys/bus/cxl/devices/root0/ 2>/dev/null', 4),
    ('find /sys/bus/cxl/ -name port\* -o -name endpoint\* 2>/dev/null', 4),
    ('dmesg | grep -iE "cxl|EPROBE_DEFER|ACPI0016|ACPI0017|defer" | tail -50', 10),
    ('dmesg | grep -iE "add_dport|add_port|uport|dport|CHBS|CHBCR|host supports|port registr" | head -20', 10),
]

all_output = ''
for cmd, wait in cmds:
    send_cmd(s, cmd, wait=wait)
    out = read_all(s, timeout=wait+5)
    all_output += out

with open(OUT_FILE, 'w') as f:
    f.write(all_output)

print(f"Results written to {OUT_FILE}")
print("=== OUTPUT ===")
print(all_output)
print("=== END ===")

s.close()
proc.terminate()
print("QEMU terminated.")
