#!/bin/bash

# Frida监控工具 - Frida服务管理模块
# 负责frida-server的检查、部署、启动和连接验证
# 作者: GodQ

# 全局变量声明
FRIDA_SERVER_RUNNING=false
FRIDA_CONNECTION_OK=false
AUTO_DEPLOY_NEEDED=false
declare -a DEPLOY_ACTIONS=()

# 根据设备架构确定frida-server架构
get_frida_architecture() {
    local device_arch="$1"
    case "$device_arch" in
        "arm64-v8a"|"arm64")
            echo "arm64"
            ;;
        "armeabi-v7a"|"armeabi"|"arm")
            echo "arm"
            ;;
        "x86_64")
            echo "x86_64"
            ;;
        "x86")
            echo "x86"
            ;;
        *)
            log_error "❌ 不支持的设备架构: ${device_arch}"
            return 1
            ;;
    esac
}

# 检查frida-server状态
check_frida_server_status() {
    log_step "6" "9" "检查frida-server状态..."
    
    # 重置全局变量
    FRIDA_SERVER_RUNNING=false
    AUTO_DEPLOY_NEEDED=false
    DEPLOY_ACTIONS=()
    
    # 检查frida-server是否在运行
    local frida_pid=$(adb -s "$DEVICE_ID" shell ps | grep frida-server | awk '{print $2}' | head -n 1)
    if [ -n "$frida_pid" ]; then
        log_success "✅ frida-server正在运行 PID: ${frida_pid}"
        FRIDA_SERVER_RUNNING=true
    else
        log_warn "⚠️ frida-server未运行"
        FRIDA_SERVER_RUNNING=false
        
        # 检查frida-server是否已部署
        if adb -s "$DEVICE_ID" shell ls "/data/local/tmp/frida-server" &> /dev/null; then
            log_info "📋 frida-server已部署，但未运行"
            DEPLOY_ACTIONS+=("启动frida-server")
            AUTO_DEPLOY_NEEDED=true
        else
            log_warn "📋 frida-server未部署"
            DEPLOY_ACTIONS+=("下载frida-server" "部署frida-server" "启动frida-server")
            AUTO_DEPLOY_NEEDED=true
        fi
    fi
}

# 检查Frida连接
check_frida_connection() {
    log_step "7" "9" "检查Frida连接..."
    
    if frida-ps -D "$DEVICE_ID" &> /dev/null; then
        local process_count=$(frida-ps -D "$DEVICE_ID" | wc -l)
        log_success "✅ Frida连接正常，检测到 ${process_count} 个进程"
        FRIDA_CONNECTION_OK=true
    else
        log_warn "⚠️ Frida无法连接到设备"
        FRIDA_CONNECTION_OK=false
        if [ "$FRIDA_SERVER_RUNNING" = false ]; then
            log_info "💡 这是因为frida-server未运行，将自动处理"
        else
            log_error "❌ frida-server运行中但连接失败，可能存在其他问题"
        fi
    fi
}

