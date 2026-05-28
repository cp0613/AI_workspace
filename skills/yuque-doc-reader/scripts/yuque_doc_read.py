#!/usr/bin/env python3
"""
从语雀 URL 读取文档内容，转为 Markdown 格式输出或保存到本地文件。

支持的 URL 格式：
  https://aliyuque.antfin.com/{namespace}/{slug}
  https://aliyuque.antfin.com/{user}/{repo}/{slug}
  https://www.yuque.com/{user}/{repo}/{slug}

认证方式：语雀团队 Token
  获取方式：语雀 → 团队 → 设置 → Token → 新建

依赖环境变量：
  YUQUE_TOKEN      - 语雀团队 access token（必需）
  YUQUE_API_HOST   - 语雀 API 地址（可选，默认 https://yuque-api.antfin-inc.com）
"""

import argparse
import json
import os
import re
import sys
import urllib.request
import urllib.error
from datetime import datetime
from urllib.parse import urlparse


DEFAULT_API_HOST = "https://yuque-api.antfin-inc.com"


def parse_args():
    parser = argparse.ArgumentParser(description="从语雀 URL 读取文档内容")
    parser.add_argument("--url", type=str, required=True,
                        help="语雀文档 URL")
    parser.add_argument("--token", type=str, default=os.environ.get("YUQUE_TOKEN"),
                        help="语雀团队 Token（也可通过 YUQUE_TOKEN 环境变量设置）")
    parser.add_argument("--api-host", type=str,
                        default=os.environ.get("YUQUE_API_HOST", DEFAULT_API_HOST),
                        help="语雀 API 地址（默认 https://yuque-api.antfin-inc.com）")
    parser.add_argument("--save", action="store_true",
                        help="保存到本地文件")
    parser.add_argument("--output-dir", type=str, default=".",
                        help="输出目录（默认当前目录）")
    parser.add_argument("--filename", type=str, default=None,
                        help="自定义文件名（不含 .md 扩展名）；默认按 {标题}_{时间}.md 命名")
    return parser.parse_args()


def api_request(method, path, token, api_host):
    """发送语雀 API 请求"""
    url = f"{api_host}/api/v2{path}"
    headers = {
        "X-Auth-Token": token,
        "Content-Type": "application/json",
        "User-Agent": "yuque-doc-reader/1.0",
    }
    req = urllib.request.Request(url, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            resp_body = resp.read().decode("utf-8")
            return json.loads(resp_body) if resp_body else {}
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8") if e.fp else ""
        print(f"API 错误 [{e.code}] {method} {path}: {error_body}", file=sys.stderr)
        raise


def parse_yuque_url(url):
    """
    解析语雀 URL，返回 (namespace, slug)。

    支持格式：
      https://aliyuque.antfin.com/{user}/{repo}/{slug}
      https://www.yuque.com/{user}/{repo}/{slug}
      https://aliyuque.antfin.com/{namespace}/{slug}  (namespace 含 /)
    """
    parsed = urlparse(url)
    path = parsed.path.strip("/")

    # 去掉可能的查询参数和锚点中的内容已经由 urlparse 处理

    parts = path.split("/")

    if len(parts) >= 3:
        # 格式: user/repo/slug
        namespace = f"{parts[0]}/{parts[1]}"
        slug = parts[2]
    elif len(parts) == 2:
        # 格式: namespace/slug (namespace 本身不含 /)
        namespace = parts[0]
        slug = parts[1]
    else:
        print(f"错误: 无法解析 URL 路径: {path}", file=sys.stderr)
        print("期望格式: https://aliyuque.antfin.com/{user}/{repo}/{slug}", file=sys.stderr)
        sys.exit(1)

    return namespace, slug


def get_doc(token, api_host, namespace, slug):
    """获取文档详情（包含 body_markdown / body）"""
    result = api_request("GET", f"/repos/{namespace}/docs/{slug}?raw=1", token, api_host)
    return result.get("data", {})


def sanitize_filename(name):
    """将字符串转为安全的文件名，特殊字符替换为下划线"""
    name = re.sub(r'[\\/:*?"<>|]', '_', name)
    name = re.sub(r'\s+', '_', name)
    name = name.strip('_.')
    return name


def main():
    args = parse_args()

    if not args.token:
        print(
            "错误: 需要提供语雀 Token。\n"
            "  方式1: --token YOUR_TOKEN\n"
            "  方式2: export YUQUE_TOKEN=YOUR_TOKEN\n\n"
            "获取方式: 语雀 → 头像 → 账户设置 → Token → 新建",
            file=sys.stderr,
        )
        sys.exit(1)

    token = args.token
    api_host = args.api_host.rstrip("/")

    # 解析 URL
    namespace, slug = parse_yuque_url(args.url)
    print(f"解析 URL: namespace={namespace}, slug={slug}", file=sys.stderr)

    # 获取文档
    print("正在获取文档...", file=sys.stderr)
    doc = get_doc(token, api_host, namespace, slug)

    if not doc:
        print("错误: 文档不存在或无权限访问", file=sys.stderr)
        sys.exit(1)

    title = doc.get("title", "untitled")
    # 优先使用 body 字段（raw markdown），其次 body_draft
    body = doc.get("body", "") or doc.get("body_draft", "")

    if not body:
        print("警告: 文档内容为空", file=sys.stderr)

    print(f"文档标题: {title}", file=sys.stderr)
    print(f"文档字数: {len(body)}", file=sys.stderr)

    # 输出或保存
    if args.save:
        # 确定文件名
        if args.filename:
            filename = args.filename
        else:
            safe_title = sanitize_filename(title)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{safe_title}_{timestamp}"

        if not filename.endswith(".md"):
            filename = f"{filename}.md"

        # 确保输出目录存在
        output_dir = os.path.abspath(args.output_dir)
        os.makedirs(output_dir, exist_ok=True)

        filepath = os.path.join(output_dir, filename)

        with open(filepath, "w", encoding="utf-8") as f:
            f.write(body)

        print(f"文件已保存: {filepath}", file=sys.stderr)
        print(filepath)
    else:
        # 输出到 stdout
        print(body)


if __name__ == "__main__":
    main()
