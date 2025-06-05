#!/bin/bash

# Frida监控工具 - 监控启动管理模块
# 负责监控启动、日志管理、监控结束处理
# 作者: GodQ

# 全局变量声明
LOG_FILE=""
TIMESTAMP=""

# 显示环境检查总结
show_environment_summary() {
    log_newline
    log_success "🎉 环境检查完成! 所有条件均满足"
    log_info "================================="
    log_success "✅ Frida工具: $(frida --version 2>/dev/null)"
    log_success "✅ 设备连接: ${DEVICE_ID}"
    
    if [ "$IS_EMULATOR" = "true" ]; then
        log_success "✅ 设备类型: 模拟器"
    else
        log_success "✅ 设备类型: 物理设备"
    fi
    
    log_success "✅ 设备架构: ${DEVICE_ARCH}"
    log_success "✅ Root权限: 已获得"
    log_success "✅ 磁盘空间: 充足"
    log_success "✅ frida-server: 运行中"
    log_success "✅ Frida连接: 正常"
    log_success "✅ 目标应用: ${TARGET_PACKAGE}"
    
    if [ "$(get_app_version)" != "" ]; then
        log_success "✅ 应用版本: $(get_app_version) 版本号$(get_app_version_code)"
    fi
    
    log_success "✅ 监控脚本: privacy_monitor_template.js v1.0 (模板化配置版本)"
    log_success "✅ 配置文件: ${CONFIG_FILE}"
    
    if [ "$(get_auto_deploy_needed)" = "true" ]; then
        echo -e "${MAGENTA}✅ 自动部署: 已完成${NC}"
    fi
    
    log_info "================================="
}

# 生成监控脚本并验证
prepare_monitor_script() {
    if ! generate_monitor_script; then
        log_error "❌ JS文件生成失败，无法继续"
        exit 1
    fi
}

# 显示监控启动提示
show_launch_prompt() {
    log_newline
    log_warn "🚀 即将启动隐私监控..."
    log_warn "💡 提示: 按 Ctrl+C 停止监控"
    log_info "📝 使用生成的监控脚本: build/privacy_monitor_generated.js"
    echo ""
}

# 等待用户确认
wait_for_user_confirmation() {
    read -p "按 Enter 键开始监控，或按 Ctrl+C 取消..." -r
}

# 创建日志目录和文件
setup_logging() {
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    LOG_FILE="${LOG_DIR}/${LOG_PREFIX}_${TIMESTAMP}.txt"
    
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        log_success "📁 创建日志目录: ${LOG_DIR}"
    fi
    
    log_info "📝 日志文件: ${LOG_FILE}"
}

# 启动Frida监控
launch_frida_monitor() {
    log_success "🔥 启动Frida隐私监控..."
    log_warn "💡 所有输出将同时保存到日志文件"
    echo ""
    
    # 使用tee命令同时输出到控制台和文件
    frida -D "$DEVICE_ID" -l build/privacy_monitor_generated.js -f "$TARGET_PACKAGE" 2>&1 | tee "$LOG_FILE"
}

# 监控结束后的处理
handle_monitor_completion() {
    echo ""
    log_success "🔄 监控已结束"
    log_info "📁 日志文件已保存到: ${LOG_FILE}"
}

# 自动提取堆栈信息
auto_extract_stacks() {
    if [ "$AUTO_EXTRACT_STACKS" = "true" ]; then
        log_newline
        log_info "🔍 自动提取堆栈信息..."
        if [ -f "./lib/extract_stacks.sh" ]; then
            ./lib/extract_stacks.sh "$LOG_FILE"
            log_success "✅ 堆栈信息提取完成"
        else
            log_error "❌ 未找到堆栈提取脚本 lib/extract_stacks.sh"
            log_warn "💡 您可以手动运行: ./lib/extract_stacks.sh \"${LOG_FILE}\""
        fi
    fi
}

# 获取日志文件路径
get_log_file() {
    echo "$LOG_FILE"
}

# 获取时间戳
get_timestamp() {
    echo "$TIMESTAMP"
}

# 验证监控环境
validate_monitor_environment() {
    # 检查必要的文件是否存在
    if [ ! -f "build/privacy_monitor_generated.js" ]; then
        log_error "❌ 监控脚本文件不存在: build/privacy_monitor_generated.js"
        return 1
    fi
    
    # 检查设备连接
    if [ -z "$DEVICE_ID" ]; then
        log_error "❌ 设备ID未设置"
        return 1
    fi
    
    # 检查目标应用包名
    if [ -z "$TARGET_PACKAGE" ]; then
        log_error "❌ 目标应用包名未设置"
        return 1
    fi
    
    # 检查日志目录配置
    if [ -z "$LOG_DIR" ] || [ -z "$LOG_PREFIX" ]; then
        log_error "❌ 日志配置未正确设置"
        return 1
    fi
    
    return 0
}

# 清理临时文件
cleanup_temp_files() {
    # 如果需要清理临时文件，在这里添加逻辑
    # 目前暂不需要清理
    :
}

# 显示监控统计信息
show_monitor_statistics() {
    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        local file_size=$(wc -c < "$LOG_FILE" 2>/dev/null || echo "0")
        local line_count=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
        
        if [ "$file_size" -gt 0 ]; then
            log_info "📊 监控统计: 日志文件 ${line_count} 行，大小 ${file_size} 字节"
        fi
    fi
}

# 完整的监控启动流程
launch_monitor() {
    # 1. 显示环境总结
    show_environment_summary
    
    # 2. 生成监控脚本
    prepare_monitor_script
    
    # 3. 显示启动提示
    show_launch_prompt
    
    # 4. 等待用户确认
    wait_for_user_confirmation
    
    # 5. 验证监控环境
    if ! validate_monitor_environment; then
        exit 1
    fi
    
    # 6. 设置日志
    setup_logging
    
    # 7. 启动监控
    launch_frida_monitor
    
    # 8. 监控结束处理
    handle_monitor_completion
    
    # 9. 显示统计信息
    show_monitor_statistics
    
    # 10. 自动提取堆栈
    auto_extract_stacks
    
    # 11. 清理临时文件
    cleanup_temp_files
} 