#!/bin/bash

# Frida Android 隐私监控启动脚本 v3.6
# 用于快速启动对目标应用的隐私API监控
# 优化: 使用bash原生配置解析

# 配置文件路径
CONFIG_FILE="config.conf"

# 默认配置
DEFAULT_TARGET_PACKAGE="com.frog.educate"
DEFAULT_LOG_DIR="./logs"
DEFAULT_LOG_PREFIX="frida_log"
DEFAULT_AUTO_EXTRACT="true"

# 读取配置文件函数 (使用bash原生source)
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "⚙️ 读取配置文件: $CONFIG_FILE"
        
        # 直接source配置文件 - bash原生支持注释！
        source "$CONFIG_FILE"
        
        echo "✅ 配置文件加载完成"
    else
        echo "⚠️ 未找到配置文件 $CONFIG_FILE，使用默认配置"
    fi
    
    # 设置默认值（如果配置文件中没有设置）
    TARGET_PACKAGE="${TARGET_PACKAGE:-$DEFAULT_TARGET_PACKAGE}"
    LOG_DIR="${LOG_DIR:-$DEFAULT_LOG_DIR}"
    LOG_PREFIX="${LOG_PREFIX:-$DEFAULT_LOG_PREFIX}"
    AUTO_EXTRACT_STACKS="${AUTO_EXTRACT_STACKS:-$DEFAULT_AUTO_EXTRACT}"
    
    # 验证必填项
    if [ -z "$TARGET_PACKAGE" ]; then
        echo "❌ 错误: 目标应用包名不能为空"
        echo "💡 请在 $CONFIG_FILE 中设置 TARGET_PACKAGE=your.app.package"
        exit 1
    fi
}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 加载配置
load_config

echo "🚀 启动Frida隐私监控 v3.6..."
echo "🎯 目标应用: ${TARGET_PACKAGE}"
echo "📋 监控脚本: lib/privacy_monitor_ultimate.js v2.2"
echo "🔧 优化: 使用bash原生source解析"
echo "📁 日志目录: ${LOG_DIR}"
if [ -n "$PROXY_URL" ]; then
    echo "🌐 代理地址: ${PROXY_URL}"
fi
echo "👨‍💻 作者: GodQ"
echo "===================================="

# 自动部署标志
AUTO_DEPLOY_NEEDED=false
DEPLOY_ACTIONS=()

# 网络检测函数（按需调用）
function check_network_for_download() {
    echo -e "${BLUE}🔍 检查网络连接（下载需要）...${NC}"
    
    # 设置代理（如果配置了）
    local curl_proxy=""
    local wget_proxy=""
    if [ -n "$PROXY_URL" ]; then
        curl_proxy="--proxy $PROXY_URL"
        wget_proxy="--proxy=$PROXY_URL"
        echo -e "${BLUE}🌐 使用代理: $PROXY_URL${NC}"
    fi
    
    if command -v curl &> /dev/null; then
        if curl -I --connect-timeout 10 --max-time 15 $curl_proxy https://github.com &> /dev/null; then
            echo -e "${GREEN}✅ 网络连接正常，可访问GitHub${NC}"
            return 0
        else
            echo -e "${RED}❌ 无法访问GitHub，frida-server下载失败${NC}"
            echo -e "${YELLOW}💡 请检查网络连接或代理设置${NC}"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if wget --spider --timeout=10 --tries=1 $wget_proxy https://github.com &> /dev/null; then
            echo -e "${GREEN}✅ 网络连接正常，可访问GitHub${NC}"
            return 0
        else
            echo -e "${RED}❌ 无法访问GitHub，frida-server下载失败${NC}"
            echo -e "${YELLOW}💡 请检查网络连接或代理设置${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ 未找到curl或wget工具${NC}"
        echo -e "${YELLOW}💡 请安装curl或wget用于下载frida-server${NC}"
        return 1
    fi
}

