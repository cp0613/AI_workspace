#!/usr/bin/env python3
"""
将 Markdown 文档内容写入语雀知识库，按照指定文件夹分类管理。

目录结构（在语雀知识库中）：
  riscv-kernel-report-daily (知识库)
  ├── 2026-01/                          (TITLE 文件夹)
  │   ├── Kernel Patch 日报 (2026-01-01)  (DOC)
  │   └── ...
  └── ...

认证方式：语雀团队 Token
  获取方式：语雀 → 团队 → 设置 → Token → 新建

依赖环境变量：
  YUQUE_TOKEN      - 语雀团队 access token（必需）
  YUQUE_API_HOST   - 语雀 API 地址（可选，默认 https://yuque-api.antfin-inc.com）
  YUQUE_WEB_HOST   - 语雀页面地址（可选，默认 https://aliyuque.antfin.com）
"""

import argparse
import json
import os
import sys
import urllib.request
import urllib.error


# 阿里内网语雀：页面地址是 aliyuque.antfin.com，但 API 地址是 yuque-api.antfin-inc.com
# 外网语雀：页面和 API 都是 www.yuque.com
DEFAULT_API_HOST = "https://yuque-api.antfin-inc.com"
DEFAULT_WEB_HOST = "https://aliyuque.antfin.com"


def parse_args():
    parser = argparse.ArgumentParser(description="将 Markdown 文档写入语雀知识库")
    parser.add_argument("--token", type=str, default=os.environ.get("YUQUE_TOKEN"),
                        help="语雀团队 Token（也可通过 YUQUE_TOKEN 环境变量设置）")
    parser.add_argument("--api-host", type=str,
                        default=os.environ.get("YUQUE_API_HOST", DEFAULT_API_HOST),
                        help="语雀 API 地址（默认 https://yuque-api.antfin-inc.com）")
    parser.add_argument("--web-host", type=str,
                        default=os.environ.get("YUQUE_WEB_HOST", DEFAULT_WEB_HOST),
                        help="语雀页面地址（默认 https://aliyuque.antfin.com）")
    parser.add_argument("--md-file", type=str, default=None,
                        help="Markdown 文件路径")
    parser.add_argument("--stdin", action="store_true",
                        help="从 stdin 读取 Markdown 内容")
    parser.add_argument("--title", type=str, default=None,
                        help="文档标题（默认: 文档 (YYYY-MM-DD)）")
    parser.add_argument("--slug", type=str, default=None,
                        help="文档 slug（默认: YYYY-MM-DD）")
    parser.add_argument("--date", type=str, default=None,
                        help="文档日期 (YYYY-MM-DD)，用于确定年月文件夹")
    parser.add_argument("--folder", type=str, default=None,
                        help="指定语雀文件夹名称（已存在则直接写入，不存在则新建）；"
                             "不指定则按 --date 自动生成年月文件夹（如 2026-05）")
    parser.add_argument("--repo", type=str, default="riscv-kernel-report-daily",
                        help="知识库 slug（默认 riscv-kernel-report-daily）")
    return parser.parse_args()


def api_request(method, path, token, api_host, data=None):
    """发送语雀 API 请求"""
    url = f"{api_host}/api/v2{path}"
    headers = {
        "X-Auth-Token": token,
        "Content-Type": "application/json",
        "User-Agent": "yuque-doc-writer/1.0",
    }
    body = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            resp_body = resp.read().decode("utf-8")
            return json.loads(resp_body) if resp_body else {}
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8") if e.fp else ""
        if e.code != 404:
            print(f"API 错误 [{e.code}] {method} {path}: {error_body}", file=sys.stderr)
        raise


def get_current_user(token, api_host):
    """获取当前用户信息"""
    result = api_request("GET", "/user", token, api_host)
    return result.get("data", {})


def get_user_repos(token, api_host, user_login):
    """获取用户的知识库列表"""
    result = api_request("GET", f"/users/{user_login}/repos", token, api_host)
    return result.get("data", [])


def find_repo_by_slug(token, api_host, user_login, slug):
    """按 slug 查找知识库"""
    repos = get_user_repos(token, api_host, user_login)
    for repo in repos:
        if repo.get("slug") == slug:
            return repo
    return None


