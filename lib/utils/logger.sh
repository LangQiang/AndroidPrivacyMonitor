#!/bin/bash

# Frida监控工具 - 日志工具模块
# 提供统一的日志输出格式和颜色管理
# 作者: GodQ

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志级别
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# 当前日志级别（默认显示所有）
CURRENT_LOG_LEVEL=1

# 设置日志级别
set_log_level() {
    CURRENT_LOG_LEVEL="$1"
}

# 信息日志（蓝色）
log_info() {
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_INFO" ]; then
        echo -e "${BLUE}$1${NC}"
    fi
}

# 成功日志（绿色）
log_success() {
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_INFO" ]; then
        echo -e "${GREEN}$1${NC}"
    fi
}

# 警告日志（黄色）
log_warn() {
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_WARN" ]; then
        echo -e "${YELLOW}$1${NC}"
    fi
}

# 错误日志（红色）
log_error() {
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_ERROR" ]; then
        echo -e "${RED}$1${NC}"
    fi
}

# 步骤日志（带编号，青色）
log_step() {
    local step_num="$1"
    local total_steps="$2"
    local message="$3"
    
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_INFO" ]; then
        echo -e "\n${CYAN}🔍 [${step_num}/${total_steps}] ${message}${NC}"
    fi
}

# 普通输出（无颜色）
log_plain() {
    echo "$1"
}

# 带图标的特殊日志
log_check() {
    log_info "✅ $1"
}

log_fail() {
    log_error "❌ $1"
}

log_warn_icon() {
    log_warn "⚠️ $1"
}

log_process() {
    log_info "🔧 $1"
}

log_target() {
    log_info "🎯 $1"
}

log_rocket() {
    log_info "🚀 $1"
}

# 分隔线
log_separator() {
    echo "===================================="
}

# 换行
log_newline() {
    echo ""
} 