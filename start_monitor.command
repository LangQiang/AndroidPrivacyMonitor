#!/bin/bash

# macOS双击可执行文件
# 自动在终端中运行Frida隐私监控

# 设置终端标题
echo -ne "\033]0;Frida隐私监控启动器\007"

# 清屏并显示欢迎信息
clear
echo "=========================================="
echo "   Frida Android 隐私监控启动器 v3.6"
echo "   适用于: macOS 平台"  
echo "   作者: GodQ"
echo "=========================================="
echo ""

# 获取脚本所在目录并切换
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || {
    echo "❌ 错误: 无法切换到项目目录"
    echo "按任意键退出..."
    read -n 1
    exit 1
}

echo "📂 项目目录: $(pwd)"
echo "🚀 正在启动Frida隐私监控..."
echo ""

# 检查lib目录下的启动脚本是否存在
if [ ! -f "lib/start_monitor.sh" ]; then
    echo "❌ 错误: 未找到启动脚本 lib/start_monitor.sh"
    echo "请确保在正确的项目目录中运行此文件"
    echo ""
    echo "按任意键退出..."
    read -n 1
    exit 1
fi

# 执行启动脚本
./lib/start_monitor.sh

# 监控结束后提示
echo ""
echo "🔄 监控已结束"
echo "按任意键关闭终端..."
read -n 1 