def create_repo(token, api_host, user_login, name, slug, description=""):
    """创建知识库"""
    data = {
        "name": name,
        "slug": slug,
        "type": "Book",
        "public": 0,
        "description": description,
    }
    result = api_request("POST", f"/users/{user_login}/repos", token, api_host, data)
    return result.get("data", {})


def get_repo_toc(token, api_host, namespace):
    """获取知识库目录（TOC）"""
    result = api_request("GET", f"/repos/{namespace}/toc", token, api_host)
    return result.get("data", [])


def find_doc_by_slug(token, api_host, namespace, slug):
    """按 slug 查找文档"""
    try:
        result = api_request("GET", f"/repos/{namespace}/docs/{slug}", token, api_host)
        return result.get("data")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise


def create_doc(token, api_host, namespace, title, slug, body, format_type="markdown"):
    """创建文档"""
    data = {
        "title": title,
        "slug": slug,
        "format": format_type,
        "body": body,
        "public": 0,
    }
    result = api_request("POST", f"/repos/{namespace}/docs", token, api_host, data)
    return result.get("data", {})


# ──────────────────────────────────────────────
# TOC 目录管理：年月文件夹
# ──────────────────────────────────────────────

def toc_find_folder(toc_items, folder_title):
    """在 TOC 中查找 TITLE 类型的文件夹节点，返回 uuid"""
    for item in toc_items:
        if item.get("type") == "TITLE" and item.get("title") == folder_title:
            return item.get("uuid")
    return None


def toc_create_folder(token, api_host, namespace, folder_title):
    """在知识库 TOC 根层级创建一个文件夹节点，返回新节点 uuid"""
    data = {
        "action": "prependNode",
        "action_mode": "child",
        "target_uuid": "",
        "title": folder_title,
        "type": "TITLE",
    }
    result = api_request("PUT", f"/repos/{namespace}/toc", token, api_host, data)
    toc_items = result.get("data", [])
    for item in toc_items:
        if item.get("type") == "TITLE" and item.get("title") == folder_title:
            return item.get("uuid")
    return None


def toc_add_doc_to_folder(token, api_host, namespace, folder_uuid, doc_id):
    """将文档添加到指定文件夹下"""
    data = {
        "action": "appendByDocs",
        "target_uuid": folder_uuid,
        "doc_ids": [doc_id],
    }
    api_request("PUT", f"/repos/{namespace}/toc", token, api_host, data)


def toc_doc_exists_in_folder(toc_items, folder_uuid, doc_id):
    """检查文档是否已经在指定文件夹下"""
    for item in toc_items:
        if (item.get("parent_uuid") == folder_uuid
                and item.get("doc_id") == doc_id
                and item.get("type") == "DOC"):
            return True
    return False


def ensure_month_folder(token, api_host, namespace, year_month):
    """确保年月文件夹存在，返回 folder_uuid"""
    toc_items = get_repo_toc(token, api_host, namespace)
    folder_uuid = toc_find_folder(toc_items, year_month)

    if folder_uuid:
        print(f"月份文件夹已存在: {year_month}", file=sys.stderr)
        return folder_uuid

    print(f"正在创建月份文件夹: {year_month}", file=sys.stderr)
    folder_uuid = toc_create_folder(token, api_host, namespace, year_month)
    if not folder_uuid:
        print(f"警告: 创建文件夹失败: {year_month}", file=sys.stderr)
    return folder_uuid


