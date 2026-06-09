---
name: kernel-build-matrix
description: 内核多架构编译矩阵，用于使用不同的工具链、不同的 defconfig、不同的架构目标编译内核，测试内核源码修改对各种架构的编译兼容性。当用户要求交叉编译内核、多架构编译测试、验证编译兼容性、或说"编译矩阵/build matrix"时使用此 skill。
---

# 内核多架构编译矩阵

在单棵内核源码树上，使用不同 ARCH + CROSS_COMPILE + defconfig 组合编译内核，快速验证代码修改对各架构的编译兼容性。

## 触发条件

- 用户说"多架构编译 / build matrix / 编译矩阵 / 交叉编译测试"等
- 修改了跨架构的头文件（`include/linux/`、`include/uapi/`）或 Kbuild/Kconfig 后，需要验证不影响其他架构
- 用户说"验证 arm64/x86 编译是否通过"

## 提供的脚本（位于本 skill 的 `scripts/` 目录）

| 脚本 | 用途 | 典型调用 |
|------|------|----------|
| `build-matrix.sh` | 按矩阵组合顺序编译，汇总 pass/fail | `bash scripts/build-matrix.sh` |

## 内置矩阵（默认）

不传参数时使用以下默认矩阵：

| ARCH | CROSS_COMPILE | defconfig | EXTRA_CFLAGS |
|------|---------------|-----------|-------------|
| `arm64` | `aarch64-linux-gnu-` | `defconfig` | `-Werror -g` |
| `x86_64` | *(native)* | `x86_64_defconfig` 或 `defconfig` | `-Werror -g` |
| `riscv` (64) | `riscv64-unknown-linux-gnu-` (xuantie) | `xuantie_defconfig` | `-Werror -g` |

## 自定义矩阵

### --target 格式

`ARCH:CROSS_COMPILE:DEFCONFIG`

- **ARCH** — 内核架构名：`riscv`、`arm64`、`x86_64`、`arm`、`mips` 等
- **CROSS_COMPILE** — 交叉编译工具链前缀；留空表示 native 编译；RISC-V 架构留空或填 `__RISCV_ENV__` 时自动从 `~/.agent_cfg/riscv_env.sh` 读取 `RISCV_CROSS_COMPILE_64/32`
- **DEFCONFIG** — defconfig 名称，对应 `arch/$ARCH/configs/` 下的文件

```bash
# 单个目标
bash scripts/build-matrix.sh \
  --target "arm64:aarch64-linux-gnu-:defconfig"

# 多个目标
bash scripts/build-matrix.sh \
  --target "arm64:aarch64-linux-gnu-:defconfig" \
  --target "x86_64::defconfig" \
  --target "riscv::xuantie_defconfig"
```

### 可选目标参考

| ARCH | CROSS_COMPILE | DEFCONFIG | 说明 |
|------|---------------|-----------|------|
| `riscv` | *(留空，自动)* | `defconfig` | RISC-V 64 默认 |
| `riscv` | *(留空，自动)* | `xuantie_defconfig` | 玄铁平台 |
| `riscv` | *(留空，自动)* | `xuantie_rv32_defconfig` | 玄铁 RV32 |
| `arm64` | `aarch64-linux-gnu-` | `defconfig` | ARM64 默认 |
| `arm64` | `aarch64-linux-gnu-` | `allmodconfig` | ARM64 全模块 |
| `x86_64` | *(留空，native)* | `defconfig` | x86_64 默认 |
| `x86_64` | *(留空，native)* | `x86_64_defconfig` | x86_64 完整 |
| `x86_64` | *(留空，native)* | `allmodconfig` | x86_64 全模块 |
| `arm` | `arm-linux-gnueabihf-` | `multi_v7_defconfig` | ARM32 多平台 |
| `mips` | `mips-linux-gnu-` | `malta_defconfig` | MIPS Malta |

## 参数表

| 参数 | 默认 | 说明 |
|------|------|------|
| `--src PATH` | CWD | 内核源码树根目录 |
| `--target SPEC` | 内置矩阵 | `ARCH:CROSS_COMPILE:DEFCONFIG`，可多次指定 |
| `--extra-cflags FLAGS` | `-Werror -g` | 追加到 EXTRA_CFLAGS |
| `--extra-kcflags FLAGS` | — | 追加到 KCFLAGS（内核 C 编译选项） |
| `--jobs N` | `$(nproc)` | `-j` 并行度 |
| `--targets-only` | off | 只编译 `vmlinux`，不编译模块（加速） |
| `--modules` | on | 编译模块（`modules` target），`--no-modules` 跳过 |
| `--stop-on-error` | on | 某个目标失败后立即停止；`--continue-on-error` 继续编译下一个 |
| `--clean` | off | 每个目标编译前 `make clean` |
| `--out-dir PATH` | — | `O=` 输出目录前缀，每个目标自动追加 ARCH 子目录 |
| `--dry-run` | off | 只打印 plan，不执行编译 |

## 执行流程

