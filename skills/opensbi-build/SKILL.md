---
name: opensbi-build
description: 使用 `make PLATFORM=generic` 独立编译 OpenSBI（支持 RV32/RV64、fw_dynamic/fw_jump/fw_payload），通过 scripts/build.sh 封装；默认工具链为 xuantie-gcc multilib（可通过 CROSS_COMPILE 覆盖）。适合纯 SBI 改动的快速迭代，兼容 xuantie 厂商分支和上游 mainline。当用户要求编译 OpenSBI、构建 fw_* 镜像、或需要 SBI 二进制用于 QEMU 测试时使用此 skill。
---

# OpenSBI 独立编译

绕开 buildrootX、直接用工具链编译 OpenSBI 的轻量路径。改动只涉及 SBI（不需要重建内核/根文件系统）时使用。若要做端到端联调，请改用 `riscv-dev-loop`。

## 触发条件

- 用户说"编译 OpenSBI / 构建 fw_dynamic / make fw_dynamic"等
- 当前位于 OpenSBI 仓库内（根目录同时存在 `Makefile` 和 `lib/sbi/sbi_init.c`）
- 改动只涉及 SBI（不动 kernel/rootfs/dts，无需走 buildroot 全量重建）

如果改动同时涉及 kernel/rootfs，建议改用 `riscv-dev-loop` 或 `buildroot-build`。

## 提供的脚本（位于本 skill 的 `scripts/` 目录）

| 脚本 | 用途 | 典型调用 |
|------|------|----------|
| `build.sh` | 编译 OpenSBI（含参数解析 + 工具链解析 + 报错处理 + 产物列表） | `bash scripts/build.sh` |
| `clean.sh` | `make distclean` | `bash scripts/clean.sh` |

`build.sh` 默认即可（RV64 + fw_dynamic + debug + xuantie toolchain），常见场景一行命令即可。

## 默认值

| 项 | 默认值 | 覆盖方式 |
|----|--------|----------|
| 仓库根 | 当前目录 | `--repo PATH` |
| `PLATFORM` | `generic` | `--platform` |
| XLEN | `64` | `--xlen 32` |
| `FW_TYPE` | `dynamic` | `--fw-type jump|payload|all` |
| 工具链 | `~/.agent_cfg/riscv_env.sh` 中 `RISCV_CROSS_COMPILE_64` | `--toolchain upstream` / `--cross-compile P` / `$CROSS_COMPILE` |
| `DEBUG` | on | `--debug` |
| `-j` | `$(nproc)` | `--jobs N` |

> **xuantie 工具链是 multilib**：同一个前缀同时支持 rv32/rv64。upstream 工具链 32/64 位使用独立前缀，通过 `RISCV_CROSS_COMPILE_32` / `RISCV_CROSS_COMPILE_64` 自动切换。

## build.sh 参数表

| 参数 | 默认 | 说明 |
|------|------|------|
| `--repo PATH` | CWD | OpenSBI 仓库根，必须包含 `Makefile` + `lib/sbi/sbi_init.c` |
| `--platform NAME` | `generic` | 几乎一直是 generic；vendor 子目录通过 FDT 自动匹配 |
| `--xlen 32\|64` | `64` | 设置 `PLATFORM_RISCV_XLEN`；ABI 自动派生（ilp32 / lp64） |
| `--fw-type T` | `dynamic` | `dynamic` / `jump` / `payload` / `all`（all = dynamic+jump，含 payload 时需 --payload） |
| `--payload PATH` | — | fw_payload 用的 Linux `Image` 或 U-Boot 二进制 |
| `--jump-addr ADDR` | — | fw_jump 入口地址（`FW_JUMP_ADDR=...`） |
| `--debug` | on | 追加 `DEBUG=1 BUILD_INFO=y`（默认已开） |
| `--no-debug` | — | 关闭 DEBUG / BUILD_INFO，编出 release 优化版本 |
| `--clean` | off | 编译前 `make distclean` |
| `--jobs N` | nproc | `-j` 并行度 |
| `--toolchain T` | xuantie | `xuantie` / `upstream`，选择 `~/.agent_cfg/riscv_env.sh` 中定义的工具链 |
| `--cross-compile P` | — | 覆盖 `CROSS_COMPILE`（优先级高于一切） |
| `--extra "VAR=VAL"` | — | 追加任意 make KV，可多次给 |

