---
name: opensbi-qemu-run
description: 把编译好的 OpenSBI 固件（fw_dynamic / fw_jump / fw_payload）送进 QEMU RISC-V virt 机型启动，提供两种模式：socket 模式（通过 socat 实现 agent 自动化）和交互模式（前台便于人工调试）。默认使用 xuantie-qemu。当 `opensbi-build` 完成后需要验证，或用户要求在 QEMU 中测试/验证 OpenSBI 改动时使用。
---

# OpenSBI QEMU 启动

把 OpenSBI 启动到 QEMU `virt` 机型上。两种模式：**socket**（默认，agent 通过 socat 驱动）和 **交互**（前台供人工调试）。仅 QEMU 仿真，不涉及真机。

## 触发条件

- `opensbi-build` 成功后用户要验证
- 用户说"跑起来 / 启动 / QEMU 里测一下 / 看 banner / 验证 fw_dynamic 能否启动"等
- 在可控环境中复现 SBI bug

## 提供的脚本（位于本 skill 的 `scripts/` 目录）

| 脚本 | 用途 | 典型调用 |
|------|------|----------|
| `launch.sh` | 启动 QEMU（含预检 + 清理残留 + 创建 logfile） | `bash scripts/launch.sh --bios <fw>` |
| `read.sh`   | 从 logfile 读取 QEMU 串口输出（支持超时/正则提前退出） | `bash scripts/read.sh 5 /tmp/qemu_opensbi.log "Boot HART MEDELEG"` |
| `send.sh`   | 向 QEMU 串口 socket 发送一行命令 | `bash scripts/send.sh "help"` |
| `cleanup.sh`| 停 QEMU + 删 socket/log | `bash scripts/cleanup.sh` |

所有脚本带 `-h/--help` 输出参数说明；全部有合理默认值，绝大多数场景只需 `launch.sh --bios <fw>` + `read.sh`。

## 默认值

| 项 | 默认值 | 覆盖方式 |
|----|--------|----------|
| QEMU 可执行文件 | `~/.agent_cfg/riscv_env.sh` 中 `RISCV_QEMU_64`（默认 xuantie-qemu） | `--toolchain upstream` / 环境变量 `QEMU_RISCV64` |
| 机型 | `virt` | （固定） |
| 内存 | `512M` | `launch.sh --mem` |
| SMP | `2` | `launch.sh --smp` |
| 模式 | `socket` | `launch.sh --interactive` |
| Socket 路径 | `/tmp/qemu_opensbi.sock` | `launch.sh --sock` |
| Logfile 路径 | `/tmp/qemu_opensbi.log` | `launch.sh --log` |
| 固件 | CWD 下 `build/platform/generic/firmware/fw_dynamic.bin` | `launch.sh --bios` |

> xuantie-qemu 支持 XUANTIE 自定义 CSR 和指令。测纯上游 SBI 用 `--toolchain upstream` 即可切换到标准 QEMU。
> 工具链和 QEMU 路径统一在 `~/.agent_cfg/riscv_env.sh` 配置，支持 xuantie / upstream 两套，32/64 位独立路径。

## launch.sh 参数表

| 参数 | 默认 | 说明 |
|------|------|------|
| `--bios PATH` | `build/platform/generic/firmware/fw_dynamic.bin` | OpenSBI 固件二进制 |
| `--kernel PATH` | — | 可选 Linux `Image` / U-Boot 二进制（fw_jump 场景） |
| `--initrd PATH` | — | 可选 initramfs |
| `--append "STR"` | — | 内核命令行（仅配合 `--kernel` 生效） |
| `--mem SIZE` | `512M` | 内存大小 |
| `--smp N` | `2` | HART 数 |
| `--interactive` | off | 前台 `-nographic` 模式 |
| `--sock PATH` | `/tmp/qemu_opensbi.sock` | 仅 socket 模式 |
| `--log PATH` | `/tmp/qemu_opensbi.log` | 仅 socket 模式 |
| `--gdb PORT` | — | 追加 `-gdb tcp::PORT -S` |
| `--xlen 32\|64` | `64` | 选择 32/64 位 QEMU（`qemu-system-riscv32` / `riscv64`） |
| `--toolchain T` | xuantie | `xuantie` / `upstream`，选择 `~/.agent_cfg/riscv_env.sh` 中定义的 QEMU |
| `--extra "ARGS"` | — | 末尾追加的原始 QEMU 参数 |