# 自动部署函数
function auto_deploy_frida_server() {
    echo -e "\n${MAGENTA}🔧 [自动部署] 开始部署frida-server...${NC}"
    
    # 获取Frida版本
    FRIDA_VERSION=$(frida --version 2>/dev/null)
    if [ -z "$FRIDA_VERSION" ]; then
        echo -e "${RED}❌ 无法获取Frida版本${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📋 Frida版本: ${FRIDA_VERSION}${NC}"
    echo -e "${BLUE}📋 目标架构: ${DEVICE_ARCH}${NC}"
    
    # 根据设备架构确定frida-server文件名
    case "$DEVICE_ARCH" in
        "arm64-v8a"|"arm64")
            FRIDA_ARCH="arm64"
            ;;
        "armeabi-v7a"|"armeabi"|"arm")
            FRIDA_ARCH="arm"
            ;;
        "x86_64")
            FRIDA_ARCH="x86_64"
            ;;
        "x86")
            FRIDA_ARCH="x86"
            ;;
        *)
            echo -e "${RED}❌ 不支持的设备架构: ${DEVICE_ARCH}${NC}"
            return 1
            ;;
    esac
    
    FRIDA_SERVER_FILE="lib/frida-server-android-${FRIDA_ARCH}"
    
    # 检查本地是否已有frida-server文件
    if [ -f "$FRIDA_SERVER_FILE" ]; then
        echo -e "${GREEN}✅ 发现本地frida-server文件: ${FRIDA_SERVER_FILE}${NC}"
    else
        echo -e "${YELLOW}📥 需要下载frida-server-${FRIDA_VERSION}-android-${FRIDA_ARCH}...${NC}"
        
        # 只在需要下载时检测网络
        if ! check_network_for_download; then
            return 1
        fi
        
        # 下载frida-server
        DOWNLOAD_URL="https://github.com/frida/frida/releases/download/${FRIDA_VERSION}/frida-server-${FRIDA_VERSION}-android-${FRIDA_ARCH}.xz"
        
        # 设置代理参数
        local curl_proxy=""
        local wget_proxy=""
        if [ -n "$PROXY_URL" ]; then
            curl_proxy="--proxy $PROXY_URL"
            wget_proxy="--proxy=$PROXY_URL"
        fi
        
        if command -v curl &> /dev/null; then
            curl -L $curl_proxy -o "frida-server-${FRIDA_VERSION}-android-${FRIDA_ARCH}.xz" "$DOWNLOAD_URL"
        elif command -v wget &> /dev/null; then
            wget $wget_proxy -O "frida-server-${FRIDA_VERSION}-android-${FRIDA_ARCH}.xz" "$DOWNLOAD_URL"
        else
            echo -e "${RED}❌ 未找到curl或wget下载工具${NC}"
            return 1
        fi
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ frida-server下载失败${NC}"
            return 1
        fi
        
        # 解压文件
        echo -e "${YELLOW}📦 解压frida-server...${NC}"
        if command -v unxz &> /dev/null; then
            unxz "frida-server-${FRIDA_VERSION}-android-${FRIDA_ARCH}.xz"
            mv "frida-server-${FRIDA_VERSION}-android-${FRIDA_ARCH}" "$FRIDA_SERVER_FILE"
        else
            echo -e "${RED}❌ 未找到unxz解压工具${NC}"
            return 1
        fi
        
        echo -e "${GREEN}✅ frida-server下载完成${NC}"
    fi
    
    # 推送到设备
    echo -e "${YELLOW}📤 推送frida-server到设备...${NC}"
    if adb push "$FRIDA_SERVER_FILE" "/data/local/tmp/frida-server"; then
        echo -e "${GREEN}✅ frida-server推送成功${NC}"
    else
        echo -e "${RED}❌ frida-server推送失败${NC}"
        return 1
    fi
    
    # 设置执行权限
    echo -e "${YELLOW}🔐 设置执行权限...${NC}"
    if adb shell chmod 755 "/data/local/tmp/frida-server"; then
        echo -e "${GREEN}✅ 权限设置成功${NC}"
    else
        echo -e "${RED}❌ 权限设置失败${NC}"
        return 1
    fi
    
    # 启动frida-server
    echo -e "${YELLOW}🚀 启动frida-server...${NC}"
    adb shell "/data/local/tmp/frida-server &" &
    
    # 等待启动
    sleep 3
    
    # 验证启动
    FRIDA_PID=$(adb shell ps | grep frida-server | awk '{print $2}' | head -n 1)
    if [ -n "$FRIDA_PID" ]; then
        echo -e "${GREEN}✅ frida-server启动成功 PID: ${FRIDA_PID}${NC}"
        return 0
    else
        echo -e "${RED}❌ frida-server启动失败${NC}"
        return 1
    fi
}

