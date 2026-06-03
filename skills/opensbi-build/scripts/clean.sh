#!/bin/bash
# clean.sh — make distclean
#
# 用法:
#   bash clean.sh [--repo PATH]
#
# 默认 --repo 为当前目录。

set -euo pipefail

REPO=""
while [ $# -gt 0 ]; do
    case "$1" in
        --repo)    REPO="$2"; shift 2 ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *)         echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

if [ -z "$REPO" ]; then
    REPO="$(pwd)"
fi
if [ ! -f "$REPO/Makefile" ] || [ ! -f "$REPO/lib/sbi/sbi_init.c" ]; then
    echo "ERROR: $REPO 不是 OpenSBI 仓库" >&2
    exit 1
fi

cd "$REPO"
make distclean
echo "cleaned: $REPO/build"