## 执行流程

### Step 1：校验固件 & 启动

由 `launch.sh` 自动完成（预检 → 清理残留 → 启动 QEMU）：

```bash
bash scripts/launch.sh --bios build/platform/generic/firmware/fw_dynamic.bin
```

socket 模式下，脚本输出形如：

```
QEMU_PID=12345
SOCK=/tmp/qemu_opensbi.sock
LOG=/tmp/qemu_opensbi.log
BIOS=build/platform/generic/firmware/fw_dynamic.bin
```

> **关键设计**：socket 模式在 `-chardev socket` 上挂了 `logfile=...,logappend=off`。
> QEMU 串口的所有输出会同步落盘，**即使 socat 还没连上**，banner 也不会丢失。

### Step 2：读取 banner / 等待关键字

通过 `read.sh` 从 logfile 拉取（不直连 socket）：

```bash
# 读 5s 内的全部输出
bash scripts/read.sh 5

# 等到 "Boot HART MEDELEG" 出现就立即返回（最长 5s）
bash scripts/read.sh 5 /tmp/qemu_opensbi.log "Boot HART MEDELEG"
```

纯 SBI 验证场景重点关注：

```
OpenSBI v...
Platform Name               : ...
Boot HART ID                : ...
```

### Step 3（可选）：发送命令

```bash
bash scripts/send.sh "help"             # 在 U-Boot/Linux shell 里发命令
bash scripts/send.sh ""                 # 仅发回车
```

发送后再用 `read.sh` 抓回显。

### Step 4：收尾清理（必做）

```bash
bash scripts/cleanup.sh
```

不要留下游离 QEMU 进程 —— 它们会占住 socket，阻塞下次启动。

### 交互模式

需要人工敲键时：

```bash
bash scripts/launch.sh --bios <fw> --interactive
# 前台 -nographic，按 Ctrl-A x 退出
```

交互模式下不需要 `read.sh` / `send.sh` / `cleanup.sh`。

## GDB 调试

```bash
bash scripts/launch.sh --bios <fw> --gdb 123456
# 另开终端：
riscv64-buildroot-linux-gnu-gdb build/platform/generic/firmware/fw_dynamic.elf \
    -ex 'target remote localhost:123456'
```

## 启动前预检（`launch.sh` 自动完成）

| 检查 | 失败时的提示 |
|------|--------------|
| `$QEMU_RISCV64` 可执行 | 提示设置环境变量 |
| `--bios` 存在 | 提示先跑 `opensbi-build` |
| socket 模式下 `socat` 可用 | 提示 `apt install socat` |
| `--kernel` / `--initrd` 存在（若提供） | 报告缺失路径 |
| 同 socket 残留 QEMU/socket 文件 | 自动清理 |
| socket 在 2s 内创建 | 失败则报错并 kill QEMU |

## 此 skill 不做的事

- 不烧写真机
- 不集成 buildrootX（端到端联调走 `riscv-dev-loop`）
- 不自动生成 kernel/rootfs —— 由调用方通过 `--kernel` / `--initrd` 提供
- 不做持久化 —— 每次启动都是全新 QEMU 实例

## 前置依赖

**启动前必须先执行 `riscv-env-check`**，确保 `~/.agent_cfg/riscv_env.sh` 存在且 QEMU 路径有效。

```bash
bash <riscv-env-check>/scripts/check.sh --toolchain xuantie --xlen 64
# 通过后再执行 launch
bash scripts/launch.sh --bios <fw>
```

## 关联 skill

- `riscv-env-check` —— 前置：校验 QEMU 环境
- `opensbi-build` —— 产出 `fw_*.bin` 给 `--bios` 使用
- `riscv-dev-loop` —— 端到端循环（含 kernel + rootfs）
