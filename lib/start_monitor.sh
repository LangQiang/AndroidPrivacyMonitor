#!/bin/bash

# Frida Android 隐私监控启动脚本 v3.6
# 用于快速启动对目标应用的隐私API监控
# 优化: 使用安全的eval配置解析，配置化监控脚本

# 临时智能路径检测（仅用于加载第一个模块）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 加载所有模块
source "$PROJECT_ROOT/lib/utils/logger.sh"
source "$PROJECT_ROOT/lib/utils/config_manager.sh"
source "$PROJECT_ROOT/lib/core/script_generator.sh"
source "$PROJECT_ROOT/lib/core/environment_checker.sh"
source "$PROJECT_ROOT/lib/core/device_manager.sh"
source "$PROJECT_ROOT/lib/core/frida_service_manager.sh"
source "$PROJECT_ROOT/lib/core/app_manager.sh"
source "$PROJECT_ROOT/lib/core/monitor_launcher.sh"

# 初始化项目环境和配置
initialize_project

# 1. 检查Frida是否安装
check_frida_tools

# 2. 检查ADB连接
check_adb_tools

# 3-5. 设备管理（多设备检查、架构检测、磁盘空间检查）
manage_devices

# 6-7. Frida服务管理（frida-server检查、连接验证、自动部署）
manage_frida_service

# 8-9. 应用管理（目标应用检查、配置文件验证）
manage_application

# 启动监控系统
launch_monitor 