# 自动部署frida-server
auto_deploy_frida_server() {
    log_info "🔧 [自动部署] 开始部署frida-server..."
    
    # 获取Frida版本
    local frida_version=$(frida --version 2>/dev/null)
    if [ -z "$frida_version" ]; then
        log_error "❌ 无法获取Frida版本"
        return 1
    fi
    
    log_info "📋 Frida版本: ${frida_version}"
    log_info "📋 目标架构: ${DEVICE_ARCH}"
    
    # 根据设备架构确定frida-server文件名
    local frida_arch=$(get_frida_architecture "$DEVICE_ARCH")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local frida_server_file="build/frida-server-android-${frida_arch}"
    
    # 检查本地是否已有frida-server文件
    if [ -f "$frida_server_file" ]; then
        log_success "✅ 发现本地frida-server文件: ${frida_server_file}"
    else
        log_warn "📥 需要下载frida-server-${frida_version}-android-${frida_arch}..."
        
        # 确保build目录存在
        mkdir -p build
        
        # 只在需要下载时检测网络
        if ! check_network_for_download; then
            return 1
        fi
        
        # 下载frida-server
        local download_url="https://github.com/frida/frida/releases/download/${frida_version}/frida-server-${frida_version}-android-${frida_arch}.xz"
        
        if command -v curl &> /dev/null; then
            curl -L -o "frida-server-${frida_version}-android-${frida_arch}.xz" "$download_url"
        elif command -v wget &> /dev/null; then
            wget -O "frida-server-${frida_version}-android-${frida_arch}.xz" "$download_url"
        else
            log_error "❌ 未找到curl或wget下载工具"
            return 1
        fi
        
        if [ $? -ne 0 ]; then
            log_error "❌ frida-server下载失败"
            if [ -z "$PROXY_URL" ]; then
                log_warn "💡 可能是连接VPN但没有配置代理，请在 ${CONFIG_FILE} 中设置 network.proxyUrl"
            else
                log_warn "💡 请检查代理设置是否正确: ${PROXY_URL}"
            fi
            return 1
        fi
        
        # 解压文件
        log_warn "📦 解压frida-server..."
        if command -v unxz &> /dev/null; then
            unxz "frida-server-${frida_version}-android-${frida_arch}.xz"
            mv "frida-server-${frida_version}-android-${frida_arch}" "$frida_server_file"
        else
            log_error "❌ 未找到unxz解压工具"
            return 1
        fi
        
        log_success "✅ frida-server下载完成"
    fi
    
    # 推送到设备
    log_warn "📤 推送frida-server到设备..."
    if adb -s "$DEVICE_ID" push "$frida_server_file" "/data/local/tmp/frida-server"; then
        log_success "✅ frida-server推送成功"
    else
        log_error "❌ frida-server推送失败"
        return 1
    fi
    
    # 设置执行权限
    log_warn "🔐 设置执行权限..."
    if adb -s "$DEVICE_ID" shell chmod 755 "/data/local/tmp/frida-server"; then
        log_success "✅ 权限设置成功"
    else
        log_error "❌ 权限设置失败"
        return 1
    fi
    
    # 启动frida-server
    log_warn "🚀 启动frida-server..."
    adb -s "$DEVICE_ID" shell "/data/local/tmp/frida-server &" &
    
    # 等待启动
    sleep 3
    
    # 验证启动
    local frida_pid=$(adb -s "$DEVICE_ID" shell ps | grep frida-server | awk '{print $2}' | head -n 1)
    if [ -n "$frida_pid" ]; then
        log_success "✅ frida-server启动成功 PID: ${frida_pid}"
        FRIDA_SERVER_RUNNING=true
        return 0
    else
        log_error "❌ frida-server启动失败"
        return 1
    fi
}

# 处理智能自动部署
handle_auto_deployment() {
    if [ "$AUTO_DEPLOY_NEEDED" = true ]; then
        log_info "🔧 [智能部署] 检测到环境不完整，但符合自动部署条件"
        log_info "📋 需要执行的操作:"
        for action in "${DEPLOY_ACTIONS[@]}"; do
            log_warn "   • ${action}"
        done
        
        log_info "💡 由于设备满足基本要求（Root权限✅），将自动完成部署"
        read -p "按 Enter 键开始自动部署，或按 Ctrl+C 取消..." -r
        
        # 执行自动部署
        if auto_deploy_frida_server; then
            log_success "🎉 自动部署完成！"
            
            # 重新检查Frida连接
            log_info "🔍 重新检查Frida连接..."
            if frida-ps -D "$DEVICE_ID" &> /dev/null; then
                local process_count=$(frida-ps -D "$DEVICE_ID" | wc -l)
                log_success "✅ Frida连接正常，检测到 ${process_count} 个进程"
                FRIDA_CONNECTION_OK=true
            else
                log_error "❌ 自动部署后Frida连接仍然失败"
                exit 1
            fi
        else
            log_error "❌ 自动部署失败"
            log_warn "💡 请手动运行: ./docs/setup_frida_environment.sh"
            exit 1
        fi
    fi
}

# 获取frida-server状态
get_frida_server_running() {
    echo "$FRIDA_SERVER_RUNNING"
}

# 获取Frida连接状态
get_frida_connection_ok() {
    echo "$FRIDA_CONNECTION_OK"
}

# 获取自动部署状态
get_auto_deploy_needed() {
    echo "$AUTO_DEPLOY_NEEDED"
}

# 完整的Frida服务管理流程
manage_frida_service() {
    check_frida_server_status
    check_frida_connection
    handle_auto_deployment
} 