def ensure_repo(token, api_host, user_login, repo_slug):
    """确保知识库存在，返回 namespace"""
    repo = find_repo_by_slug(token, api_host, user_login, repo_slug)
    if repo:
        print(f"知识库已存在: {repo.get('name')} ({repo.get('namespace')})", file=sys.stderr)
        return repo.get("namespace")

    print(f"正在创建知识库: {repo_slug}", file=sys.stderr)
    repo = create_repo(
        token, api_host, user_login,
        name=repo_slug,
        slug=repo_slug,
        description="文档",
    )
    namespace = repo.get("namespace")

    # create_repo 的返回值可能不包含 namespace，需要重新查询获取
    if not namespace:
        repo = find_repo_by_slug(token, api_host, user_login, repo_slug)
        if repo:
            namespace = repo.get("namespace")

    print(f"知识库已创建: {namespace}", file=sys.stderr)
    return namespace


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

    # 读取 Markdown 内容
    if args.stdin:
        md_content = sys.stdin.read()
    elif args.md_file:
        try:
            with open(args.md_file, "r", encoding="utf-8") as f:
                md_content = f.read()
        except Exception as e:
            print(f"错误: 无法读取 Markdown 文件 - {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print("错误: 需要提供 --md-file 或 --stdin 参数", file=sys.stderr)
        sys.exit(1)

    # 确定 --date 和文件夹名
    # 如果指定了 --folder 但没指定 --date，--date 可以为空（仅用于默认标题/slug）
    # 如果两者都没指定，则报错
    if not args.folder and not args.date:
        print("错误: 需要提供 --date 或 --folder 参数", file=sys.stderr)
        sys.exit(1)

    report_date = args.date  # 可能为 None
    folder_name = args.folder  # 可能为 None

    # 确定文件夹名：--folder 优先，否则从 --date 派生年月
    if folder_name:
        year_month = folder_name
    elif report_date:
        year_month = report_date[:7]
    else:
        year_month = None

    # 文档信息：slug 和 title 默认值依赖 date
    if args.slug:
        doc_slug = args.slug
    elif report_date:
        doc_slug = report_date
    else:
        print("错误: 未指定 --date 时需要提供 --slug 参数", file=sys.stderr)
        sys.exit(1)

    if args.title:
        doc_title = args.title
    elif report_date:
        doc_title = f"文档 ({report_date})"
    else:
        print("错误: 未指定 --date 时需要提供 --title 参数", file=sys.stderr)
        sys.exit(1)

    token = args.token
    api_host = args.api_host.rstrip("/")
    web_host = args.web_host.rstrip("/")

    # 获取当前用户
    print("正在获取用户信息...", file=sys.stderr)
    user = get_current_user(token, api_host)
    user_login = user.get("login")
    if not user_login:
        print("错误: 无法获取用户信息，请检查 Token 是否有效", file=sys.stderr)
        sys.exit(1)
    print(f"当前用户: {user.get('name')} ({user_login})", file=sys.stderr)

    # 确保知识库存在
    namespace = ensure_repo(token, api_host, user_login, args.repo)

    # 检查文档是否已存在
    existing = find_doc_by_slug(token, api_host, namespace, doc_slug)
    if existing:
        print(f"文档已存在: {doc_title}，跳过创建", file=sys.stderr)
        print(f"文档 URL: {web_host}/{namespace}/{doc_slug}")
        return

    # 创建文档
    print(f"正在创建文档: {doc_title}", file=sys.stderr)
    doc = create_doc(token, api_host, namespace, doc_title, doc_slug, md_content)
    doc_id = doc.get("id")

    if not doc_id:
        print("错误: 文档创建失败", file=sys.stderr)
        sys.exit(1)

    # 确保文件夹存在并将文档放入
    if year_month:
        folder_uuid = ensure_month_folder(token, api_host, namespace, year_month)
        if folder_uuid:
            toc_items = get_repo_toc(token, api_host, namespace)
            if not toc_doc_exists_in_folder(toc_items, folder_uuid, doc_id):
                print(f"正在将文档放入文件夹: {year_month}/", file=sys.stderr)

                # 先移除根层级的文档引用（创建文档时自动生成的）
                for item in toc_items:
                    if (item.get("doc_id") == doc_id
                            and item.get("type") == "DOC"
                            and not item.get("parent_uuid")):
                        try:
                            remove_data = {
                                "action": "removeNode",
                                "action_mode": "sibling",
                                "node_uuid": item.get("uuid"),
                            }
                            api_request("PUT", f"/repos/{namespace}/toc", token, api_host, remove_data)
                        except urllib.error.HTTPError:
                            pass
                        break

                toc_add_doc_to_folder(token, api_host, namespace, folder_uuid, doc_id)
            else:
                print(f"文档已在文件夹 {year_month}/ 下", file=sys.stderr)
    else:
        print("未指定文件夹，文档创建在知识库根目录", file=sys.stderr)

    print(f"完成! 文档已创建:", file=sys.stderr)
    print(f"  标题: {doc_title}")
    print(f"  URL:  {web_host}/{namespace}/{doc_slug}")
    print(f"  ID:   {doc_id}")
    if year_month:
        print(f"  目录: {year_month}/")
    if report_date:
        print(f"  日期: {report_date}")


if __name__ == "__main__":
    main()