## 工具链解析优先级

1. CLI `--cross-compile <prefix>`（最高）
2. `$CROSS_COMPILE` 环境变量
3. `~/.agent_cfg/riscv_env.sh` → `RISCV_CROSS_COMPILE_64` / `RISCV_CROSS_COMPILE_32`（由 `--toolchain` 或 `$RISCV_TOOLCHAIN` 选择）
4. 内置硬编码 fallback

`--xlen 32` 时优先使用 `RISCV_CROSS_COMPILE_32`。

解析后会校验 `<prefix>gcc` 存在；找不到时直接报错并提示如何覆盖。

## 执行流程

### Step 1：定位 OpenSBI 仓库根

`build.sh --repo` 缺省取当前目录。若 CWD 不是 OpenSBI 仓库，需指定：

- `/mnt/ssd/workarea/chenp/riscv/opensbi_xuantie`
- `/mnt/ssd/workarea/chenp/riscv/opensbi_mainline`

### Step 2：编译

```bash
# 默认：RV64 + fw_dynamic + xuantie toolchain
bash scripts/build.sh

# 显式所有参数
bash scripts/build.sh --xlen 64 --fw-type dynamic

# RV32
bash scripts/build.sh --xlen 32

# fw_jump
bash scripts/build.sh --fw-type jump

# fw_payload + Linux Image
bash scripts/build.sh --fw-type payload --payload /path/to/Image

# 一次产出 fw_dynamic + fw_jump（+ payload 如果给了）
bash scripts/build.sh --fw-type all

# 用 upstream 工具链
bash scripts/build.sh --toolchain upstream

# 用任意工具链覆盖
bash scripts/build.sh --cross-compile riscv64-linux-gnu-

# 调试 + 全量重建
bash scripts/build.sh --clean --debug
```

启动时脚本会打印 plan（REPO / XLEN / FW_TYPE / CROSS / GCC ver / JOBS）。

### Step 3：定位产物

成功后脚本自动打印产物绝对路径，形如：

```
=== Artifacts ===
  /.../build/platform/generic/firmware/fw_dynamic.bin
  /.../build/platform/generic/firmware/fw_dynamic.elf
```

也可手工查看 `<repo>/build/platform/<platform>/firmware/`。

### Step 4：错误处理

`build.sh` 失败时已自动 `tail -n 30` 失败日志到 stderr。常见对照表：

| 症状 | 可能原因 |
|------|----------|
| `command not found: ...-gcc` | 工具链路径错误；检查 `--cross-compile` 或默认路径是否存在 |
| `undefined reference to ...` | `objects.mk` 漏注册新源文件；检查新加文件是否登记 |
| `ABI mismatch` / `incompatible ABI` | RV32/RV64 与已编译对象混用；先 `bash scripts/clean.sh` |
| `No rule to make target FW_PAYLOAD_PATH` | `--fw-type payload` 但忘了 `--payload` |
| 刚拉代码就 `Error 2` | 先 `bash scripts/clean.sh` 再重建 |

**不要静默重试** —— 把错误和建议方案展示给用户。

## 快速验证流程（编译 + 启动）

```bash
bash scripts/build.sh
# → 调用 opensbi-qemu-run 验证 banner
```

## 此 skill 不做的事

- 不构建/刷新 Linux 内核、U-Boot 或 rootfs（这些走 buildrootX）
- 不烧写真机（受众是 QEMU 仿真）
- 不修改 OpenSBI 仓库源码

## 前置依赖

**编译前必须先执行 `riscv-env-check`**，确保 `~/.agent_cfg/riscv_env.sh` 存在且 TOOLCHAIN 路径有效。

```bash
bash <riscv-env-check>/scripts/check.sh --toolchain xuantie --xlen 64
# 通过后再执行 build
bash scripts/build.sh
```

## 关联 skill

- `riscv-env-check` —— 前置：校验 TOOLCHAIN / QEMU 环境
- `opensbi-qemu-run` —— 把编译产物送进 QEMU virt 启动
- `riscv-dev-loop` —— 完整的 buildrootX 编译+运行循环（kernel/rootfs 也变动时用）
- `buildroot-build` —— 从 buildrootX 根目录走 `make CONF=<defconfig> opensbi`
