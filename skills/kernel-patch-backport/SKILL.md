---
name: kernel-patch-backport
description: 将上游 Linux 内核 patch 移植（backport）到当前内核仓库。支持从本地上游仓库 cherry-pick、从 lore.kernel.org URL 获取 patch、或通过关键字搜索并由用户选择。每次 commit 后通过 kernel-build-matrix 验证编译兼容性。当用户要求 backport、移植补丁、cherry-pick 上游 commit、或说"backport/移植/合入上游补丁"时使用此 skill。
---

# 内核 Patch Backport

将上游 Linux 内核的 patch 移植到当前仓库，保留原始 commit 信息（作者、日期、commit message），必要时微调代码以解决冲突，每个 commit 必须通过编译矩阵验证后才能继续下一个。

## 触发条件

- 用户说"backport / 移植 / 合入上游补丁 / cherry-pick 上游"
- 用户提供上游 commit hash、lore.kernel.org URL 或搜索关键字
- 用户说"把上游的 xxx 修复移植过来"

## 三种 Patch 来源

### 来源 A：本地上游仓库

用户提供本地已有的上游内核仓库路径，可以提供 commit hash 或关键字。

**如果用户提供 commit hash**：
```bash
git remote add upstream <本地上游仓库路径>
git fetch upstream
git cherry-pick <commit-hash>
```

**如果用户提供关键字**：
```bash
git remote add upstream <本地上游仓库路径>
git fetch upstream

# 在上游仓库中搜索相关 commit
git log --oneline --grep="<关键字>"
# 或按文件路径搜索
git log --oneline -- <文件路径>
# 或按作者搜索
git log --oneline --author="<作者>"
```

搜索到候选 commit 后，列出结果供用户选择，再执行 cherry-pick。

**适用场景**：用户已有 mainline 或 stable 仓库的本地 clone。

### 来源 B：lore.kernel.org URL

用户提供邮件列表中某个 patch 的 URL。

**获取方式**：
```bash
# 从 lore URL 获取 mbox 格式的 patch
curl -sL "<lore-url>/raw" > /tmp/patch.mbox

# 应用 patch
git am /tmp/patch.mbox
```

**URL 格式**：
- `https://lore.kernel.org/linux-riscv/<message-id>/`
- `https://lore.kernel.org/lkml/<message-id>/`
- `https://lore.kernel.org/all/<message-id>/`

**patch series（多个 patch）**：
- 从 cover letter 页面获取完整 series 的 mbox：`<lore-url>/t.mbox.gz`
- 或逐个获取并按顺序 `git am`

### 来源 C：关键字搜索

用户提供关键字，使用 `kernel-bug-search` skill 的搜索方式在 lore.kernel.org 检索相关 patch。

**流程**：
1. 使用 WebFetch 搜索 `https://lore.kernel.org/{list}/?q={query}&x=A`
2. 提取搜索结果列表，展示给用户
3. 用户选择需要 backport 的 patch
4. 按来源 B 的方式获取并应用

## 执行流程总览

```
Step 0  ─→  确认 Patch 来源和目标
   │
Step 1  ─→  获取 Patch 列表 + 创建 TodoWrite 跟踪表（每个 patch 一行）
   │
   ├──── 对每个 patch（不可跳过、不可批量）────┐
   │                                            │
Step 2  ─→  应用单个 patch（cherry-pick / am） │
   │                                            │
Step 3  ─→  ★★ 强制编译矩阵验证（编译门禁）★★ │
   │                                            │
   │       通过？──否──→ 修复 → amend → 回到 Step 3
   │         │                                  │
   │         是                                 │
   │         │                                  │
Step 4  ─→  TodoWrite 标记完成，记录 hash & 编译耗时
   │                                            │
   └────────── 下一个 patch ───────────────────┘
   │
Step 5  ─→  全部完成后输出汇总报告
```

## 详细步骤

### Step 0：确认 Patch 来源和目标

向用户确认：
- Patch 来源（A/B/C）及具体参数
- 当前分支是否是目标分支
- 是否需要创建新分支进行 backport
- 编译矩阵范围：默认 `arm64 + x86_64 + riscv`，可缩减（例如纯 riscv 修改可只跑 riscv）

### Step 1：获取 Patch 并建立跟踪表

