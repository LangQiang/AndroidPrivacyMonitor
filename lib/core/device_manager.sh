#!/bin/bash

# Frida监控工具 - 设备管理模块
# 负责多设备检查、Root权限验证、设备选择和基础信息检测
# 作者: GodQ

# 全局变量声明
declare -a DEVICE_RESULTS=()
declare -a ROOTED_DEVICES=()
SELECTED_DEVICE=""
DEVICE_ID=""
DEVICE_STATUS=""
HAS_ROOT=""
IS_EMULATOR=""
DEVICE_ARCH=""

# 单设备Root权限检查函数
check_device_root() {
    local device_id="$1"
    local device_status="$2"
    
    log_info "🔍 检查设备: ${device_id}"
    
    # 检查设备状态
    if [ "$device_status" != "device" ]; then
        log_error "   ❌ 设备状态异常: ${device_status}"
        return 1
    fi
    
    # 检查是否为模拟器
    local is_emulator="false"
    if echo "$device_id" | grep -q "emulator"; then
        is_emulator="true"
        log_success "   📱 模拟器设备"
    else
        log_info "   📱 物理设备"
    fi
    
    # 先尝试获取Root权限
    log_info "   🔧 尝试获取Root权限..."
    adb -s "$device_id" root >/dev/null 2>&1
    sleep 1
    
    # 检查Root权限
    local root_check=""
    local whoami_check=""
    local has_root="false"
    
    # 使用异常处理，避免命令失败导致脚本退出
    root_check=$(adb -s "$device_id" shell "id" 2>/dev/null | grep "uid=0(root)" || true)
    if [ -n "$root_check" ]; then
        log_success "   🔓 设备已获得Root权限"
        has_root="true"
    else
        # 备用检测方法：检查whoami命令
        whoami_check=$(adb -s "$device_id" shell "whoami" 2>/dev/null || true)
        if [ "$whoami_check" = "root" ]; then
            log_success "   🔓 设备已获得Root权限"
            has_root="true"
        else
            log_error "   ❌ 设备未获得Root权限"
            has_root="false"
        fi
    fi
    
    # 返回结果：device_id|device_status|is_emulator|has_root
    echo "${device_id}|${device_status}|${is_emulator}|${has_root}"
    return 0
}

# 检测所有设备的类型和Root状态
check_all_devices() {
    log_step "3" "9" "检测所有设备的类型和权限..."
    
    # 重置全局变量
    DEVICE_RESULTS=()
    ROOTED_DEVICES=()
    SELECTED_DEVICE=""
    
    # 直接处理设备列表，避免文件和管道
    local device_count=0
    log_info "开始逐个检查设备..."
    
    # 获取设备列表并存储在变量中
    local device_list=$(adb devices | grep -v "List of devices" | grep -v "^$")
    local total_devices=$(echo "$device_list" | wc -l)
    
    log_info "发现 ${total_devices} 个设备需要检查"
    
    # 使用for循环处理每一行，避免stdin问题
    for line_num in $(seq 1 "$total_devices"); do
        local device_line=$(echo "$device_list" | sed -n "${line_num}p")
        
        if [ -n "$device_line" ]; then
            device_count=$((device_count + 1))
            local device_id=$(echo "$device_line" | awk '{print $1}')
            local device_status=$(echo "$device_line" | awk '{print $2}')
            
            log_info "[${device_count}/${total_devices}] 检查设备: ${device_id}"
            
            # 直接调用函数检查root权限
            check_device_root "$device_id" "$device_status"
            local device_result="$device_id|$device_status|false|false"
            
            # 重新获取检查结果
            local is_emulator="false"
            if echo "$device_id" | grep -q "emulator"; then
                is_emulator="true"
            fi
            
            # 检查root权限
            local root_check=$(adb -s "$device_id" shell "id" 2>/dev/null | grep "uid=0(root)" || true)
            local whoami_check=$(adb -s "$device_id" shell "whoami" 2>/dev/null || true)
            
            local has_root="false"
            if [ -n "$root_check" ] || [ "$whoami_check" = "root" ]; then
                has_root="true"
                log_success "   ✅ 设备有Root权限"
            else
                has_root="false"
                log_error "   ❌ 设备无Root权限"
            fi
            
            device_result="$device_id|$device_status|$is_emulator|$has_root"
            DEVICE_RESULTS+=("$device_result")
            
            # 检查是否有root权限
            if [ "$has_root" = "true" ]; then
                ROOTED_DEVICES+=("$device_result")
            fi
            
            log_info "   📝 设备检查完成"
        fi
    done
}

# 显示设备检查结果总览
show_device_summary() {
    log_info "📊 设备检查结果总览:"
    for result in "${DEVICE_RESULTS[@]}"; do
        local device_id=$(echo "$result" | cut -d'|' -f1)
        local device_status=$(echo "$result" | cut -d'|' -f2)
        local is_emulator=$(echo "$result" | cut -d'|' -f3)
        local has_root=$(echo "$result" | cut -d'|' -f4)
        
        local device_type="物理设备"
        if [ "$is_emulator" = "true" ]; then
            device_type="模拟器"
        fi
        
        local root_status="❌ 无Root"
        if [ "$has_root" = "true" ]; then
            root_status="✅ 有Root"
        fi
        
        log_info "   ${device_id} | ${device_type} | ${root_status}"
    done
}

