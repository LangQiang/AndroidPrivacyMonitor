#!/bin/bash

# Frida监控工具 - 应用管理模块
# 负责目标应用的检查、版本信息获取、安装状态管理
# 作者: GodQ

# 全局变量声明
APP_INSTALLED=false
APP_VERSION=""
APP_VERSION_CODE=""

# 检查应用是否已安装
check_app_installation() {
    local package_name="$1"
    if adb -s "$DEVICE_ID" shell pm list packages | grep -q "$package_name"; then
        return 0  # 已安装
    else
        return 1  # 未安装
    fi
}

# 获取应用版本信息
get_app_version_info() {
    local package_name="$1"
    
    # 获取应用版本名称
    APP_VERSION=$(adb -s "$DEVICE_ID" shell dumpsys package "$package_name" | grep "versionName" | head -n 1 | awk -F'=' '{print $2}' | tr -d ' ')
    
    # 获取应用版本代码
    APP_VERSION_CODE=$(adb -s "$DEVICE_ID" shell dumpsys package "$package_name" | grep "versionCode" | head -n 1 | awk -F'=' '{print $2}' | awk '{print $1}')
    
    if [ -n "$APP_VERSION" ] && [ -n "$APP_VERSION_CODE" ]; then
        log_info "📦 应用版本: ${APP_VERSION} 版本号${APP_VERSION_CODE}"
        return 0
    else
        log_warn "⚠️ 无法获取应用版本信息"
        return 1
    fi
}

# 检查应用运行状态并停止
check_and_stop_app() {
    local package_name="$1"
    
    # 检查应用是否正在运行
    if adb -s "$DEVICE_ID" shell ps | grep -q "$package_name"; then
        log_warn "⚠️ 应用正在运行，将强制停止后重新启动"
        adb -s "$DEVICE_ID" shell am force-stop "$package_name"
        sleep 1
        return 0
    else
        log_info "📱 应用未运行"
        return 1
    fi
}

# 查找相关应用
find_related_apps() {
    local package_name="$1"
    
    # 从包名中提取关键词进行搜索
    local keywords=""
    if echo "$package_name" | grep -q "frog"; then
        keywords="frog"
    elif echo "$package_name" | grep -q "educate"; then
        keywords="educate"
    else
        # 提取包名的主要部分作为关键词
        keywords=$(echo "$package_name" | cut -d'.' -f2-3 | tr '.' '|')
    fi
    
    if [ -n "$keywords" ]; then
        log_info "🔍 查找相关应用..."
        local related_apps=$(adb -s "$DEVICE_ID" shell pm list packages | grep -E "($keywords)")
        if [ -n "$related_apps" ]; then
            log_info "📱 发现相关应用:"
            echo "$related_apps" | while read app; do
                log_info "   • ${app#package:}"
            done
            log_warn "💡 如需监控其他应用，请修改配置文件中的包名"
            return 0
        else
            log_info "📱 未发现相关应用"
            return 1
        fi
    else
        return 1
    fi
}

# 显示安装建议
show_installation_suggestions() {
    local package_name="$1"
    
    log_info "🔧 安装建议:"
    log_warn "   1. 通过应用商店安装 ${package_name}"
    log_warn "   2. 或使用: adb install /path/to/app.apk"
    log_warn "   3. 安装完成后重新运行此脚本"
}

# 等待用户安装应用
wait_for_app_installation() {
    local package_name="$1"
    
    echo ""
    read -p "应用未安装，按 Enter 键退出去安装应用，或输入 'wait' 等待应用安装..." -r user_choice
    if [ "$user_choice" = "wait" ] || [ "$user_choice" = "WAIT" ]; then
        log_warn "⏳ 等待应用安装，请在另一个终端安装应用..."
        log_warn "💡 安装完成后按任意键继续"
        read -p "应用安装完成后按 Enter 键继续..." -r
        
        # 重新检查应用
        if check_app_installation "$package_name"; then
            log_success "✅ 检测到应用已安装"
            APP_INSTALLED=true
            return 0
        else
            log_error "❌ 仍未检测到应用安装"
            exit 1
        fi
    else
        exit 1
    fi
}

# 完整的目标应用检查流程
check_target_application() {
    log_step "8" "9" "检查目标应用..."
    
    local package_name="$TARGET_PACKAGE"
    
    # 检查应用是否已安装
    if check_app_installation "$package_name"; then
        log_success "✅ 目标应用已安装: ${package_name}"
        
        # 获取应用版本信息
        get_app_version_info "$package_name"
        
        # 检查应用运行状态并停止
        check_and_stop_app "$package_name"
        
        APP_INSTALLED=true
    else
        log_error "❌ 目标应用未安装: ${package_name}"
        log_warn "💡 请先安装目标应用后再运行监控"
        
        # 查找相关应用
        find_related_apps "$package_name"
        
        # 显示安装建议
        show_installation_suggestions "$package_name"
        
        APP_INSTALLED=false
        
        # 等待用户安装
        wait_for_app_installation "$package_name"
    fi
}

# 检查监控脚本和配置文件
check_scripts_and_config() {
    log_step "9" "9" "检查配置文件和脚本模板..."
    
    # 检查脚本文件
    if [ -f "lib/privacy_monitor_template.js" ]; then
        local script_size=$(wc -l < lib/privacy_monitor_template.js)
        log_success "✅ 脚本模板已就绪 ${script_size} 行代码（可选）"
    fi
    
    # 检查配置文件
    if [ -f "$CONFIG_FILE" ]; then
        local config_size=$(wc -l < "$CONFIG_FILE")
        local api_count
        if command -v jq &> /dev/null; then
            api_count=$(jq '.apis | length' "$CONFIG_FILE" 2>/dev/null || echo "14")
        else
            api_count=$(grep -c '"description"' "$CONFIG_FILE" 2>/dev/null || echo "14")
        fi
        log_success "✅ 统一配置文件已就绪 ${config_size} 行，${api_count} 个API配置"
    else
        log_error "❌ 错误: 未找到配置文件 $CONFIG_FILE"
        log_warn "💡 无法动态生成监控脚本"
        exit 1
    fi
}

# 获取应用安装状态
get_app_installed() {
    echo "$APP_INSTALLED"
}

# 获取应用版本信息
get_app_version() {
    echo "$APP_VERSION"
}

# 获取应用版本代码
get_app_version_code() {
    echo "$APP_VERSION_CODE"
}

# 验证应用是否可以被监控
validate_app_for_monitoring() {
    local package_name="$1"
    
    # 检查应用是否为系统应用
    if adb -s "$DEVICE_ID" shell pm list packages -s | grep -q "$package_name"; then
        log_warn "⚠️ 目标应用是系统应用，可能需要特殊权限"
        return 1
    fi
    
    # 检查应用是否有调试权限
    local app_flags=$(adb -s "$DEVICE_ID" shell dumpsys package "$package_name" | grep "flags=" | head -n 1)
    if echo "$app_flags" | grep -q "DEBUGGABLE"; then
        log_info "🔧 应用支持调试模式"
    else
        log_warn "⚠️ 应用未开启调试模式，监控可能受限"
    fi
    
    return 0
}

# 完整的应用管理流程
manage_application() {
    check_target_application
    check_scripts_and_config
    
    # 如果应用已安装，进行额外验证
    if [ "$APP_INSTALLED" = "true" ]; then
        validate_app_for_monitoring "$TARGET_PACKAGE"
    fi
} 