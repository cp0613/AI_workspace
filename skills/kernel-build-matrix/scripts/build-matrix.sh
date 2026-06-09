#!/bin/bash
# build-matrix.sh — 内核多架构编译矩阵
#
# 用法:
#   bash build-matrix.sh [选项]
#
# 选项 (全部可选):
#   --src PATH              内核源码树根目录（默认当前目录）
#   --target SPEC           ARCH:CROSS_COMPILE:DEFCONFIG，可多次指定
#   --matrix FILE           从文件读取矩阵（每行一个 SPEC，# 注释）
#   --extra-cflags FLAGS    追加到 EXTRA_CFLAGS（默认 "-Werror -g"）
#   --extra-kcflags FLAGS   追加到 KCFLAGS
#   --jobs N                -jN（默认 nproc）
#   --targets-only          只编译 vmlinux，不编译模块
#   --no-modules            跳过 modules 编译
#   --stop-on-error         遇到失败立即停止（默认）
#   --clean                 每个目标编译前 make clean
#   --out-dir PATH          O= 输出目录前缀
#   --dry-run               只打印 plan 不执行
#   -h, --help              显示帮助

set -uo pipefail

# ---- 加载全局 RISC-V 工具链配置 ----
[ -f ~/.agent_cfg/riscv_env.sh ] && source ~/.agent_cfg/riscv_env.sh

# ---- 默认值 ----
SRC_DIR=""
TARGETS=()
MATRIX_FILE=""
EXTRA_CFLAGS="-Werror -g"
EXTRA_KCFLAGS=""
JOBS=""
TARGETS_ONLY="false"
BUILD_MODULES="true"
STOP_ON_ERROR="true"
CLEAN="false"
OUT_DIR=""
DRY_RUN="false"

# ---- 参数解析 ----
while [ $# -gt 0 ]; do
    case "$1" in
        --src)              SRC_DIR="$2"; shift 2 ;;
        --target)           TARGETS+=("$2"); shift 2 ;;
        --matrix)           MATRIX_FILE="$2"; shift 2 ;;
        --extra-cflags)     EXTRA_CFLAGS="$2"; shift 2 ;;
        --extra-kcflags)    EXTRA_KCFLAGS="$2"; shift 2 ;;
        --jobs)             JOBS="$2"; shift 2 ;;
        --targets-only)     TARGETS_ONLY="true"; shift ;;
        --no-modules)       BUILD_MODULES="false"; shift ;;
        --modules)          BUILD_MODULES="true"; shift ;;
        --stop-on-error)     STOP_ON_ERROR="true"; shift ;;
        --continue-on-error) STOP_ON_ERROR="false"; shift ;;
        --clean)            CLEAN="true"; shift ;;
        --out-dir)          OUT_DIR="$2"; shift 2 ;;
        --dry-run)          DRY_RUN="true"; shift ;;
        -h|--help)          sed -n '2,18p' "$0"; exit 0 ;;
        *)                  echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
    esac
done

# ---- 源码定位 ----
if [ -z "$SRC_DIR" ]; then
    SRC_DIR="$(pwd)"
fi
SRC_DIR="$(cd "$SRC_DIR" && pwd)"

if [ ! -f "$SRC_DIR/Makefile" ] || [ ! -d "$SRC_DIR/scripts" ]; then
    echo "ERROR: $SRC_DIR 不是内核源码树（缺 Makefile 或 scripts/）" >&2
    exit 1
fi

# ---- 并行度 ----
if [ -z "$JOBS" ]; then
    JOBS="$(nproc 2>/dev/null || echo 4)"
fi

# ---- 解析矩阵文件 ----
if [ -n "$MATRIX_FILE" ]; then
    if [ ! -f "$MATRIX_FILE" ]; then
        echo "ERROR: 矩阵文件不存在: $MATRIX_FILE" >&2
        exit 1
    fi
    while IFS= read -r line; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"
        [ -z "$line" ] && continue
        TARGETS+=("$line")
    done < "$MATRIX_FILE"
fi

# ---- RISC-V 工具链自动解析 ----
resolve_riscv_cross() {
    local arch="$1"
    case "$arch" in
        riscv32) echo "${RISCV_CROSS_COMPILE_32:-${RISCV_CROSS_COMPILE_64:-}}" ;;
        *)       echo "${RISCV_CROSS_COMPILE_64:-/rvhome/chenp/toolchain/gcc/Xuantie-900-gcc-linux-6.6.36-glibc-x86_64-V3.4.0/bin/riscv64-unknown-linux-gnu-}" ;;
    esac
}

