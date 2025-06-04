#!/bin/bash

# =============================================================================
# Frida Android 隐私监控环境一键搭建脚本
# 适用于 macOS/Linux 系统
# 作者: AI Assistant
# 版本: v1.0
# =============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# 全局变量
FRIDA_VERSION=""
ANDROID_ARCH="arm64"
FRIDA_SERVER_FILE=""
SETUP_LOG="frida_setup.log"
ERRORS_FOUND=0

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$SETUP_LOG"
}

# 打印函数
print_header() {
    echo -e "${BOLD}${BLUE}"
    echo "=================================================================="
    echo "🚀 Frida Android 隐私监控环境一键搭建脚本"
    echo "=================================================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${BOLD}${CYAN}📋 步骤 $1: $2${NC}"
    log "步骤 $1: $2"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log "成功: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log "警告: $1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log "错误: $1"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    log "信息: $1"
}

# 检查操作系统
check_os() {
    print_step "1" "检查操作系统"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_success "检测到 macOS 系统"
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_success "检测到 Linux 系统"
        OS_TYPE="linux"
    else
        print_error "不支持的操作系统: $OSTYPE"
        print_info "本脚本仅支持 macOS 和 Linux"
        exit 1
    fi
}

# 检查必要工具
check_required_tools() {
    print_step "2" "检查必要工具"
    
    # 检查 Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        print_success "Python3 已安装: $PYTHON_VERSION"
    else
        print_error "Python3 未安装，请先安装 Python3"
        return 1
    fi
    
    # 检查 pip
    if command -v pip3 &> /dev/null; then
        PIP_VERSION=$(pip3 --version 2>&1 | cut -d' ' -f2)
        print_success "pip3 已安装: $PIP_VERSION"
    else
        print_error "pip3 未安装，请先安装 pip3"
        return 1
    fi
    
    # 检查 curl/wget
    if command -v curl &> /dev/null; then
        print_success "curl 已安装"
        DOWNLOAD_TOOL="curl"
    elif command -v wget &> /dev/null; then
        print_success "wget 已安装"
        DOWNLOAD_TOOL="wget"
    else
        print_error "curl 或 wget 未安装，请先安装其中一个"
        return 1
    fi
    
    # 检查 unxz (用于解压 .xz 文件)
    if command -v unxz &> /dev/null || command -v xz &> /dev/null; then
        print_success "xz 解压工具已安装"
    else
        print_warning "xz 解压工具未安装，将尝试自动安装"
        if [[ "$OS_TYPE" == "macos" ]]; then
            if command -v brew &> /dev/null; then
                brew install xz
            else
                print_error "请先安装 Homebrew 或手动安装 xz 工具"
                return 1
            fi
        elif [[ "$OS_TYPE" == "linux" ]]; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y xz-utils
            elif command -v yum &> /dev/null; then
                sudo yum install -y xz
            else
                print_error "无法自动安装 xz 工具，请手动安装"
                return 1
            fi
        fi
    fi
}

# 检查 Android 环境
check_android_environment() {
    print_step "3" "检查 Android 环境"
    
    # 检查 ADB
    if command -v adb &> /dev/null; then
        ADB_VERSION=$(adb version 2>&1 | head -n1)
        print_success "ADB 已安装: $ADB_VERSION"
    else
        print_error "ADB 未安装"
        print_info "请安装 Android SDK Platform Tools"
        if [[ "$OS_TYPE" == "macos" ]]; then
            print_info "macOS 安装命令: brew install android-platform-tools"
        fi
        return 1
    fi
    
    # 检查设备连接
    print_info "检查 Android 设备连接..."
    DEVICES=$(adb devices | grep -v "List of devices" | grep -v "^$" | wc -l)
    
    if [ "$DEVICES" -eq 0 ]; then
        print_warning "未检测到 Android 设备"
        print_info "请确保:"
        print_info "  1. Android 模拟器已启动，或"
        print_info "  2. Android 设备已连接并开启 USB 调试"
        print_info "  3. 设备已授权 ADB 连接"
        
        read -p "是否继续安装？(设备可稍后连接) [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "安装已取消"
            exit 0
        fi
    else
        print_success "检测到 $DEVICES 个 Android 设备"
        adb devices
    fi
}

# 安装 Frida 工具
install_frida_tools() {
    print_step "4" "安装 Frida 工具"
    
    # 检查是否已安装
    if command -v frida &> /dev/null; then
        CURRENT_VERSION=$(frida --version 2>&1)
        print_info "Frida 已安装，当前版本: $CURRENT_VERSION"
        
        read -p "是否重新安装最新版本？[y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            FRIDA_VERSION=$CURRENT_VERSION
            print_info "跳过 Frida 安装"
            return 0
        fi
    fi
    
    print_info "正在安装 Frida 工具..."
    if pip3 install frida-tools --upgrade; then
        FRIDA_VERSION=$(frida --version 2>&1)
        print_success "Frida 工具安装成功: $FRIDA_VERSION"
    else
        print_error "Frida 工具安装失败"
        return 1
    fi
}