# 1. 检查Frida是否安装
echo "🔍 [1/9] 检查Frida工具..."
if ! command -v frida &> /dev/null; then
    echo -e "${RED}❌ 错误: 未找到Frida工具${NC}"
    echo -e "${YELLOW}💡 请先安装: pip install frida-tools${NC}"
    exit 1
fi

FRIDA_VERSION=$(frida --version 2>/dev/null)
echo -e "${GREEN}✅ Frida工具已安装: ${FRIDA_VERSION}${NC}"

# 2. 检查ADB连接
echo -e "\n🔍 [2/9] 检查ADB连接..."
if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ 错误: 未找到ADB工具${NC}"
    echo -e "${YELLOW}💡 请安装Android SDK或platform-tools${NC}"
    exit 1
fi

# 检查设备连接
DEVICES=$(adb devices | grep -v "List of devices" | grep -v "^$" | wc -l)
if [ "$DEVICES" -eq 0 ]; then
    echo -e "${RED}❌ 错误: 未检测到连接的设备${NC}"
    echo -e "${YELLOW}💡 请确保:${NC}"
    echo -e "${YELLOW}   1. 模拟器已启动或设备已连接${NC}"
    echo -e "${YELLOW}   2. USB调试已开启${NC}"
    echo -e "${YELLOW}   3. 运行 'adb devices' 检查设备状态${NC}"
    exit 1
fi

# 获取设备信息
DEVICE_INFO=$(adb devices | grep -v "List of devices" | grep -v "^$" | head -n 1)
DEVICE_ID=$(echo $DEVICE_INFO | awk '{print $1}')
DEVICE_STATUS=$(echo $DEVICE_INFO | awk '{print $2}')

if [ "$DEVICE_STATUS" != "device" ]; then
    echo -e "${RED}❌ 错误: 设备状态异常: ${DEVICE_STATUS}${NC}"
    echo -e "${YELLOW}💡 请确保设备已正确连接并授权${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 设备连接正常: ${DEVICE_ID}${NC}"

# 3. 检测设备类型和Root状态
echo -e "\n🔍 [3/9] 检测设备类型和权限..."

# 检查是否为模拟器
IS_EMULATOR="false"
if echo "$DEVICE_ID" | grep -q "emulator"; then
    IS_EMULATOR="true"
    echo -e "${GREEN}📱 检测到模拟器设备${NC}"
else
    echo -e "${BLUE}📱 检测到物理设备${NC}"
fi

# 检查Root权限
ROOT_CHECK=$(adb shell "id" 2>/dev/null | grep "uid=0(root)")
if [ -n "$ROOT_CHECK" ]; then
    echo -e "${GREEN}🔓 设备已获得Root权限${NC}"
    HAS_ROOT="true"
else
    # 备用检测方法：检查whoami命令
    WHOAMI_CHECK=$(adb shell "whoami" 2>/dev/null)
    if [ "$WHOAMI_CHECK" = "root" ]; then
        echo -e "${GREEN}🔓 设备已获得Root权限${NC}"
        HAS_ROOT="true"
    else
        echo -e "${RED}❌ 设备未获得Root权限${NC}"
        echo -e "${YELLOW}💡 Frida监控需要Root权限，无法继续${NC}"
        echo -e "${YELLOW}🔧 请使用root模拟器或root物理设备${NC}"
        exit 1
    fi
fi

# 4. 检测设备架构
echo -e "\n🔍 [4/9] 检测设备架构..."
DEVICE_ARCH=$(adb shell getprop ro.product.cpu.abi 2>/dev/null)
if [ -z "$DEVICE_ARCH" ]; then
    echo -e "${RED}❌ 无法获取设备架构信息${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 设备架构: ${DEVICE_ARCH}${NC}"