# ---- 展开 RISC-V 占位符 & 空 CROSS_COMPILE ----
expand_targets() {
    local -a expanded=()
    for spec in "${TARGETS[@]}"; do
        IFS=':' read -r t_arch t_cross t_def <<< "$spec"
        case "$t_arch" in
            riscv|riscv64|riscv32)
                if [ -z "$t_cross" ] || [ "$t_cross" = "__RISCV_ENV__" ]; then
                    t_cross="$(resolve_riscv_cross "$t_arch")"
                fi
                ;;
        esac
        expanded+=("${t_arch}:${t_cross}:${t_def}")
    done
    TARGETS=("${expanded[@]}")
}

# ---- 默认矩阵 ----
if [ ${#TARGETS[@]} -eq 0 ]; then
    TARGETS=(
        "arm64:aarch64-linux-gnu-:defconfig"
        "x86_64::defconfig"
        "riscv::xuantie_defconfig"
    )
fi

expand_targets

# ---- 查找工具链 ----
resolve_gcc() {
    local cross="$1"
    local gcc_bin

    if [ -z "$cross" ]; then
        gcc_bin="gcc"
    else
        gcc_bin="${cross}gcc"
    fi

    if [ -x "$gcc_bin" ]; then
        echo "$gcc_bin"
        return 0
    fi

    if command -v "$(basename "$gcc_bin")" >/dev/null 2>&1; then
        command -v "$(basename "$gcc_bin")"
        return 0
    fi

    echo ""
    return 1
}

gcc_version() {
    local gcc_bin="$1"
    if [ -n "$gcc_bin" ] && [ -x "$gcc_bin" ]; then
        "$gcc_bin" --version 2>/dev/null | head -1
    elif [ -n "$gcc_bin" ]; then
        "$(basename "$gcc_bin")" --version 2>/dev/null | head -1
    else
        echo "unknown"
    fi
}

# ---- ARCH 到 make 目标映射 ----
get_make_arch() {
    local arch="$1"
    case "$arch" in
        x86_64|x86) echo "x86" ;;
        arm64|aarch64) echo "arm64" ;;
        arm) echo "arm" ;;
        riscv|riscv64|riscv32) echo "riscv" ;;
        mips|mips64) echo "mips" ;;
        *) echo "$arch" ;;
    esac
}

get_defconfig_arch() {
    local arch="$1"
    case "$arch" in
        x86_64|x86) echo "x86" ;;
        *) get_make_arch "$arch" ;;
    esac
}

# ---- 格式化时间 ----
format_duration() {
    local secs=$1
    local mins=$((secs / 60))
    local remainder=$((secs % 60))
    if [ "$mins" -gt 0 ]; then
        printf "%dm %02ds" "$mins" "$remainder"
    else
        printf "%ds" "$remainder"
    fi
}

# ---- 打印分隔线 ----
print_sep() {
    printf '%.0s─' {1..72}
    echo
}

# ---- 结果数组 ----
declare -a RESULT_ARCH=()
declare -a RESULT_DEFCONFIG=()
declare -a RESULT_STATUS=()
declare -a RESULT_TIME=()
declare -a RESULT_CROSS=()
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                   Kernel Build Matrix                              ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Source : $SRC_DIR"
echo "  Jobs   : -j$JOBS"
echo "  CFLAGS : EXTRA_CFLAGS+=\"$EXTRA_CFLAGS\""
[ -n "$EXTRA_KCFLAGS" ] && echo "  KCFLAGS: KCFLAGS=\"$EXTRA_KCFLAGS\""
echo "  Targets: ${#TARGETS[@]}"
echo ""

