#!/bin/bash

# Frida监控工具 - 环境检查模块
# 负责检查Frida、ADB工具和网络连接
# 作者: GodQ

# 检查Frida工具是否安装
check_frida_tools() {
    log_step "1" "9" "检查Frida工具..."
    
    if ! command -v frida &> /dev/null; then
        log_error "❌ 错误: 未找到Frida工具"
        log_warn "💡 请先安装: pip install frida-tools"
        exit 1
    fi
    
    FRIDA_VERSION=$(frida --version 2>/dev/null)
    log_success "✅ Frida工具已安装: ${FRIDA_VERSION}"
}

# 检查ADB工具是否安装
check_adb_tools() {
    log_step "2" "9" "检查ADB连接..."
    
    if ! command -v adb &> /dev/null; then
        log_error "❌ 错误: 未找到ADB工具"
        log_warn "💡 请安装Android SDK或platform-tools"
        exit 1
    fi
    
    # 检查设备连接
    DEVICES=$(adb devices | grep -v "List of devices" | grep -v "^$" | wc -l)
    if [ "$DEVICES" -eq 0 ]; then
        log_error "❌ 错误: 未检测到连接的设备"
        log_warn "💡 请确保:"
        log_warn "   1. 模拟器已启动或设备已连接"
        log_warn "   2. USB调试已开启"
        log_warn "   3. 运行 'adb devices' 检查设备状态"
        exit 1
    fi
    
    log_success "✅ 检测到 ${DEVICES} 个连接的设备"
}

# 网络连接检查（按需调用）
check_network_for_download() {
    log_info "🔍 检查网络连接（下载需要）..."
    
    # 环境变量已设置代理，无需额外参数
    if [ -n "$PROXY_URL" ]; then
        log_info "🌐 使用代理: $PROXY_URL（已设置环境变量）"
    fi
    
    if command -v curl &> /dev/null; then
        if curl -I --connect-timeout 10 --max-time 15 https://github.com &> /dev/null; then
            log_success "✅ 网络连接正常，可访问GitHub"
            return 0
        else
            log_error "❌ 无法访问GitHub，frida-server下载失败"
            if [ -z "$PROXY_URL" ]; then
                log_warn "💡 可能是连接VPN但没有配置代理，请在 ${CONFIG_FILE} 中设置 network.proxyUrl"
            else
                log_warn "💡 请检查代理设置是否正确: ${PROXY_URL}"
            fi
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if wget --spider --timeout=10 --tries=1 https://github.com &> /dev/null; then
            log_success "✅ 网络连接正常，可访问GitHub"
            return 0
        else
            log_error "❌ 无法访问GitHub，frida-server下载失败"
            if [ -z "$PROXY_URL" ]; then
                log_warn "💡 可能是连接VPN但没有配置代理，请在 ${CONFIG_FILE} 中设置 network.proxyUrl"
            else
                log_warn "💡 请检查代理设置是否正确: ${PROXY_URL}"
            fi
            return 1
        fi
    else
        log_error "❌ 未找到curl或wget工具"
        log_warn "💡 请安装curl或wget用于下载frida-server"
        return 1
    fi
}

# 获取Frida版本
get_frida_version() {
    echo "$FRIDA_VERSION"
}

# 检查下载工具是否可用
check_download_tools() {
    if command -v curl &> /dev/null || command -v wget &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 检查解压工具是否可用
check_extract_tools() {
    if command -v unxz &> /dev/null; then
        return 0
    else
        return 1
    fi
} 