# 下载 frida-server
download_frida_server() {
    print_step "5" "下载 frida-server"
    
    # 获取 Frida 版本
    if [ -z "$FRIDA_VERSION" ]; then
        FRIDA_VERSION=$(frida --version 2>&1)
    fi
    
    print_info "当前 Frida 版本: $FRIDA_VERSION"
    
    # 构建下载 URL
    FRIDA_SERVER_FILE="frida-server-${FRIDA_VERSION}-android-${ANDROID_ARCH}.xz"
    DOWNLOAD_URL="https://github.com/frida/frida/releases/download/${FRIDA_VERSION}/${FRIDA_SERVER_FILE}"
    
    print_info "下载 URL: $DOWNLOAD_URL"
    
    # 检查文件是否已存在
    if [ -f "frida-server-android-${ANDROID_ARCH}" ]; then
        print_info "frida-server 文件已存在"
        
        read -p "是否重新下载？[y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "跳过下载"
            return 0
        fi
    fi
    
    # 下载文件
    print_info "正在下载 frida-server..."
    if [[ "$DOWNLOAD_TOOL" == "curl" ]]; then
        if curl -L -o "$FRIDA_SERVER_FILE" "$DOWNLOAD_URL"; then
            print_success "frida-server 下载成功"
        else
            print_error "frida-server 下载失败"
            return 1
        fi
    else
        if wget -O "$FRIDA_SERVER_FILE" "$DOWNLOAD_URL"; then
            print_success "frida-server 下载成功"
        else
            print_error "frida-server 下载失败"
            return 1
        fi
    fi
    
    # 解压文件
    print_info "正在解压 frida-server..."
    if unxz "$FRIDA_SERVER_FILE"; then
        # 重命名文件
        mv "frida-server-${FRIDA_VERSION}-android-${ANDROID_ARCH}" "frida-server-android-${ANDROID_ARCH}"
        print_success "frida-server 解压成功"
    else
        print_error "frida-server 解压失败"
        return 1
    fi
}

# 部署 frida-server 到设备
deploy_frida_server() {
    print_step "6" "部署 frida-server 到设备"
    
    # 再次检查设备连接
    DEVICES=$(adb devices | grep -v "List of devices" | grep -v "^$" | wc -l)
    if [ "$DEVICES" -eq 0 ]; then
        print_warning "未检测到 Android 设备，跳过部署"
        print_info "请稍后手动部署 frida-server"
        return 0
    fi
    
    # 检查设备架构
    print_info "检查设备架构..."
    DEVICE_ARCH=$(adb shell getprop ro.product.cpu.abi)
    print_info "设备架构: $DEVICE_ARCH"
    
    if [[ "$DEVICE_ARCH" != *"arm64"* ]] && [[ "$DEVICE_ARCH" != *"aarch64"* ]]; then
        print_warning "设备架构可能不兼容 ARM64 版本的 frida-server"
        print_info "设备架构: $DEVICE_ARCH"
        print_info "如果遇到问题，请下载对应架构的 frida-server"
    fi
    
    # 推送文件
    print_info "正在推送 frida-server 到设备..."
    if adb push "frida-server-android-${ANDROID_ARCH}" /data/local/tmp/frida-server; then
        print_success "frida-server 推送成功"
    else
        print_error "frida-server 推送失败"
        return 1
    fi
    
    # 设置权限
    print_info "设置 frida-server 执行权限..."
    if adb shell chmod 755 /data/local/tmp/frida-server; then
        print_success "权限设置成功"
    else
        print_error "权限设置失败"
        return 1
    fi
}

# 启动 frida-server
start_frida_server() {
    print_step "7" "启动 frida-server"
    
    # 检查设备连接
    DEVICES=$(adb devices | grep -v "List of devices" | grep -v "^$" | wc -l)
    if [ "$DEVICES" -eq 0 ]; then
        print_warning "未检测到 Android 设备，跳过启动"
        return 0
    fi
    
    # 检查是否已在运行
    RUNNING_PID=$(adb shell ps | grep frida-server | awk '{print $2}' | head -n1)
    if [ ! -z "$RUNNING_PID" ]; then
        print_info "frida-server 已在运行 (PID: $RUNNING_PID)"
        
        read -p "是否重启 frida-server？[y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "正在停止现有的 frida-server..."
            adb shell kill "$RUNNING_PID"
            sleep 2
        else
            print_info "保持现有的 frida-server 运行"
            return 0
        fi
    fi
    
    # 启动 frida-server
    print_info "正在启动 frida-server..."
    adb shell "/data/local/tmp/frida-server &" &
    
    # 等待启动
    sleep 3
    
    # 检查是否启动成功
    NEW_PID=$(adb shell ps | grep frida-server | awk '{print $2}' | head -n1)
    if [ ! -z "$NEW_PID" ]; then
        print_success "frida-server 启动成功 (PID: $NEW_PID)"
    else
        print_error "frida-server 启动失败"
        print_info "请检查设备是否有 root 权限"
        return 1
    fi
}