# 选择合适的设备
select_target_device() {
    # 根据rooted设备数量决定后续行为
    if [ ${#ROOTED_DEVICES[@]} -eq 0 ]; then
        log_error "❌ 错误: 没有检测到有Root权限的设备"
        log_warn "💡 Frida监控需要Root权限，无法继续"
        log_warn "🔧 请使用root模拟器或root物理设备"
        exit 1
    elif [ ${#ROOTED_DEVICES[@]} -eq 1 ]; then
        # 只有一个rooted设备，自动选择
        local selected_result="${ROOTED_DEVICES[0]}"
        SELECTED_DEVICE=$(echo "$selected_result" | cut -d'|' -f1)
        local is_emulator=$(echo "$selected_result" | cut -d'|' -f3)
        
        log_success "✅ 自动选择唯一的Root设备: ${SELECTED_DEVICE}"
        
        if [ "$is_emulator" = "true" ]; then
            IS_EMULATOR="true"
            log_success "📱 使用模拟器设备"
        else
            IS_EMULATOR="false"
            log_info "📱 使用物理设备"
        fi
    else
        # 多个rooted设备，优先选择模拟器
        log_warn "⚠️ 检测到多个Root设备，正在自动选择..."
        
        # 优先选择模拟器设备
        local emulator_found="false"
        for result in "${ROOTED_DEVICES[@]}"; do
            local device_id=$(echo "$result" | cut -d'|' -f1)
            local is_emulator=$(echo "$result" | cut -d'|' -f3)
            
            if [ "$is_emulator" = "true" ]; then
                SELECTED_DEVICE="$device_id"
                IS_EMULATOR="true"
                emulator_found="true"
                log_success "✅ 优先选择Root模拟器: ${SELECTED_DEVICE}"
                break
            fi
        done
        
        # 如果没有模拟器，选择第一个物理设备
        if [ "$emulator_found" = "false" ]; then
            local selected_result="${ROOTED_DEVICES[0]}"
            SELECTED_DEVICE=$(echo "$selected_result" | cut -d'|' -f1)
            IS_EMULATOR="false"
            log_info "✅ 选择Root物理设备: ${SELECTED_DEVICE}"
        fi
    fi
    
    # 设置全局变量供后续使用
    DEVICE_ID="$SELECTED_DEVICE"
    DEVICE_STATUS="device"
    HAS_ROOT="true"
    
    log_success "🎯 最终选择设备: ${DEVICE_ID}"
}

# 检测设备架构
detect_device_architecture() {
    log_step "4" "9" "检测设备架构..."
    
    DEVICE_ARCH=$(adb -s "$DEVICE_ID" shell getprop ro.product.cpu.abi 2>/dev/null)
    if [ -z "$DEVICE_ARCH" ]; then
        log_error "❌ 无法获取设备架构信息"
        exit 1
    fi
    
    log_success "✅ 设备架构: ${DEVICE_ARCH}"
    
    # 验证架构支持
    case "$DEVICE_ARCH" in
        "arm64-v8a"|"arm64")
            log_info "📋 将使用ARM64版本的frida-server"
            ;;
        "armeabi-v7a"|"armeabi"|"arm")
            log_info "📋 将使用ARM版本的frida-server"
            ;;
        "x86_64")
            log_info "📋 将使用x86_64版本的frida-server"
            ;;
        "x86")
            log_info "📋 将使用x86版本的frida-server"
            ;;
        *)
            log_error "❌ 不支持的设备架构: ${DEVICE_ARCH}"
            log_warn "💡 支持的架构: arm64-v8a, armeabi-v7a, x86_64, x86"
            exit 1
            ;;
    esac
}

# 检查磁盘空间
check_disk_space() {
    log_step "5" "9" "检查磁盘空间..."
    
    # 检查本地磁盘空间
    if command -v df &> /dev/null; then
        local local_space=$(df -h . | awk 'NR==2 {print $4}' | sed 's/[^0-9.]//g')
        if [ -n "$local_space" ]; then
            # 简单检查是否有足够空间
            if (( $(echo "$local_space > 0.1" | bc -l 2>/dev/null || echo "1") )); then
                log_success "✅ 本地磁盘空间充足"
            else
                log_warn "⚠️ 本地磁盘空间可能不足"
            fi
        else
            log_info "📋 无法精确检测本地磁盘空间，继续执行"
        fi
    else
        log_info "📋 无法检测磁盘空间，继续执行"
    fi
    
    # 检查设备存储空间
    local device_space=$(adb -s "$DEVICE_ID" shell df /data/local/tmp 2>/dev/null | tail -n 1 | awk '{print $4}')
    if [ -n "$device_space" ] && [ "$device_space" -gt 51200 ]; then  # 50MB = 51200KB
        log_success "✅ 设备存储空间充足"
    else
        log_warn "⚠️ 设备/data/local/tmp空间可能不足"
    fi
}

# 获取设备信息的辅助函数
get_selected_device_id() {
    echo "$DEVICE_ID"
}

get_device_architecture() {
    echo "$DEVICE_ARCH"
}

get_is_emulator() {
    echo "$IS_EMULATOR"
}

# 完整的设备管理流程
manage_devices() {
    check_all_devices
    show_device_summary
    select_target_device
    detect_device_architecture
    check_disk_space
} 