# 验证架构支持
case "$DEVICE_ARCH" in
    "arm64-v8a"|"arm64")
        echo -e "${BLUE}📋 将使用ARM64版本的frida-server${NC}"
        ;;
    "armeabi-v7a"|"armeabi"|"arm")
        echo -e "${BLUE}📋 将使用ARM版本的frida-server${NC}"
        ;;
    "x86_64")
        echo -e "${BLUE}📋 将使用x86_64版本的frida-server${NC}"
        ;;
    "x86")
        echo -e "${BLUE}📋 将使用x86版本的frida-server${NC}"
        ;;
    *)
        echo -e "${RED}❌ 不支持的设备架构: ${DEVICE_ARCH}${NC}"
        echo -e "${YELLOW}💡 支持的架构: arm64-v8a, armeabi-v7a, x86_64, x86${NC}"
        exit 1
        ;;
esac

# 5. 检查磁盘空间
echo -e "\n🔍 [5/9] 检查磁盘空间..."

# 检查本地磁盘空间
if command -v df &> /dev/null; then
    LOCAL_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/[^0-9.]//g')
    if [ -n "$LOCAL_SPACE" ]; then
        # 简单检查是否有足够空间
        if (( $(echo "$LOCAL_SPACE > 0.1" | bc -l 2>/dev/null || echo "1") )); then
            echo -e "${GREEN}✅ 本地磁盘空间充足${NC}"
        else
            echo -e "${YELLOW}⚠️ 本地磁盘空间可能不足${NC}"
        fi
    else
        echo -e "${BLUE}📋 无法精确检测本地磁盘空间，继续执行${NC}"
    fi
else
    echo -e "${BLUE}📋 无法检测磁盘空间，继续执行${NC}"
fi

# 检查设备存储空间
DEVICE_SPACE=$(adb shell df /data/local/tmp 2>/dev/null | tail -n 1 | awk '{print $4}')
if [ -n "$DEVICE_SPACE" ] && [ "$DEVICE_SPACE" -gt 51200 ]; then  # 50MB = 51200KB
    echo -e "${GREEN}✅ 设备存储空间充足${NC}"
else
    echo -e "${YELLOW}⚠️ 设备/data/local/tmp空间可能不足${NC}"
fi

# 6. 检查frida-server状态
echo -e "\n🔍 [6/9] 检查frida-server状态..."

# 检查frida-server是否在运行
FRIDA_PID=$(adb shell ps | grep frida-server | awk '{print $2}' | head -n 1)
if [ -n "$FRIDA_PID" ]; then
    echo -e "${GREEN}✅ frida-server正在运行 PID: ${FRIDA_PID}${NC}"
    FRIDA_SERVER_RUNNING=true
else
    echo -e "${YELLOW}⚠️ frida-server未运行${NC}"
    FRIDA_SERVER_RUNNING=false
    
    # 检查frida-server是否已部署
    if adb shell ls "/data/local/tmp/frida-server" &> /dev/null; then
        echo -e "${BLUE}📋 frida-server已部署，但未运行${NC}"
        DEPLOY_ACTIONS+=("启动frida-server")
        AUTO_DEPLOY_NEEDED=true
    else
        echo -e "${YELLOW}📋 frida-server未部署${NC}"
        DEPLOY_ACTIONS+=("下载frida-server" "部署frida-server" "启动frida-server")
        AUTO_DEPLOY_NEEDED=true
    fi
fi

# 7. 检查Frida连接
echo -e "\n🔍 [7/9] 检查Frida连接..."
if frida-ps -U &> /dev/null; then
    PROCESS_COUNT=$(frida-ps -U | wc -l)
    echo -e "${GREEN}✅ Frida连接正常，检测到 ${PROCESS_COUNT} 个进程${NC}"
    FRIDA_CONNECTION_OK=true
else
    echo -e "${YELLOW}⚠️ Frida无法连接到设备${NC}"
    FRIDA_CONNECTION_OK=false
    if [ "$FRIDA_SERVER_RUNNING" = false ]; then
        echo -e "${BLUE}💡 这是因为frida-server未运行，将自动处理${NC}"
    else
        echo -e "${RED}❌ frida-server运行中但连接失败，可能存在其他问题${NC}"
    fi
fi

# 8. 检查目标应用
echo -e "\n🔍 [8/9] 检查目标应用..."

