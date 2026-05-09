---
name: buildroot-build
description: 编译基于 buildroot 的镜像，用于 RISC-V 目标平台。当用户要求编译、构建 buildroot 镜像，或提到指定配置名如 qemu_riscv64_virt_efi_mainline_defconfig 时使用。
---

# Buildroot 编译

从项目的 `configs/` 目录编译 buildroot defconfig 镜像。

## 项目信息

- **项目根目录**：仓库根目录`/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX`
- **配置目录**：`configs/`（文件以 `_defconfig` 结尾）
- **编译命令**：`make CONF=<config_name> [target]`（在项目根目录执行）

## 工作流程

### 步骤 1：确定配置

若用户指定了配置名（带或不带 `_defconfig` 后缀），直接使用。否则列出可用配置供用户选择：

```bash
ls configs/
```

使用 `AskUserQuestion` 工具让用户选择一个或多个配置。

### 步骤 2：确定编译目标（可选）

若用户指定了编译目标，追加到 make 命令后。常用目标：

| 目标 | 说明 |
|------|------|
| *（空）* | 全量编译（默认） |
| `opensbi` | 仅编译 OpenSBI 固件 |
| `linux-menuconfig` | 配置 Linux 内核 |
| `linux-rebuild` | 重新编译 Linux 内核 |
| `linux-dirclean` | 清理 Linux 内核编译 |
| `<pkg>-rebuild` | 重新编译指定软件包 |
| `<pkg>-dirclean` | 清理指定软件包编译 |

若用户未指定目标，执行全量编译（无目标后缀）。

### 步骤 3：执行编译

在项目根目录执行编译，使用**后台 bash**以便用户查看实时输出：

```bash
make CONF=<config_name> [target]
```

全量编译等长时间任务使用 `run_in_background: true`。`linux-menuconfig` 等快速目标在前台运行。

### 步骤 4：报告结果

编译完成后报告成功或失败。失败时展示相关错误输出。

## 多配置编译

若用户要编译多个配置，**依次顺序执行**。使用 `TodoWrite` 逐个跟踪进度。

## 示例

```bash
# 全量编译
make CONF=qemu_riscv64_virt_efi_mainline_defconfig

# 仅编译 opensbi
make CONF=qemu_riscv64_virt_efi_mainline_defconfig opensbi

# 配置 Linux 内核
make CONF=qemu_riscv64_virt_efi_mainline_defconfig linux-menuconfig
```
