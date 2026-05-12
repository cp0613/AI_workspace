#!/usr/bin/env python3
"""
通过 NNTP 从 lore.kernel.org 的多个邮件列表获取指定日期的 patch 提交记录。
支持输出 JSON 报表或 Markdown 文档内容。

使用 NNTP 协议替代 Atom feed，解决以下问题：
  - Atom feed 每次最多 25 条，高流量列表（如 LKML）无法覆盖完整一天
  - lore.kernel.org 搜索接口有 bot 保护
  - NNTP 支持按日期范围精确获取，无条数限制
"""

import argparse
import json
import sys
import re
import warnings
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime

# nntplib 在 Python 3.13 中将被移除，但目前仍可用
warnings.filterwarnings("ignore", category=DeprecationWarning, module="nntplib")
import nntplib


NNTP_SERVER = "nntp.lore.kernel.org"
NNTP_TIMEOUT = 60

# 邮件列表配置
MAILING_LISTS = [
    {
        "id": "lkml",
        "name": "lkml",
        "display_name": "LKML (主线内核)",
        "nntp_group": "org.kernel.vger.linux-kernel",
        "filter": "fix_improve",
        "batch_size": 500,
        "max_articles": 2000,
    },
    {
        "id": "linux-riscv",
        "name": "linux-riscv",
        "display_name": "Linux RISC-V",
        "nntp_group": "org.infradead.lists.linux-riscv",
        "filter": "all",
        "batch_size": 200,
        "max_articles": 500,
    },
    {
        "id": "linux-perf-users",
        "name": "linux-perf-users",
        "display_name": "Linux Perf Users",
        "nntp_group": "org.kernel.vger.linux-perf-users",
        "filter": "riscv",
        "batch_size": 200,
        "max_articles": 500,
    },
]

# 过滤关键字（不区分大小写）
FIX_IMPROVE_KEYWORDS = [
    r"\bfix\b", r"\bfixes\b", r"\bfixed\b", r"\bbug\b", r"\bbugfix\b",
    r"\bimprove\b", r"\bimprovement\b", r"\boptimize\b", r"\boptimization\b",
    r"\bperformance\b", r"\bregression\b", r"\brevert\b",
    r"\bcorrect\b", r"\bcorrection\b", r"\brepair\b", r"\bresolve\b",
]

RISCV_KEYWORDS = [
    r"\briscv\b", r"\brisc-v\b", r"\brv32\b", r"\brv64\b",
]


def parse_args():
    parser = argparse.ArgumentParser(
        description="通过 NNTP 获取多个内核邮件列表的 patch 提交记录"
    )
    parser.add_argument(
        "--date", type=str, default=None,
        help="指定日期 (YYYY-MM-DD)，默认为昨天",
    )
    parser.add_argument(
        "--output", type=str, default=None,
        help="输出 JSON 文件路径",
    )
    parser.add_argument(
        "--md-output", type=str, default=None,
        help="输出 Markdown 文件路径",
    )
    parser.add_argument(
        "--format", type=str, default="json",
        choices=["json", "markdown", "both"],
        help="输出格式: json/markdown(默认)/both",
    )
    parser.add_argument(
        "--lists", type=str, default=None,
        help="逗号分隔的邮件列表 ID（默认全部），如: linux-riscv,lkml",
    )
    parser.add_argument(
        "--server", type=str, default=NNTP_SERVER,
        help=f"NNTP 服务器地址（默认 {NNTP_SERVER}）",
    )
    return parser.parse_args()


def parse_patch_type(subject):
    """解析 patch 类型和版本号"""
    subject_upper = subject.upper()

    if "[RFC" in subject_upper:
        return "rfc", None

    version_match = re.search(r"\[PATCH\s+[vV](\d+)", subject)
    if version_match:
        return "patch_update", int(version_match.group(1))

    if "[PATCH" in subject_upper:
        return "patch_new", 1

    return "discussion", None


def parse_overview(art_num, overview, list_id):
    """将 NNTP OVER 数据解析为 patch 记录"""
    subject = overview.get("subject", "").strip()
    from_addr = overview.get("from", "").strip()
    date_str = overview.get("date", "").strip()
    msg_id = overview.get("message-id", "").strip("<>")

    # 解析作者：格式可能是 "Name <email>" 或 "email (Name)"
    author_name = ""
    author_email = ""
    match = re.match(r"^(.+?)\s*<(.+?)>", from_addr)
    if match:
        author_name = match.group(1).strip().strip('"')
        author_email = match.group(2).strip()
    else:
        match2 = re.match(r"^(.+?)\s*\((.+?)\)", from_addr)
        if match2:
            author_email = match2.group(1).strip()
            author_name = match2.group(2).strip()
        else:
            author_name = from_addr

    # 解析日期
    try:
        dt = parsedate_to_datetime(date_str)
    except Exception:
        dt = None

    # 构建链接
    link = f"https://lore.kernel.org/{list_id}/{msg_id}/" if msg_id else ""

    patch_type, version = parse_patch_type(subject)

    return {
        "title": subject,
        "author": author_name,
        "email": author_email,
        "date": dt.isoformat() if dt else date_str,
        "link": link,
        "type": patch_type,
        "version": version,
        "_datetime": dt,
    }