获取 patch 列表后，必须立即用 `TodoWrite` 创建跟踪列表。每个 patch 一个 todo 项，状态流转：`pending → applying → building → completed`，**禁止合并多个 patch 为单个 todo**。

```
TodoWrite 示例：
  [pending] Patch 01/25 cpumask: Relax cpumask_any_but() — apply + build
  [pending] Patch 02/25 find: Add find_first_andnot_bit() — apply + build
  [pending] Patch 03/25 cpumask: Add cpumask_first_andnot() — apply + build
  ...
```

### Step 2：应用单个 patch

**优先使用 `git cherry-pick`（来源 A）或 `git am`（来源 B/C）**，保留原始 commit 信息。

冲突处理策略（按优先级）：

1. **直接应用成功** — 最佳情况，无需修改
2. **上下文偏移** — `git am` 使用 `--3way` 尝试三方合并；`git cherry-pick` 自动尝试三方
3. **代码冲突** — 手动解决冲突，微调代码以适配当前代码库：
   - 函数签名变更 → 适配当前版本的接口
   - 新增依赖的上下文代码 → 补充缺失的前置改动或调整为等价实现
   - 头文件/宏定义差异 → 使用当前仓库的等价定义
4. 解决冲突后使用 `git am --continue` 或 `git cherry-pick --continue`

**commit 信息要求**：
- 保留原始作者（`Author`）和提交日期
- 保留原始 commit message
- 默认不追加 `(cherry picked from commit ...)` 标记，使 git log 与上游一致
- 如果用户要求标注来源，追加 backport 信息：
  ```
  (cherry picked from commit <upstream-hash>)
  [<your-name>: backport to <version>, <冲突说明（如有）>]
  ```
- 末尾追加 `Signed-off-by: <your-name> <your-email>`

### Step 3：强制编译验证（编译门禁）

**这是不可跳过、不可推迟的硬性门禁**。每个 commit 应用成功后，**立即**调用 `kernel-build-matrix` 验证。

#### 3.1 必须执行的检查

```bash
# 编译前先确认 git 状态干净（无未提交修改）
bash -c 'cd <repo> && git status --short'   # 应为空

# 调用 kernel-build-matrix 编译完整默认矩阵
# 失败立即停止，不允许继续 cherry-pick 下一个 patch
```

#### 3.2 编译失败处理

编译失败绝对不能跳过，按以下顺序处理：

1. **分析错误根因**
   - 头文件/类型/宏不匹配 → 通常是依赖缺失，回溯找前置 commit
   - 函数签名变更 → 我们的树缺少 API，需要补充或适配
   - undefined reference → 链接失败，检查 Kconfig 和 Makefile

2. **修复方式（按优先级）**：
   - **首选**：补充缺失的前置 commit（递归调用 backport 流程）
   - **次选**：调整本 patch 的代码以适配现有 API
   - **末选**：在 commit message 标注 `[backport: 修改 XXX 以适配 v6.6]`

3. **将修复 amend 到当前 commit**（保持 commit 历史整洁）：
   ```bash
   git add <fixed-files>
   git commit --amend --no-edit
   ```

4. **重新运行编译矩阵**，回到 3.1。直到编译通过才能进入 Step 4。

#### 3.3 大型 patch series 的优化（仅限以下条件）

仅当满足 **全部** 条件时，可对 series 内部 patch 启用"延迟编译"：
- 单个 series 包含 ≥ 10 个 patch
- 用户**显式同意** "可以批量应用后再统一编译"
- 用户理解风险（中间 commit 不保证可编译，bisect 可能受影响）

**即使启用延迟编译，仍必须满足**：
- series 的**第一个**和**最后一个** patch 必须各自通过编译验证
- series 内每 5 个 patch 设置一个**强制 checkpoint**（编译验证）
- 每个 checkpoint 必须通过才能继续后续 patch
- 不允许在不影响 git bisect 的子系统外（如跨多个子系统的大重构）使用

**默认行为是逐个 commit 编译，"延迟编译" 不是默认选项**。

#### 3.4 编译失败的反模式（绝不要做）

- ❌ "我先把所有 patch 都 apply 完，最后统一编译"（除非满足 3.3）
- ❌ "这个编译错误看起来跟我的修改无关，先跳过"
- ❌ "用 `git commit --no-verify` 绕过 hook"
- ❌ 把多个 patch 合并到一个编译验证里
- ❌ 在 todo 列表里把"应用 patch"和"编译"分成两个不相关的步骤

