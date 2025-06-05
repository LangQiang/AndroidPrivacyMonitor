@echo off
chcp 65001 >nul
title Frida隐私监控启动器

echo ==========================================
echo    Frida Android 隐私监控启动器 v3.6
echo    适用于: Windows 平台
echo    作者: GodQ
echo ==========================================
echo.

echo 正在启动Frida隐私监控...
echo 注意: 请确保已安装 Git Bash 或 WSL
echo.

rem 检查是否有bash环境
where bash >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到bash环境
    echo.
    echo 请安装以下任一环境:
    echo 1. Git for Windows ^(推荐^): https://git-scm.com/download/win
    echo 2. WSL ^(Windows子系统^): wsl --install
    echo.
    pause
    exit /b 1
)

echo [信息] 检测到bash环境，正在启动监控脚本...
echo.

rem 执行lib目录下的启动脚本
bash lib/start_monitor.sh

echo.
echo [完成] 监控已结束
pause 