#!/bin/bash

# 提取堆栈信息脚本
# 用法: ./extract_stacks.sh <日志文件> [输出文件]

if [ $# -eq 0 ]; then
    echo "用法: $0 <日志文件> [输出文件]"
    echo "示例: $0 ./monitor_log/frida_log_2025-06-04_11-05-31.txt"
    echo "示例: $0 ./monitor_log/frida_log_2025-06-04_11-05-31.txt stacks_only.txt"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.txt}_stacks_only.txt}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ 错误: 文件不存在 $INPUT_FILE"
    exit 1
fi

echo "🔍 从 $INPUT_FILE 提取堆栈信息..."
echo "📝 输出到 $OUTPUT_FILE"

# 使用awk提取STACK_START和STACK_END之间的内容
awk '
/===== STACK_START =====/ { 
    in_stack = 1
    print "=========================================="
    next 
}
/===== STACK_END =====/ { 
    in_stack = 0
    print "=========================================="
    print ""
    next 
}
in_stack { print }
' "$INPUT_FILE" > "$OUTPUT_FILE"

# 统计提取的堆栈数量
STACK_COUNT=$(grep -c "STACK_START" "$INPUT_FILE")

echo "✅ 提取完成!"
echo "📊 共提取 $STACK_COUNT 个堆栈信息"
echo "📁 纯堆栈文件: $OUTPUT_FILE" 