# ---- 遍历矩阵 ----
IDX=0
for spec in "${TARGETS[@]}"; do
    IDX=$((IDX + 1))

    IFS=':' read -r T_ARCH T_CROSS T_DEFCONFIG <<< "$spec"

    if [ -z "$T_ARCH" ] || [ -z "$T_DEFCONFIG" ]; then
        echo "ERROR: invalid target spec: '$spec' (format: ARCH:CROSS_COMPILE:DEFCONFIG)" >&2
        RESULT_ARCH+=("$T_ARCH")
        RESULT_DEFCONFIG+=("$T_DEFCONFIG")
        RESULT_STATUS+=("SKIP")
        RESULT_TIME+=("0")
        RESULT_CROSS+=("$T_CROSS")
        TOTAL_SKIP=$((TOTAL_SKIP + 1))
        continue
    fi

    MAKE_ARCH="$(get_make_arch "$T_ARCH")"

    print_sep
    echo "[$IDX/${#TARGETS[@]}] ARCH=$MAKE_ARCH  CROSS_COMPILE=${T_CROSS:-(native)}  DEFCONFIG=$T_DEFCONFIG"
    print_sep

    # 查找工具链
    GCC_BIN="$(resolve_gcc "$T_CROSS")" || true
    if [ -z "$GCC_BIN" ]; then
        echo "  SKIP: toolchain not found: ${T_CROSS}gcc" >&2
        RESULT_ARCH+=("$MAKE_ARCH")
        RESULT_DEFCONFIG+=("$T_DEFCONFIG")
        RESULT_STATUS+=("SKIP")
        RESULT_TIME+=("0")
        RESULT_CROSS+=("$T_CROSS")
        TOTAL_SKIP=$((TOTAL_SKIP + 1))
        if [ "$STOP_ON_ERROR" = "true" ]; then
            echo "  --stop-on-error: aborting" >&2
            break
        fi
        continue
    fi

    echo "  GCC: $(gcc_version "$GCC_BIN")"

    if [ "$DRY_RUN" = "true" ]; then
        echo "  [DRY-RUN] would build: make ARCH=$MAKE_ARCH CROSS_COMPILE=$T_CROSS $T_DEFCONFIG && make all"
        RESULT_ARCH+=("$MAKE_ARCH")
        RESULT_DEFCONFIG+=("$T_DEFCONFIG")
        RESULT_STATUS+=("DRY")
        RESULT_TIME+=("0")
        RESULT_CROSS+=("$T_CROSS")
        continue
    fi

    START_TS=$(date +%s)
    LOG_FILE="$(mktemp -t kernel_build_${MAKE_ARCH}_XXXX.log)"
    BUILD_RC=0

    # 构造 make 命令公共部分
    MAKE_CMD=(make -C "$SRC_DIR" "ARCH=$MAKE_ARCH" "-j$JOBS")
    if [ -n "$T_CROSS" ]; then
        MAKE_CMD+=("CROSS_COMPILE=$T_CROSS")
    fi

    # 使用 O= 输出目录
    if [ -n "$OUT_DIR" ]; then
        BUILD_DIR="${OUT_DIR}/${MAKE_ARCH}"
        mkdir -p "$BUILD_DIR"
        MAKE_CMD+=("O=$BUILD_DIR")
    fi

    # clean
    if [ "$CLEAN" = "true" ]; then
        echo "  → make clean"
        "${MAKE_CMD[@]}" clean >> "$LOG_FILE" 2>&1 || true
    fi

    # defconfig
    echo "  → make $T_DEFCONFIG"
    if ! "${MAKE_CMD[@]}" "$T_DEFCONFIG" >> "$LOG_FILE" 2>&1; then
        BUILD_RC=1
        echo "  FAIL: defconfig failed" >&2
    fi

    # build
    if [ "$BUILD_RC" -eq 0 ]; then
        BUILD_TARGETS=()
        if [ "$TARGETS_ONLY" = "true" ]; then
            BUILD_TARGETS+=("vmlinux")
        else
            BUILD_TARGETS+=("all")
        fi

        EXTRA_MAKE_ARGS=()
        if [ -n "$EXTRA_CFLAGS" ]; then
            EXTRA_MAKE_ARGS+=("EXTRA_CFLAGS+=$EXTRA_CFLAGS")
        fi
        if [ -n "$EXTRA_KCFLAGS" ]; then
            EXTRA_MAKE_ARGS+=("KCFLAGS=$EXTRA_KCFLAGS")
        fi

        echo "  → make ${BUILD_TARGETS[*]} ${EXTRA_MAKE_ARGS[*]}"
        if ! "${MAKE_CMD[@]}" "${BUILD_TARGETS[@]}" "${EXTRA_MAKE_ARGS[@]}" >> "$LOG_FILE" 2>&1; then
            BUILD_RC=1
        fi
    fi

    # modules (if separate and requested)
    if [ "$BUILD_RC" -eq 0 ] && [ "$BUILD_MODULES" = "true" ] && [ "$TARGETS_ONLY" = "true" ]; then
        echo "  → make modules"
        EXTRA_MAKE_ARGS=()
        if [ -n "$EXTRA_CFLAGS" ]; then
            EXTRA_MAKE_ARGS+=("EXTRA_CFLAGS+=$EXTRA_CFLAGS")
        fi
        if [ -n "$EXTRA_KCFLAGS" ]; then
            EXTRA_MAKE_ARGS+=("KCFLAGS=$EXTRA_KCFLAGS")
        fi
        if ! "${MAKE_CMD[@]}" modules "${EXTRA_MAKE_ARGS[@]}" >> "$LOG_FILE" 2>&1; then
            BUILD_RC=1
        fi
    fi

    END_TS=$(date +%s)
    ELAPSED=$((END_TS - START_TS))

    if [ "$BUILD_RC" -eq 0 ]; then
        echo "  PASS  ($(format_duration $ELAPSED))"
        RESULT_STATUS+=("PASS")
        TOTAL_PASS=$((TOTAL_PASS + 1))
    else
        echo "  FAIL  ($(format_duration $ELAPSED))" >&2
        echo "" >&2
        echo "  ── last 30 lines ──" >&2
        tail -n 30 "$LOG_FILE" >&2
        echo "  ── end ──" >&2
        echo "  Full log: $LOG_FILE" >&2
        RESULT_STATUS+=("FAIL")
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi

    RESULT_ARCH+=("$MAKE_ARCH")
    RESULT_DEFCONFIG+=("$T_DEFCONFIG")
    RESULT_TIME+=("$ELAPSED")
    RESULT_CROSS+=("$T_CROSS")

    # 清理成功的日志
    if [ "$BUILD_RC" -eq 0 ]; then
        rm -f "$LOG_FILE"
    fi

    if [ "$BUILD_RC" -ne 0 ] && [ "$STOP_ON_ERROR" = "true" ]; then
        echo "  --stop-on-error: aborting remaining targets" >&2
        break
    fi

    echo ""