# 检查应用是否已安装
if adb shell pm list packages | grep -q "$TARGET_PACKAGE"; then
    echo -e "${GREEN}✅ 目标应用已安装: ${TARGET_PACKAGE}${NC}"
    
    # 获取应用版本信息
    APP_VERSION=$(adb shell dumpsys package "$TARGET_PACKAGE" | grep "versionName" | head -n 1 | awk -F'=' '{print $2}')
    APP_VERSION_CODE=$(adb shell dumpsys package "$TARGET_PACKAGE" | grep "versionCode" | head -n 1 | awk -F'=' '{print $2}' | awk '{print $1}')
    
    if [ -n "$APP_VERSION" ]; then
        echo -e "${BLUE}📦 应用版本: ${APP_VERSION} 版本号${APP_VERSION_CODE}${NC}"
    fi
    
    # 检查应用是否正在运行
    if adb shell ps | grep -q "$TARGET_PACKAGE"; then
        echo -e "${YELLOW}⚠️ 应用正在运行，将强制停止后重新启动${NC}"
        adb shell am force-stop "$TARGET_PACKAGE"
        sleep 1
    fi
    
    APP_INSTALLED=true
else
    echo -e "${RED}❌ 目标应用未安装: ${TARGET_PACKAGE}${NC}"
    echo -e "${YELLOW}💡 请先安装目标应用后再运行监控${NC}"
    
    # 检查是否有其他相关应用
    echo -e "\n🔍 查找相关应用..."
    RELATED_APPS=$(adb shell pm list packages | grep -E "(frog|educate)")
    if [ -n "$RELATED_APPS" ]; then
        echo -e "${BLUE}📱 发现相关应用:${NC}"
        echo "$RELATED_APPS" | while read app; do
            echo -e "   ${BLUE}• ${app#package:}${NC}"
        done
        echo -e "${YELLOW}💡 如需监控其他应用，请修改配置文件中的包名${NC}"
    fi
    
    echo -e "\n${CYAN}🔧 安装建议:${NC}"
    echo -e "${YELLOW}   1. 通过应用商店安装 ${TARGET_PACKAGE}${NC}"
    echo -e "${YELLOW}   2. 或使用: adb install /path/to/app.apk${NC}"
    echo -e "${YELLOW}   3. 安装完成后重新运行此脚本${NC}"
    
    APP_INSTALLED=false
    
    # 询问用户是否继续等待
    echo ""
    read -p "应用未安装，按 Enter 键退出去安装应用，或输入 'wait' 等待应用安装..." -r user_choice
    if [ "$user_choice" = "wait" ] || [ "$user_choice" = "WAIT" ]; then
        echo -e "${YELLOW}⏳ 等待应用安装，请在另一个终端安装应用...${NC}"
        echo -e "${YELLOW}💡 安装完成后按任意键继续${NC}"
        read -p "应用安装完成后按 Enter 键继续..." -r
        
        # 重新检查应用
        if adb shell pm list packages | grep -q "$TARGET_PACKAGE"; then
            echo -e "${GREEN}✅ 检测到应用已安装${NC}"
            APP_INSTALLED=true
        else
            echo -e "${RED}❌ 仍未检测到应用安装${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

# 9. 检查监控脚本
echo -e "\n🔍 [9/9] 检查监控脚本..."
if [ ! -f "lib/privacy_monitor_ultimate.js" ]; then
    echo -e "${RED}❌ 错误: 未找到监控脚本 lib/privacy_monitor_ultimate.js${NC}"
    exit 1
fi

SCRIPT_SIZE=$(wc -l < lib/privacy_monitor_ultimate.js)
echo -e "${GREEN}✅ 监控脚本已就绪 ${SCRIPT_SIZE} 行代码${NC}"

# 智能自动部署处理
if [ "$AUTO_DEPLOY_NEEDED" = true ]; then
    echo -e "\n${MAGENTA}🔧 [智能部署] 检测到环境不完整，但符合自动部署条件${NC}"
    echo -e "${BLUE}📋 需要执行的操作:${NC}"
    for action in "${DEPLOY_ACTIONS[@]}"; do
        echo -e "   ${YELLOW}• ${action}${NC}"
    done
    
    echo -e "\n${CYAN}💡 由于设备满足基本要求（Root权限✅），将自动完成部署${NC}"
    read -p "按 Enter 键开始自动部署，或按 Ctrl+C 取消..." -r
    
    # 执行自动部署
    if auto_deploy_frida_server; then
        echo -e "\n${GREEN}🎉 自动部署完成！${NC}"
        
        # 重新检查Frida连接
        echo -e "\n🔍 重新检查Frida连接..."
        if frida-ps -U &> /dev/null; then
            PROCESS_COUNT=$(frida-ps -U | wc -l)
            echo -e "${GREEN}✅ Frida连接正常，检测到 ${PROCESS_COUNT} 个进程${NC}"
            FRIDA_CONNECTION_OK=true
        else
            echo -e "${RED}❌ 自动部署后Frida连接仍然失败${NC}"
            exit 1
        fi
    else
        echo -e "\n${RED}❌ 自动部署失败${NC}"
        echo -e "${YELLOW}💡 请手动运行: ./docs/setup_frida_environment.sh${NC}"
        exit 1
    fi
