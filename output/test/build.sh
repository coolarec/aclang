#!/usr/bin/env bash

# ---------------------------------------------------------
# 0. 参数检查
# ---------------------------------------------------------
if [ $# -ne 1 ]; then
    echo "[ERROR] 用法: $0 <input_file>"
    exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
    echo "[ERROR] 文件不存在: $INPUT_FILE"
    exit 1
fi

# ---------------------------------------------------------
# 1. 环境与变量初始化
# ---------------------------------------------------------
BASENAME=$(basename "$INPUT_FILE")
BASENAME="${BASENAME%.*}"

OUTPUT_DIR="$BASENAME"
ASM_FILE="$OUTPUT_DIR/$BASENAME.asm"
OBJ_FILE="$OUTPUT_DIR/$BASENAME.o"
EXE_FILE="$OUTPUT_DIR/$BASENAME"

# 创建输出目录
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo "[INFO] Created output directory: $OUTPUT_DIR"
fi

echo
echo "[INFO] Initializing build pipeline for: $INPUT_FILE"
echo "--------------------------------------------------------"

# ---------------------------------------------------------
# 2. Step 1: AC → Assembly
# ---------------------------------------------------------
echo "[STEP 1] Running AC Transpiler (acc)..."

if ! ./acc < "$INPUT_FILE" > "$ASM_FILE"; then
    echo "[CRITICAL ERROR] Transpiler failed"
    echo "Check your $INPUT_FILE for syntax errors."
    exit 1
fi

echo "  >> Success: Created $ASM_FILE"

# ---------------------------------------------------------
# 3. Step 2: NASM 汇编
# ---------------------------------------------------------
echo "[STEP 2] Assembling with NASM..."

OS=$(uname -s)
ARCH=$(uname -m)

FMT=""

case "$OS" in
    MINGW*|MSYS*|CYGWIN*)
        if [[ "$ARCH" == "x86_64" ]]; then
            FMT="win64"
        else
            FMT="win32"
        fi
        ;;
    Linux)
        if [[ "$ARCH" == "x86_64" ]]; then
            FMT="elf64"
        else
            FMT="elf32"
        fi
        ;;
    Darwin)
        if [[ "$ARCH" == "x86_64" ]]; then
            FMT="macho64"
        else
            FMT="macho32"
        fi
        ;;
    *)
        echo "[CRITICAL ERROR] Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "  >> NASM format: $FMT"

if ! nasm -f "$FMT" "$ASM_FILE" -o "$OBJ_FILE"; then
    echo "[CRITICAL ERROR] NASM Assembly failed"
    exit 1
fi

echo "  >> Success: Created $OBJ_FILE"


# ---------------------------------------------------------
# 4. Step 3: GCC 链接
# ---------------------------------------------------------
echo "[STEP 3] Linking with GCC..."

if ! gcc "$OBJ_FILE" -o "$EXE_FILE"; then
    echo "[CRITICAL ERROR] GCC Linker failed"
    exit 1
fi

echo "  >> Success: Created $EXE_FILE"

# ---------------------------------------------------------
# 5. 完成
# ---------------------------------------------------------
echo "--------------------------------------------------------"
echo "[COMPLETED] Application built successfully!"
echo "Executable Path: ./$EXE_FILE"