done

# ---- 汇总报告 ----
echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                   Build Matrix Report                              ║"
echo "╠══════════╦═════════════════════════╦════════╦═══════════════════════╣"
printf "║ %-8s ║ %-23s ║ %-6s ║ %-21s ║\n" "ARCH" "DEFCONFIG" "STATUS" "TIME"
echo "╠══════════╬═════════════════════════╬════════╬═══════════════════════╣"

for i in "${!RESULT_ARCH[@]}"; do
    STATUS="${RESULT_STATUS[$i]}"
    TIME_STR="$(format_duration "${RESULT_TIME[$i]}")"

    case "$STATUS" in
        PASS) STATUS_FMT="  PASS" ;;
        FAIL) STATUS_FMT="* FAIL" ;;
        SKIP) STATUS_FMT="- SKIP" ;;
        DRY)  STATUS_FMT="~ DRY " ;;
    esac

    DEFCONF="${RESULT_DEFCONFIG[$i]}"
    if [ ${#DEFCONF} -gt 23 ]; then
        DEFCONF="${DEFCONF:0:20}..."
    fi

    printf "║ %-8s ║ %-23s ║ %s ║ %-21s ║\n" \
        "${RESULT_ARCH[$i]}" "$DEFCONF" "$STATUS_FMT" "$TIME_STR"
done

echo "╚══════════╩═════════════════════════╩════════╩═══════════════════════╝"
echo ""
echo "Summary: $TOTAL_PASS passed, $TOTAL_FAIL failed, $TOTAL_SKIP skipped (${#TARGETS[@]} total)"

if [ "$TOTAL_FAIL" -gt 0 ]; then
    echo ""
    echo "FAILED targets:"
    for i in "${!RESULT_ARCH[@]}"; do
        if [ "${RESULT_STATUS[$i]}" = "FAIL" ]; then
            echo "  - ${RESULT_ARCH[$i]} (${RESULT_DEFCONFIG[$i]})"
        fi
    done
    exit 1
fi

exit 0