fi

# 环境检查完成，显示总结
echo -e "\n${GREEN}🎉 环境检查完成! 所有条件均满足${NC}"
echo -e "${BLUE}=================================${NC}"
echo -e "${GREEN}✅ Frida工具: ${FRIDA_VERSION}${NC}"
echo -e "${GREEN}✅ 设备连接: ${DEVICE_ID}${NC}"
if [ "$IS_EMULATOR" = "true" ]; then
    echo -e "${GREEN}✅ 设备类型: 模拟器${NC}"
else
    echo -e "${GREEN}✅ 设备类型: 物理设备${NC}"
fi
echo -e "${GREEN}✅ 设备架构: ${DEVICE_ARCH}${NC}"
echo -e "${GREEN}✅ Root权限: 已获得${NC}"
echo -e "${GREEN}✅ 磁盘空间: 充足${NC}"
echo -e "${GREEN}✅ frida-server: 运行中${NC}"
echo -e "${GREEN}✅ Frida连接: 正常${NC}"
echo -e "${GREEN}✅ 目标应用: ${TARGET_PACKAGE}${NC}"
echo -e "${GREEN}✅ 监控脚本: lib/privacy_monitor_ultimate.js v2.2${NC}"
echo -e "${GREEN}✅ 配置文件: ${CONFIG_FILE}${NC}"
if [ "$AUTO_DEPLOY_NEEDED" = true ]; then
    echo -e "${MAGENTA}✅ 自动部署: 已完成${NC}"
fi
echo -e "${BLUE}=================================${NC}"

echo -e "\n${YELLOW}🚀 即将启动隐私监控...${NC}"
echo -e "${YELLOW}💡 提示: 按 Ctrl+C 停止监控${NC}"
echo -e "${YELLOW}🔍 监控范围: 设备标识符、位置、联系人、相机、麦克风等${NC}"
echo ""

# 询问用户是否继续
read -p "按 Enter 键开始监控，或按 Ctrl+C 取消..." -r

# 创建日志目录和文件
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${LOG_DIR}/${LOG_PREFIX}_${TIMESTAMP}.txt"

if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    echo -e "${GREEN}📁 创建日志目录: ${LOG_DIR}${NC}"
fi

echo -e "${BLUE}📝 日志文件: ${LOG_FILE}${NC}"

# 启动监控
echo -e "${GREEN}🔥 启动Frida隐私监控...${NC}"
echo -e "${YELLOW}💡 所有输出将同时保存到日志文件${NC}"
echo ""

# 使用tee命令同时输出到控制台和文件
frida -U -l lib/privacy_monitor_ultimate.js -f "$TARGET_PACKAGE" 2>&1 | tee "$LOG_FILE"

# 监控结束后的提示
echo ""
echo -e "${GREEN}🔄 监控已结束${NC}"
echo -e "${BLUE}📁 日志文件已保存到: ${LOG_FILE}${NC}"

# 检查是否自动提取堆栈
if [ "$AUTO_EXTRACT_STACKS" = "true" ]; then
    echo ""
    echo -e "${YELLOW}🔍 自动提取堆栈信息...${NC}"
    if [ -f "./lib/extract_stacks.sh" ]; then
        ./lib/extract_stacks.sh "$LOG_FILE"
        echo -e "${GREEN}✅ 堆栈信息提取完成${NC}"
    else
        echo -e "${RED}❌ 未找到堆栈提取脚本 lib/extract_stacks.sh${NC}"
        echo -e "${YELLOW}💡 您可以手动运行: ./lib/extract_stacks.sh \"${LOG_FILE}\"${NC}"
    fi
fi 