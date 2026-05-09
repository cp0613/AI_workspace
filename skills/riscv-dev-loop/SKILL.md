---
name: riscv-dev-loop
description: 自动完成 QEMU、Kernel 和 OpenSBI 代码修改、基于 buildrootX 编译、QEMU 运行、根据测试输出迭代修改代码的完整开发循环。适用于 RISC-V 功能调试、内核驱动修改等任务。当用户要求修改 QEMU、Kernel 或 OpenSBI 代码并验证效果时使用。
---

# RISC-V 开发迭代循环

## 环境信息

| 组件 | 路径 | 别名 |
|------|------|
| buildrootX 工作目录 | `/mnt/ssd/workarea/chenp/xuantie_linux/buildrootX` | <buildrootX_dir> |
| QEMU 源码 | `/mnt/ssd/workarea/chenp/riscv/qemu_mainline` | <qemu_dir> |
| Linux 内核源码 | `/mnt/ssd/workarea/chenp/riscv/linux_mainline` | <kernel_dir> |
| OpenSBI 源码 | `/mnt/ssd/workarea/chenp/riscv/opensbi_mainline` | <opensbi_dir> |

## 工作对象

1. buildroot_defconfig
buildroot_defconfig = qemu_cxl_defconfig
后续遇到<buildroot_defconfig>即进行对应替换

2. package_qemu
package_qemu = host-qemu-local
后续遇到<package_qemu>即进行对应替换

3. qemu_run
qemu_run = run_aia_mainline_cxl.sh
后续遇到<qemu_run>即进行对应替换

## 代码修改
- 如果是本地代码，每次代码修改后需要进行 commit ， commit 要求标题精简，内容概括修改内容
- 如果是内核代码仓库修改，需要将commit后的commit-id更新到<buildrootX_dir>/configs/<buildroot_defconfig>的`BR2_LINUX_KERNEL_CUSTOM_REPO_VERSION`

## 编译与运行脚本

所有编译和运行操作均通过本 skill 的 `scripts/` 目录下的封装脚本执行，脚本内置默认参数，也可通过命令行参数覆盖。

| 脚本 | 用途 | 用法 |
|------|------|------|
| `scripts/build_qemu.sh` | 增量编译 QEMU | `bash scripts/build_qemu.sh [BUILDROOT_DIR] [DEFCONFIG] [PACKAGE_QEMU]` |
| `scripts/build_kernel.sh` | 增量编译内核 | `bash scripts/build_kernel.sh [BUILDROOT_DIR] [DEFCONFIG]` |
| `scripts/build_all.sh` | 全量编译（内核+根文件系统镜像） | `bash scripts/build_all.sh [BUILDROOT_DIR] [DEFCONFIG]` |
| `scripts/run_qemu.sh` | 启动 QEMU（参考脚本） | `bash scripts/run_qemu.sh [BUILDROOT_DIR] [QEMU_RUN_SCRIPT]` |
| `scripts/run_qemu_socket.sh` | 启动 QEMU CXL（socket 自动化交互） | `bash scripts/run_qemu_socket.sh [commands...]` |
| `scripts/qemu_cxl_auto.py` | QEMU CXL 全自动启动+测试（Python） | `python3 scripts/qemu_cxl_auto.py` |

> **注意**：如果测试涉及加载 ko，则需要使用 `build_all.sh`，保证根文件系统镜像被更新

> **注意**：编译命令可能随环境变化。若不确定，先询问用户正确的 make 命令。

### QEMU 运行模式（socat/socket 自动化交互）

`<buildrootX_dir>/scripts/` 下有两种 QEMU 运行脚本：其一是**参考脚本**，默认使用 `-nographic` 模式，适合人工交互；其二是**socket 脚本**，适合 Agent 自动化执行，通过 socat 与 QEMU 串口交互。

#### 参考脚本说明

- **`run_qemu_socket.sh`**：完整的 QEMU CXL socket 启动脚本，内置 QEMU 命令行参数，支持两种模式：
  - 无参数：启动 QEMU 后等待手动 socat 连接
  - 带参数：启动后自动通过 socat 发送命令并输出结果
  - Socket 路径：`<buildrootX_dir>/tmp/qemu_cxl.sock`

- **`qemu_cxl_auto.py`**：Python 全自动化脚本，启动 QEMU CXL → 等待 login prompt → 自动登录 → 执行内置 CXL 测试命令 → 输出结果到 `<buildrootX_dir>/tmp/qemu_cxl_result.txt`，适合无人值守测试

#### 手动 socat 连接
```bash
socat -,rawer UNIX-CONNECT:<buildrootX_dir>/tmp/qemu_cxl.sock
```

> **注意**：每次启动 QEMU 前需确认旧进程和 socket 文件已清理（脚本内置了自动清理逻辑）

### 编译修复loop
每次编译需要跟踪最后 20 行的日志，查看是否有 Error 等错误关键字，如果判断编译出错，需要自行修复，直至编译成功。

> **注意**：buildroot 登录账号为`root`，无密码

### 测试命令
1. 根据任务要求自行生成测试命令并执行
2. 如果没有明确的测试命令，需要跟用户确认，由用户提供

下面是一些典型场景的测试命令：

1. cxl mem测试
```
# 1. 系统拓扑（初始）
# cxl list
# 2. 启用CXL内存设备
# cxl enable-memdev mem0
# 3. 创建RAM类型区域
# cxl create-region -m -t ram -d decoder0.0 -w 1 mem0 -s 4G
# 4. 将区域上线为系统内存
# daxctl online-memory dax0.0
# 5. 系统内存增加
# numactl -H
# free -h
# 6. 将内存从系统内存中下线
# daxctl offline-memory dax0.0
# 7. 系统拓扑（已更新）
# cxl list
# 将设备重新配置为devdax模式
# daxctl reconfigure-device -m devdax dax0.0
# 将设备重新配置为系统内存模式
# daxctl reconfigure-device -m system-ram dax0.0
```

### 运行修复loop
每次运行后需要记录相关命令的结果，自行判断相关结果是否符合预期，如果不符合预期，继续修改相关代码，再重新编译，启动运行，测试，直至符合预期。

## 调试打印规范

添加临时调试打印时使用统一前缀，便于 grep：

```c
pr_info("[AI DBG] function_name: key=%value\n", ...);
```

过滤命令：
```bash
dmesg | grep "AI DBG"
```

调试完成后，记得还原所有 `[AI DBG]` 打印。

## 重要约定

1. **保持代码干净** — 调试完成后还原所有临时调试打印
2. **保存修改记录** — 调试成功后总结修改方案并保存到本地，使用md文档，文件名包含时间和关键字
3. **清理进程资源** — 每次测试完成或任务结束后，必须清理 QEMU 进程和 socket 文件：
```bash
# 清理 QEMU 进程和 socket
pkill -f "qemu-system-riscv64.*cxl" 2>/dev/null
rm -f /tmp/qemu_cxl.sock
```
> **注意**：重新启动 QEMU 前也需执行清理，避免残留进程占用资源或 socket 冲突

## 调试模式
- 如果用户说明使用调试模式执行或者想查看中间过程日志，则默认在 terminal 执行命令，执行时打开一个 terminal ，直接执行命令，无需重定向，无需 tail ，直接输出原始日志信息便于用户也查看
- QEMU 运行始终通过 socat/socket 自动化交互执行
