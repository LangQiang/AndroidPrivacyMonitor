#!/bin/bash

# Linux双击可执行文件
# 适用于支持双击运行shell脚本的桌面环境

# 检查是否在终端中运行
if [ -t 0 ]; then
    # 在终端中运行
    TERMINAL_MODE=true
else
    # 双击运行，需要启动终端
    TERMINAL_MODE=false
fi

# 如果不在终端中，尝试在终端中重新运行
if [ "$TERMINAL_MODE" = false ]; then
    # 尝试各种终端启动器
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash "$0" terminal
        exit 0
    elif command -v konsole &> /dev/null; then
        konsole -e bash "$0" terminal
        exit 0
    elif command -v xterm &> /dev/null; then
        xterm -e bash "$0" terminal
        exit 0
    elif command -v x-terminal-emulator &> /dev/null; then
        x-terminal-emulator -e bash "$0" terminal
        exit 0
    else
        # 如果找不到终端，显示错误信息
        if command -v zenity &> /dev/null; then
            zenity --error --text="未找到可用的终端模拟器\n请在终端中手动运行: ./lib/start_monitor.sh"
        elif command -v kdialog &> /dev/null; then
            kdialog --error "未找到可用的终端模拟器\n请在终端中手动运行: ./lib/start_monitor.sh"
        fi
        exit 1
    fi
fi

# 以下是在终端中的执行逻辑
clear
echo "=========================================="
echo "   Frida Android 隐私监控启动器 v3.6"
echo "   适用于: Linux 平台"
echo "   作者: GodQ"
echo "=========================================="
echo ""

# 获取脚本所在目录并切换
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || {
    echo "❌ 错误: 无法切换到项目目录"
    echo "按Enter键退出..."
    read
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
    echo "按Enter键退出..."
    read
    exit 1
fi

# 执行启动脚本
./lib/start_monitor.sh

# 监控结束后提示
echo ""
echo "🔄 监控已结束"
echo "按Enter键关闭终端..."
read 