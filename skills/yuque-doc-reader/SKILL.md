---
name: "yuque-doc-reader"
description: "从语雀网址读取文档内容并转为 Markdown，可选保存到本地文件（文件名按页面标题+时间命名）。当用户提供语雀链接要求获取内容、下载语雀文档、将语雀页面保存为 Markdown 文件时使用此技能。"
---

# 语雀文档读取器

提供语雀文档 URL，自动获取页面内容并转为 Markdown 格式，可选保存到本地文件。

## 功能特性

- 从语雀 URL 自动解析知识库和文档 slug
- 通过语雀 API 获取文档 Markdown 内容
- 可选保存到本地 `.md` 文件
- 文件名默认按 `{页面标题}_{YYYYMMDD_HHmmss}.md` 格式命名
- 支持自定义输出目录和文件名

## 环境变量

注：适用于阿里内网语雀

| 变量 | 必需 | 说明 |
|------|------|------|
| `YUQUE_TOKEN` | 是 | 语雀团队 Token |
| `YUQUE_API_HOST` | 否 | 语雀 API 地址（默认 `https://yuque-api.antfin-inc.com`） |

### 语雀 Token 获取方式

1. 登录 `https://aliyuque.antfin.com/`
2. 点击 **团队**，如果没有可管理的团队需要先点击右上角 **新建团队**
3. 在团队主页右上角点击 **设置**，**更多设置**
4. 在左侧菜单栏点击开发者栏目 **Token**
5. 点击 **新建**，勾选知识库读写、文档读写权限
6. 复制生成的 Token

## 工作流程

### 读取语雀文档并输出到终端

```bash
python3 scripts/yuque_doc_read.py --url "https://aliyuque.antfin.com/namespace/slug"
```

### 读取并保存到文件

```bash
python3 scripts/yuque_doc_read.py --url "https://aliyuque.antfin.com/namespace/slug" --save
```

### 保存到指定目录

```bash
python3 scripts/yuque_doc_read.py --url "https://aliyuque.antfin.com/namespace/slug" --save --output-dir /tmp/docs
```

## 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--url` | str | - | 语雀文档 URL（必需） |
| `--token` | str | `YUQUE_TOKEN` | 语雀 Token |
| `--api-host` | str | `YUQUE_API_HOST` | 语雀 API 地址 |
| `--save` | flag | False | 是否保存到本地文件 |
| `--output-dir` | str | `.` | 输出目录（默认当前目录） |
| `--filename` | str | 自动 | 自定义文件名（不含扩展名）；默认按 `{标题}_{时间}.md` 命名 |

## 完整示例

```bash
export YUQUE_TOKEN="your_token"

# 仅输出到终端
python3 scripts/yuque_doc_read.py \
  --url "https://aliyuque.antfin.com/my-team/my-repo/my-doc"

# 保存到当前目录，自动命名
python3 scripts/yuque_doc_read.py \
  --url "https://aliyuque.antfin.com/my-team/my-repo/my-doc" \
  --save

# 保存到指定目录，自定义文件名
python3 scripts/yuque_doc_read.py \
  --url "https://aliyuque.antfin.com/my-team/my-repo/my-doc" \
  --save \
  --output-dir /tmp/docs \
  --filename "my-custom-name"
```

## URL 格式支持

支持以下语雀 URL 格式：

```
https://aliyuque.antfin.com/{namespace}/{slug}
https://aliyuque.antfin.com/{user}/{repo}/{slug}
https://www.yuque.com/{user}/{repo}/{slug}
```

## 注意事项

- `--url` 为必需参数
- 默认仅输出到终端（stdout），需要 `--save` 才会保存文件
- 文件名中的特殊字符会被替换为下划线
- 保存成功后会打印文件路径