### Step 0：列出编译计划和命令

编译前**必须**先向用户展示完整的编译计划，列出每个目标将要执行的 make 命令（含完整路径和参数），等用户确认后再开始实际编译。格式示例：

```
[1/3] arm64
  make -C <src> ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j96 defconfig
  make -C <src> ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j96 all "EXTRA_CFLAGS+=-Werror -g"

[2/3] x86_64
  make -C <src> ARCH=x86 -j96 defconfig
  make -C <src> ARCH=x86 -j96 all "EXTRA_CFLAGS+=-Werror -g"

[3/3] riscv
  make -C <src> ARCH=riscv CROSS_COMPILE=<xuantie-prefix> -j96 xuantie_defconfig
  make -C <src> ARCH=riscv CROSS_COMPILE=<xuantie-prefix> -j96 all "EXTRA_CFLAGS+=-Werror -g"
```

### Step 1：定位内核源码

`--src` 缺省取当前目录。校验 `Makefile` 和 `scripts/` 存在。

### Step 2：依次编译矩阵中每个目标

对每个 `(ARCH, CROSS_COMPILE, DEFCONFIG)` 组合：

1. 打印编译 plan（ARCH、工具链版本、defconfig 名）
2. `make ARCH=$ARCH CROSS_COMPILE=$CROSS $DEFCONFIG`
3. `make ARCH=$ARCH CROSS_COMPILE=$CROSS all -j$JOBS EXTRA_CFLAGS+="$EXTRA_CFLAGS"`
4. 可选 `make ARCH=$ARCH CROSS_COMPILE=$CROSS modules`
5. 记录 pass/fail 和耗时
6. 默认失败即停止，不继续下一个目标

### Step 3：汇总报告

```
╔══════════════════════════════════════════════════════╗
║              Kernel Build Matrix Report              ║
╠══════════╦═══════════════════╦════════╦══════════════╣
║ ARCH     ║ DEFCONFIG         ║ STATUS ║ TIME         ║
╠══════════╬═══════════════════╬════════╬══════════════╣
║ arm64    ║ defconfig         ║ PASS   ║ 3m 42s       ║
║ x86_64   ║ defconfig         ║ PASS   ║ 4m 15s       ║
║ riscv    ║ defconfig         ║ FAIL   ║ 1m 03s       ║
╚══════════╩═══════════════════╩════════╩══════════════╝
```

失败的目标会附带最后 30 行错误日志。

## 工具链查找

优先级（从高到低）：

1. `--target` 中显式指定的 CROSS_COMPILE（最高）
2. 对 RISC-V 架构：CROSS_COMPILE 留空或 `__RISCV_ENV__` → 自动读取 `~/.agent_cfg/riscv_env.sh` 中的 `RISCV_CROSS_COMPILE_64`（riscv32 用 `RISCV_CROSS_COMPILE_32`）
3. 系统 PATH 中的 `${CROSS_COMPILE}gcc`

| ARCH | 默认工具链 |
|------|-----------|
| `arm64` | `aarch64-linux-gnu-` (系统 PATH) |
| `x86_64` | native `gcc` 或 `x86_64-linux-gnu-` |
| `riscv` | `riscv_env.sh` → `RISCV_CROSS_COMPILE_64` |
| `riscv32` | `riscv_env.sh` → `RISCV_CROSS_COMPILE_32` |

## 典型用例

```bash
# 默认矩阵（arm64 + x86_64 + riscv64）
bash scripts/build-matrix.sh

# 干跑查看 plan
bash scripts/build-matrix.sh --dry-run

# 只测 arm64
bash scripts/build-matrix.sh --target "arm64:aarch64-linux-gnu-:defconfig"

# riscv 工具链留空，自动使用 riscv_env.sh
bash scripts/build-matrix.sh \
  --target "riscv::xuantie_defconfig" \
  --target "arm64:aarch64-linux-gnu-:defconfig"

# 指定内核树 + 只编译 vmlinux（加速）
bash scripts/build-matrix.sh --src /path/to/linux --targets-only

```

## 错误处理

| 症状 | 可能原因 |
|------|----------|
| `command not found: ...-gcc` | 工具链未安装或路径错误 |
| `No rule to make target '..._defconfig'` | defconfig 名称错误，检查 `arch/$ARCH/configs/` |
| `CROSS_COMPILE=` 时链接错误 | 本机编译器目标与 ARCH 不匹配 |
| 只有某个 ARCH 失败 | 修改引入了架构相关的编译问题，检查错误日志 |

## 此 skill 不做的事

- 不运行/启动编译出的内核（运行测试用 `riscv-dev-loop` 或 `opensbi-qemu-run`）
- 不修改内核源码
- 不自动安装缺失的工具链

## 关联 skill

- `riscv-env-check` —— 验证 RISC-V 工具链环境
- `riscv-dev-loop` —— 完整开发循环（编译+运行+迭代）
- `buildroot-build` —— 基于 buildroot 的完整镜像编译