# 验证环境
verify_environment() {
    print_step "8" "验证环境"
    
    # 检查设备连接
    DEVICES=$(adb devices | grep -v "List of devices" | grep -v "^$" | wc -l)
    if [ "$DEVICES" -eq 0 ]; then
        print_warning "未检测到 Android 设备，跳过验证"
        return 0
    fi
    
    # 测试 Frida 连接
    print_info "测试 Frida 连接..."
    if timeout 10 frida-ps -U > /dev/null 2>&1; then
        print_success "Frida 连接测试成功"
        
        # 显示进程列表
        print_info "设备上运行的进程 (前10个):"
        frida-ps -U | head -n 11
    else
        print_error "Frida 连接测试失败"
        print_info "可能的原因:"
        print_info "  1. frida-server 未正常启动"
        print_info "  2. 设备没有 root 权限"
        print_info "  3. 防火墙阻止了连接"
        return 1
    fi
}

# 创建项目文件
create_project_files() {
    print_step "9" "创建项目文件"
    
    # 检查是否已存在
    if [ -f "privacy_monitor_ultimate.js" ]; then
        print_info "监控脚本已存在，跳过创建"
    else
        print_info "项目文件需要单独创建"
        print_info "请参考项目文档创建监控脚本"
    fi
    
    # 创建启动脚本模板
    if [ ! -f "start_monitor.sh" ]; then
        print_info "创建启动脚本模板..."
        cat > start_monitor.sh << 'EOF'
#!/bin/bash

# Frida Android 隐私监控启动脚本
echo "🚀 启动Frida隐私监控..."
echo "目标应用: com.frog.educate"

# 检查环境
if ! command -v frida &> /dev/null; then
    echo "❌ 错误: 未找到Frida"
    exit 1
fi

if ! frida-ps -U &> /dev/null; then
    echo "❌ 错误: 无法连接到设备"
    exit 1
fi

if [ ! -f "privacy_monitor_ultimate.js" ]; then
    echo "❌ 错误: 未找到监控脚本"
    exit 1
fi

echo "✅ 环境检查通过，开始监控..."
frida -U -l privacy_monitor_ultimate.js -f com.frog.educate
EOF
        chmod +x start_monitor.sh
        print_success "启动脚本模板创建成功"
    fi
}

# 显示总结
show_summary() {
    echo -e "${BOLD}${BLUE}"
    echo "=================================================================="
    echo "📊 环境搭建总结"
    echo "=================================================================="
    echo -e "${NC}"
    
    if [ $ERRORS_FOUND -eq 0 ]; then
        print_success "环境搭建完成！"
        echo -e "${GREEN}"
        echo "✅ 所有组件安装成功"
        echo "✅ frida-server 已部署到设备"
        echo "✅ Frida 连接测试通过"
        echo -e "${NC}"
        
        echo -e "${BOLD}${CYAN}🚀 下一步操作:${NC}"
        echo "1. 确保目标应用已安装: adb install your_app.apk"
        echo "2. 创建监控脚本: privacy_monitor_ultimate.js"
        echo "3. 开始监控: ./start_monitor.sh"
        
    else
        print_warning "环境搭建完成，但发现 $ERRORS_FOUND 个问题"
        echo -e "${YELLOW}"
        echo "⚠️  请检查上述错误信息"
        echo "⚠️  部分功能可能无法正常使用"
        echo -e "${NC}"
        
        echo -e "${BOLD}${CYAN}🔧 故障排除:${NC}"
        echo "1. 查看详细日志: cat $SETUP_LOG"
        echo "2. 检查设备连接: adb devices"
        echo "3. 检查 frida-server: adb shell ps | grep frida"
    fi
    
    echo -e "${BOLD}${BLUE}"
    echo "=================================================================="
    echo "📁 生成的文件:"
    echo "=================================================================="
    echo -e "${NC}"
    
    ls -la frida-server-android-* start_monitor.sh $SETUP_LOG 2>/dev/null || true
    
    echo -e "${BOLD}${PURPLE}"
    echo "=================================================================="
    echo "📖 更多信息请查看: $SETUP_LOG"
    echo "=================================================================="
    echo -e "${NC}"
}

# 主函数
main() {
    # 初始化日志
    echo "Frida 环境搭建开始 - $(date)" > "$SETUP_LOG"
    
    print_header
    
    # 执行各个步骤
    check_os || exit 1
    check_required_tools || exit 1
    check_android_environment
    install_frida_tools || exit 1
    download_frida_server || exit 1
    deploy_frida_server
    start_frida_server
    verify_environment
    create_project_files
    
    # 显示总结
    show_summary
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 