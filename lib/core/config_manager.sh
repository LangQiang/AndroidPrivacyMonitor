#!/bin/bash

# Frida监控工具 - 配置管理模块
# 提供统一的配置文件读取和管理功能
# 作者: GodQ

# 配置文件路径
CONFIG_FILE="frida_config.json"

# 默认配置
DEFAULT_LOG_DIR="./build/logs"
DEFAULT_LOG_PREFIX="privacy_log"
DEFAULT_AUTO_EXTRACT="true"

# 项目环境初始化
initialize_project() {
    # 1. 智能路径检测
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    
    # 2. 切换到项目根目录
    cd "$project_root" || {
        echo "❌ 错误: 无法切换到项目根目录: $project_root"
        exit 1
    }
    
    # 3. 设置全局变量（供其他模块使用）
    export SCRIPT_DIR="$script_dir"
    export PROJECT_ROOT="$project_root"
    
    # 4. 输出路径信息
    log_info "🔍 智能路径检测..."
    log_info "📂 脚本位置: $SCRIPT_DIR"
    log_info "📂 项目根目录: $PROJECT_ROOT"
    log_success "✅ 工作目录已设置为: $(pwd)"
    log_newline
    
    # 5. 加载配置
    load_config
    
    # 6. 设置代理环境变量（如果配置了代理）
    if [ -n "$PROXY_URL" ]; then
        echo "🌐 设置shell代理环境变量: ${PROXY_URL}"
        export http_proxy="$PROXY_URL"
        export https_proxy="$PROXY_URL"
        export HTTP_PROXY="$PROXY_URL"
        export HTTPS_PROXY="$PROXY_URL"
        echo -e "${GREEN}✅ 代理环境变量已设置${NC}"
    fi
    
    # 7. 显示启动信息
    echo "🚀 启动Frida隐私监控 v3.6..."
    echo "🎯 目标应用: ${TARGET_PACKAGE}"
    echo "📋 监控脚本: privacy_monitor_template.js v1.0 (模板化配置版本)"
    echo "📄 配置文件: frida_config.json"
    echo "🔧 优化: 使用JSON统一配置格式"
    echo "📁 日志目录: ${LOG_DIR}"
    if [ -n "$PROXY_URL" ]; then
        echo "🌐 代理地址: ${PROXY_URL}"
    fi
    echo "👨‍💻 作者: GodQ"
    echo "===================================="
    echo ""
}

# 读取JSON配置文件函数
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_info "⚙️ 读取配置文件: $CONFIG_FILE"
        
        # 使用jq解析JSON配置文件
        if command -v jq &> /dev/null; then
            TARGET_PACKAGE=$(jq -r '.monitor.targetPackage // empty' "$CONFIG_FILE")
            LOG_DIR=$(jq -r '.monitor.logDir // "./build/logs"' "$CONFIG_FILE")
            LOG_PREFIX=$(jq -r '.monitor.logPrefix // "privacy_log"' "$CONFIG_FILE")
            AUTO_EXTRACT_STACKS=$(jq -r '.monitor.autoExtractStacks // true' "$CONFIG_FILE")
            PROXY_URL=$(jq -r '.network.proxyUrl // ""' "$CONFIG_FILE")
        else
            echo "⚠️ 未找到jq工具，使用简单解析方法"
            # 简单解析方法（备用）
            TARGET_PACKAGE=$(grep -o '"targetPackage"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
            LOG_DIR=$(grep -o '"logDir"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
            LOG_PREFIX=$(grep -o '"logPrefix"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
            PROXY_URL=$(grep -o '"proxyUrl"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
            AUTO_EXTRACT_STACKS="true"
        fi
        
        echo "✅ JSON配置文件加载完成"
    else
        echo "❌ 错误: 未找到配置文件 $CONFIG_FILE"
        echo "💡 请先创建配置文件，包含必要的 monitor.targetPackage 配置"
        exit 1
    fi
    
    # 设置默认值（如果配置文件中没有设置）
    LOG_DIR="${LOG_DIR:-$DEFAULT_LOG_DIR}"
    LOG_PREFIX="${LOG_PREFIX:-$DEFAULT_LOG_PREFIX}"
    AUTO_EXTRACT_STACKS="${AUTO_EXTRACT_STACKS:-$DEFAULT_AUTO_EXTRACT}"
    
    # 验证必填项
    if [ -z "$TARGET_PACKAGE" ] || [ "$TARGET_PACKAGE" = "null" ]; then
        echo "❌ 错误: 目标应用包名不能为空"
        echo "💡 请在 $CONFIG_FILE 中设置 monitor.targetPackage"
        echo "📝 配置示例:"
        echo "   {\"monitor\": {\"targetPackage\": \"com.example.app\"}}"
        exit 1
    fi
}

# 获取配置值的便捷函数
get_target_package() {
    echo "$TARGET_PACKAGE"
}

get_log_dir() {
    echo "$LOG_DIR"
}

get_log_prefix() {
    echo "$LOG_PREFIX"
}

get_proxy_url() {
    echo "$PROXY_URL"
}

get_auto_extract_stacks() {
    echo "$AUTO_EXTRACT_STACKS"
}

# 检查配置是否已加载
is_config_loaded() {
    [ -n "$TARGET_PACKAGE" ]
} 