### Step 4：标记完成并继续

```
TodoWrite 更新：
  [completed] Patch 01/25 ... — abc123 PASS (arm64 3m12s, x86 2m48s, riscv 4m05s)
  [in_progress] Patch 02/25 ... — apply + build
```

记录每个 patch 的：
- commit hash
- 编译结果（PASS/FAIL）
- 各架构耗时
- 任何修改注释

### Step 5：汇总报告

所有 patch 应用完成后，输出汇总：

```
Backport Summary
────────────────
  Branch  : <当前分支>
  Commits : N applied (all PASS build)
  Source  : <来源描述>

  [01] <short-hash> <commit-title> — PASS (arm64 + x86 + riscv)
  [02] <short-hash> <commit-title> — PASS (arm64 + x86 + riscv)
  ...
```

如果存在 FAIL 的 commit，**必须**在最终汇总中显式列出，并向用户说明原因。

## Self-check：commit 后必问的三个问题

每次 `git commit` / `git am --continue` / `git cherry-pick --continue` 之后，先回答这三个问题，再决定下一步：

1. **当前 commit 是否已通过编译矩阵？**（未通过 → Step 3）
2. **是否还有未应用的 patch？**（有 → 应用下一个，从 Step 2 开始）
3. **TodoWrite 是否已更新当前 commit 的状态？**（未更新 → 立即更新）

如果三个问题任一答案为"否"，**禁止**进入下一个 patch 的应用。

## 参数参考

| 参数 | 说明 | 示例 |
|------|------|------|
| 上游仓库路径 | 本地 mainline/stable 仓库 | `/mnt/ssd/workarea/chenp/riscv/linux-mainline` |
| commit hash | 上游 commit SHA（可选，也可用关键字代替） | `a1b2c3d4e5f6` |
| commit 范围 | 连续多个 commit | `a1b2c3d..f6e5d4c` |
| 关键字 | 在上游仓库 git log 或 lore 中搜索 | `riscv fix pte`、`clocksource delta` |
| lore URL | 邮件列表 patch 链接 | `https://lore.kernel.org/linux-riscv/...` |
| 编译矩阵 | 默认 arm64+x86+riscv，可由用户缩减 | `riscv:xuantie_defconfig` |

## 依赖解决

目标 patch 可能依赖尚未合入当前仓库的前置 commit。**编译失败常常就是依赖缺失的信号**，发现依赖时需主动解决：

1. **识别依赖** — cherry-pick/am 冲突或编译失败时分析原因，通过 `git log --oneline <file>` 在上游仓库中查找引入相关上下文的前置 commit
2. **递归回溯** — 如果前置 commit 也有依赖，继续向前追溯，直到找到完整的依赖链
3. **综合多种来源** — 依赖的 patch 可能分布在不同子系统，灵活运用来源 A/B/C：
   - 上游仓库 `git log --grep/--all -- <path>` 定位前置 commit
   - lore.kernel.org 搜索相关 patch series 找到完整上下文
   - `git show <upstream-hash>` 确认每个依赖的具体改动
4. **确定应用顺序** — 将依赖链按时间顺序排列，从最早的依赖开始逐个应用
5. **向用户报告** — 列出完整的依赖链和应用顺序，等用户确认后再执行
6. **每个依赖 commit 也要走编译门禁**（Step 3 适用于所有 commit，包括依赖 commit）

## 注意事项

- **不要修改原始 patch 的功能逻辑**，只做必要的适配调整
- **保留原始作者归属**，backport 者在 Signed-off-by 中署名
- 如果冲突过大无法合理解决，向用户报告并建议手动处理
- 对于 patch series，必须按顺序依次应用，不要跳过中间 patch
- `git log --oneline` 看到的应该是上游原始的 commit title
- **编译门禁不可跳过**：批量提交看起来快，但 bisect 困难和回滚成本远高于逐个编译的等待时间

## 关联 skill

- `kernel-build-matrix` —— 编译兼容性验证（**每个 commit 后必须调用，不可跳过**）
- `kernel-bug-search` —— 搜索 lore.kernel.org（来源 C 的搜索逻辑）
- `kernel-patch-fetch` —— 获取邮件列表 patch 记录
