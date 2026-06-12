---
name: signed-off-by
description: 为 git commit 或 patch 添加 Signed-off-by 签名行，身份信息从 ~/.gitconfig 的 [user] 段读取。任何技能在生成 commit、创建 patch、cherry-pick、git am、git format-patch、或执行任何会产生 git commit 的操作时，必须自动调用此技能获取签名行并追加。当用户提到"signed-off-by"、"sign off"、"DCO"、"签名提交"时也直接触发。校验 ~/.gitconfig 是否存在且包含 [user] name 和 email，不存在或缺失时提醒用户填写，绝不伪造姓名和邮箱。
---

# Signed-off-by 提交签名

从 `~/.gitconfig` 读取用户身份，为 git commit 和 patch 添加 `Signed-off-by: Name <email>` 签名行。

## 自动集成规则

**任何技能在执行以下操作时，必须自动调用此技能：**

- `git commit`（任何形式，包括 `--amend`、`-m`、HEREDOC 等）
- `git cherry-pick` / `git cherry-pick --continue`
- `git am` / `git am --continue`
- `git format-patch`
- 任何其他产生 git commit 或 patch 文件的操作

调用方式：执行 `bash <skill_dir>/scripts/get-signoff.sh` 获取签名行，将其追加到 commit message 末尾。

## 工作流程

1. 执行 `bash <skill_dir>/scripts/get-signoff.sh` 提取签名身份。
2. 若脚本报错退出：
   - **绝不伪造或猜测**姓名和邮箱。
   - 向用户展示错误信息。
   - 提示用户创建/编辑 `~/.gitconfig`，添加 `[user]` 段，例如：
     ```
     [user]
         name = Your Name
         email = your.email@example.com
     ```
   - 停止并等待用户修复配置。
3. 脚本成功时输出 `Name <email>`，例如 `Chen Pei <cp0613@linux.alibaba.com>`。
4. 根据操作类型追加签名：
   - **git commit**：在 commit message 末尾追加空行 + `Signed-off-by: Name <email>`，或使用 `git commit -s`。
   - **git format-patch**：无需额外操作，`-s` 参数会在生成的 patch 中自动追加签名。
   - **git cherry-pick / git am**：操作完成后通过 `git commit --amend -s` 补充签名。
   - **解决冲突后 continue**：`git cherry-pick --continue` 或 `git am --continue` 前，检查 commit message 是否已包含 `Signed-off-by`，缺失则补充。

## 约束

- **绝不伪造**姓名或邮箱，只使用 `~/.gitconfig` 中的值。
- `[user]` 段缺失或不完整时，停止并要求用户修复。
- 不要重复追加签名行——若 commit message 中已存在相同的 `Signed-off-by: Name <email>`，则跳过。

## 资源

- `scripts/get-signoff.sh` — 从 `~/.gitconfig` [user] 段提取 `Name <email>`。