def fetch_articles_for_date(conn, ml_config, target_date):
    """
    从 NNTP group 中获取指定日期的所有文章概览。
    从最新的文章向前扫描，直到遇到目标日期之前的文章为止。
    """
    group = ml_config["nntp_group"]
    batch_size = ml_config["batch_size"]
    max_articles = ml_config["max_articles"]
    list_id = ml_config["id"]

    resp, count, first, last, name = conn.group(group)
    last = int(last)
    first = int(first)

    all_entries = []
    scanned = 0
    found_target = False
    passed_target = False

    current_end = last

    while scanned < max_articles and current_end >= first:
        current_start = max(first, current_end - batch_size + 1)

        try:
            resp, overviews = conn.over((str(current_start), str(current_end)))
        except nntplib.NNTPTemporaryError:
            break

        if not overviews:
            break

        for art_num, ov in reversed(overviews):
            entry = parse_overview(art_num, ov, list_id)
            dt = entry.get("_datetime")

            if dt is None:
                continue

            entry_date = dt.date()

            if entry_date == target_date:
                found_target = True
                all_entries.append(entry)
            elif entry_date < target_date:
                passed_target = True
                break

        scanned += len(overviews)

        if passed_target:
            break

        current_end = current_start - 1

    return all_entries


def match_keywords(entry, keyword_patterns):
    """检查 entry 的标题是否匹配任一关键字"""
    text = entry["title"]
    for pattern in keyword_patterns:
        if re.search(pattern, text, re.IGNORECASE):
            return True
    return False


def apply_filter(entries, filter_type):
    """根据过滤类型筛选条目"""
    if filter_type == "all":
        return entries
    elif filter_type == "fix_improve":
        return [e for e in entries if match_keywords(e, FIX_IMPROVE_KEYWORDS)]
    elif filter_type == "riscv":
        return [e for e in entries if match_keywords(e, RISCV_KEYWORDS)]
    else:
        return entries


def clean_entry(entry):
    """移除内部字段，准备输出"""
    return {k: v for k, v in entry.items() if not k.startswith("_")}


def make_summary(patches):
    """生成类型统计"""
    return {
        "patch_new": len([p for p in patches if p["type"] == "patch_new"]),
        "patch_update": len([p for p in patches if p["type"] == "patch_update"]),
        "rfc": len([p for p in patches if p["type"] == "rfc"]),
        "discussion": len([p for p in patches if p["type"] == "discussion"]),
    }


# ──────────────────────────────────────────────
# Markdown 格式化
# ──────────────────────────────────────────────

def format_patches_section(patches, heading_level="###"):
    """将一组 patch 列表格式化为 Markdown，按类型分小节"""
    lines = []

    new_patches = [p for p in patches if p["type"] == "patch_new"]
    if new_patches:
        lines.append(f"{heading_level} 新补丁 ({len(new_patches)})")
        lines.append("")
        for p in new_patches:
            lines.append(f"- [{p['title']}]({p['link']}) — {p['author']}")
        lines.append("")

    updates = [p for p in patches if p["type"] == "patch_update"]
    if updates:
        lines.append(f"{heading_level} 补丁更新 ({len(updates)})")
        lines.append("")
        for p in updates:
            lines.append(f"- [{p['title']}]({p['link']}) — {p['author']}")
        lines.append("")

    rfcs = [p for p in patches if p["type"] == "rfc"]
    if rfcs:
        lines.append(f"{heading_level} RFC ({len(rfcs)})")
        lines.append("")
        for p in rfcs:
            lines.append(f"- [{p['title']}]({p['link']}) — {p['author']}")
        lines.append("")

    discussions = [p for p in patches if p["type"] == "discussion"]
    if discussions:
        lines.append(f"{heading_level} 讨论 ({len(discussions)})")
        lines.append("")
        for p in discussions:
            lines.append(f"- [{p['title']}]({p['link']}) — {p['author']}")
        lines.append("")

    return lines


