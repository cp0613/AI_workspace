---
name: riscv-env-check
description: 检查 ~/.agent_cfg/riscv_env.sh 是否存在、 TOOLCHAIN 和 QEMU 路径是否有效。env.sh 不存在时提供模板生成。所有依赖此环境的 skill（opensbi-build、opensbi-qemu-run 等）执行前必须先通过此检查。
---

# RISC-V 环境检查

校验 `~/.agent_cfg/riscv_env.sh` 配置文件及其中定义的 TOOLCHAIN / QEMU 路径。是 `opensbi-build`、`opensbi-qemu-run` 等依赖此环境 skill 的前置依赖。

## 触发条件

- 在执行 `opensbi-build`、`opensbi-qemu-run` 等 build/运行 skill **之前**自动执行
- 用户说"检查环境 / 检查工具链 / check env"等
- 首次在新环境中使用 RISC-V 开发工具时

## 提供的脚本（位于本 skill 的 `scripts/` 目录）

| 脚本 | 用途 | 典型调用 |
|------|------|----------|
| `check.sh` | 校验 env.sh 存在性 + 所有 TOOLCHAIN / QEMU 路径有效性 | `bash scripts/check.sh` |
| `gen-template.sh` | 生成 env.sh 模板文件 | `bash scripts/gen-template.sh` |

## check.sh 参数表

| 参数 | 默认 | 说明 |
|------|------|------|
| `--toolchain T` | 全部 | 只检查 `xuantie` 或 `upstream` |
| `--xlen N` | 全部 | 只检查 `32` 或 `64` |
| `--quiet` | off | 仅输出错误，不打印 OK 行 |

## gen-template.sh 参数表

| 参数 | 默认 | 说明 |
|------|------|------|
| `--output PATH` | `~/.agent_cfg/riscv_env.sh` | 输出路径 |
| `--force` | off | 覆盖已有文件 |

## 退出码

| 退出码 | 含义 |
|--------|------|
| `0` | 全部通过 |
| `1` | env.sh 不存在 |
| `2` | 存在无效路径 |

## 执行流程

### 场景 A：env.sh 不存在

```bash
bash scripts/check.sh
# → ERROR: ~/.agent_cfg/riscv_env.sh 不存在
# → 提示使用 gen-template.sh 生成模板
```

生成模板：

```bash
bash scripts/gen-template.sh
# → 模板已生成: ~/.agent_cfg/riscv_env.sh
# → 请编辑该文件，将 /path/to/... 替换为实际路径
```

用户编辑后再次检查：

```bash
bash scripts/check.sh
```

### 场景 B：env.sh 存在，全部通过

```bash
bash scripts/check.sh
# → === RISC-V 环境检查 ===
# →   OK    XUANTIE_CROSS_COMPILE_64: riscv64-unknown-linux-gnu-gcc (Xuantie ...) 14.3.0
# →   OK    XUANTIE_QEMU_64: QEMU emulator version 8.2.94
# →   ...
# → === 检查完毕: 8 项全部通过 ===
```

### 场景 C：部分路径无效

```bash
bash scripts/check.sh
# →   OK    XUANTIE_CROSS_COMPILE_64: ...
# →   FAIL  UPSTREAM_QEMU_32: /path/to/.../qemu-system-riscv32 不存在或不可执行
# → === 检查完毕: 8 项中有 1 项失败 ===
```

### 场景 D：只检查特定工具链/位宽

```bash
bash scripts/check.sh --toolchain xuantie --xlen 64
# → 只检查 XUANTIE_CROSS_COMPILE_64 和 XUANTIE_QEMU_64
```

## 与依赖 TOOLCHAIN / QEMU 环境 skill 的关系

**执行依赖 TOOLCHAIN / QEMU 环境的 skill 前，必须先运行此检查并确保通过。**

典型流程：

```
riscv-env-check  →  opensbi-build  →  opensbi-qemu-run
   (通过)              (编译)            (验证)
```

如果 `check.sh` 返回非 0，不应继续执行后续 build/run 操作。

## 检查项

| 变量 | 类型 | 验证方式 |
|------|------|----------|
| `XUANTIE_CROSS_COMPILE_64` | GCC 前缀 | `<prefix>gcc` 可执行 |
| `XUANTIE_CROSS_COMPILE_32` | GCC 前缀 | `<prefix>gcc` 可执行 |
| `XUANTIE_QEMU_64` | QEMU 路径 | 文件可执行 |
| `XUANTIE_QEMU_32` | QEMU 路径 | 文件可执行 |
| `UPSTREAM_CROSS_COMPILE_64` | GCC 前缀 | `<prefix>gcc` 可执行 |
| `UPSTREAM_CROSS_COMPILE_32` | GCC 前缀 | `<prefix>gcc` 可执行 |
| `UPSTREAM_QEMU_64` | QEMU 路径 | 文件可执行 |
| `UPSTREAM_QEMU_32` | QEMU 路径 | 文件可执行 |

## 关联 skill

- `opensbi-build` —— TOOLCHAIN 编译 OpenSBI，依赖本 skill 的检查结果
- `opensbi-qemu-run` —— QEMU 启动 OpenSBI，依赖本 skill 的检查结果