def format_report_markdown(report_data):
    """将多邮件列表 JSON 报表转为 Markdown 文档内容"""
    total = report_data["total_count"]
    mailing_lists = report_data.get("mailing_lists", [])

    lines = []

    if total == 0:
        lines.append("今日各邮件列表均无相关 patch 提交。")
        return "\n".join(lines)

    # 总览表格
    filter_desc_map = {
        "all": "全部",
        "fix_improve": "fix/improve 相关",
        "riscv": "riscv 相关",
    }
    lines.extend([
        f"**共 {total} 条记录**",
        "",
        "| 邮件列表 | 过滤规则 | 数量 |",
        "|----------|----------|------|",
    ])
    for ml in mailing_lists:
        filter_desc = filter_desc_map.get(ml.get("filter", "all"), ml.get("filter", ""))
        lines.append(f"| {ml['display_name']} | {filter_desc} | {ml['total_count']} |")
    lines.append("")

    # 按邮件列表分组展示
    for ml in mailing_lists:
        patches = ml.get("patches", [])
        count = ml["total_count"]
        lines.append(f"## {ml['display_name']}（{count} 条）")
        lines.append("")

        if count == 0:
            lines.append("无相关记录。")
            lines.append("")
            continue

        lines.extend(format_patches_section(patches, heading_level="###"))

    # 数据来源
    lines.extend([
        "---",
        "",
        "*数据来源: [lore.kernel.org](https://lore.kernel.org/)*",
    ])

    return "\n".join(lines)


# ──────────────────────────────────────────────
# 主流程
# ──────────────────────────────────────────────

def main():
    args = parse_args()

    # 确定目标日期
    if args.date:
        target_date = datetime.strptime(args.date, "%Y-%m-%d").date()
    else:
        target_date = (datetime.now(timezone.utc) - timedelta(days=1)).date()

    # 确定要抓取的邮件列表
    if args.lists:
        selected_ids = [x.strip() for x in args.lists.split(",")]
        lists_to_fetch = [ml for ml in MAILING_LISTS if ml["id"] in selected_ids]
        if not lists_to_fetch:
            print(f"错误: 未找到指定的邮件列表: {args.lists}", file=sys.stderr)
            print(f"可用列表: {', '.join(ml['id'] for ml in MAILING_LISTS)}", file=sys.stderr)
            sys.exit(1)
    else:
        lists_to_fetch = MAILING_LISTS

    # 连接 NNTP 服务器
    print(f"正在连接 NNTP 服务器 {args.server}...", file=sys.stderr)
    try:
        conn = nntplib.NNTP(args.server, timeout=NNTP_TIMEOUT)
    except Exception as e:
        print(f"错误: 无法连接 NNTP 服务器 - {e}", file=sys.stderr)
        sys.exit(1)
    print(f"已连接，目标日期: {target_date}", file=sys.stderr)

    # 抓取并处理各邮件列表
    mailing_lists_result = []
    total_count = 0

    try:
        for ml in lists_to_fetch:
            print(f"\n正在获取 {ml['display_name']} ({ml['nntp_group']})...", file=sys.stderr)

            try:
                entries = fetch_articles_for_date(conn, ml, target_date)
            except Exception as e:
                print(f"  警告: 获取 {ml['id']} 失败 - {e}", file=sys.stderr)
                mailing_lists_result.append({
                    "id": ml["id"],
                    "name": ml["name"],
                    "display_name": ml["display_name"],
                    "filter": ml["filter"],
                    "total_count": 0,
                    "patches": [],
                    "summary": make_summary([]),
                    "error": str(e),
                })
                continue

            print(f"  获取到 {len(entries)} 条原始记录", file=sys.stderr)

            # 按关键字过滤
            filtered = apply_filter(entries, ml["filter"])

            # 清理内部字段
            clean_patches = [clean_entry(p) for p in filtered]

            count = len(clean_patches)
            total_count += count

            filter_desc = {
                "all": "全部",
                "fix_improve": "仅 fix/improve 相关",
                "riscv": "仅 riscv 相关",
            }.get(ml["filter"], ml["filter"])

            print(f"  关键字过滤({filter_desc})后: {count} 条", file=sys.stderr)

            mailing_lists_result.append({
                "id": ml["id"],
                "name": ml["name"],
                "display_name": ml["display_name"],
                "filter": ml["filter"],
                "total_count": count,
                "patches": clean_patches,
                "summary": make_summary(clean_patches),
            })
    finally:
        conn.quit()

    # 组装最终结果
    result = {
        "date": target_date.isoformat(),
        "total_count": total_count,
        "mailing_lists": mailing_lists_result,
    }

    output_json = json.dumps(result, ensure_ascii=False, indent=2)
    output_md = format_report_markdown(result)

    # 输出 JSON
    if args.format in ("json", "both"):
        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(output_json)
            print(f"\nJSON 已保存到: {args.output}", file=sys.stderr)
        else:
            print(output_json)

    # 输出 Markdown
    if args.format in ("markdown", "both"):
        if args.md_output:
            with open(args.md_output, "w", encoding="utf-8") as f:
                f.write(output_md)
            print(f"\nMarkdown 已保存到: {args.md_output}", file=sys.stderr)
        else:
            print(output_md)

    print(f"\n总计: {total_count} 条记录（{len(lists_to_fetch)} 个邮件列表）", file=sys.stderr)


if __name__ == "__main__":
    main()
