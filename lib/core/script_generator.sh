#!/bin/bash

# Frida监控工具 - 脚本生成模块
# 负责动态生成监控脚本和API配置注入
# 作者: GodQ

# 动态生成JS文件函数
generate_monitor_script() {
    echo -e "\n🔧 [动态生成] 开始生成监控脚本..."
    
    # 确保build目录存在
    mkdir -p build
    
    # 读取配置文件中的API配置
    local apis_config=""
    if command -v jq &> /dev/null; then
        apis_config=$(jq '.apis' "$CONFIG_FILE" 2>/dev/null)
    else
        echo -e "${YELLOW}⚠️ 未找到jq工具，使用grep提取配置${NC}"
        # 简单提取apis部分（备用方案）
        apis_config=$(sed -n '/\"apis\":/,/],/p' "$CONFIG_FILE" | sed '1s/.*\[/[/' | sed '$s/].*/]/')
    fi
    
    if [ -z "$apis_config" ] || [ "$apis_config" = "null" ]; then
        echo -e "${RED}❌ 无法提取API配置${NC}"
        return 1
    fi
    
    # 生成时间戳和文件路径
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local build_file="build/privacy_monitor_generated.js"
    local template_file="lib/privacy_monitor_template.js"
    
    # 检查模板文件是否存在
    if [ ! -f "$template_file" ]; then
        echo -e "${RED}❌ 模板文件不存在: $template_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📝 基于模板: ${template_file}${NC}"
    echo -e "${BLUE}📝 生成文件: ${build_file}${NC}"
    
    # 复制模板文件
    cp "$template_file" "$build_file"
    
    # 添加生成信息注释
    sed -i '' '1i\
// 自动生成的Frida隐私监控脚本\
// 生成时间: '"$timestamp"'\
// 配置文件: '"$CONFIG_FILE"'\
// 目标应用: '"$TARGET_PACKAGE"'\
// 基于模板: '"$template_file"'\
' "$build_file"
    
    # 替换配置占位符 - 拼接完整变量声明
    # 第一步：替换为临时标记
    sed -i '' 's/var monitoredApis = APIS_CONFIG_PLACEHOLDER || \[\];/REPLACE_CONFIG_HERE/g' "$build_file"
    
    # 第二步：创建完整的变量定义
    echo "var monitoredApis = " > build/temp_config.json
    echo "$apis_config" >> build/temp_config.json
    echo ";" >> build/temp_config.json
    
    # 第三步：插入完整定义并删除占位符
    sed -i '' "/REPLACE_CONFIG_HERE/r build/temp_config.json" "$build_file"
    sed -i '' "/REPLACE_CONFIG_HERE/d" "$build_file"
    rm -f build/temp_config.json

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ JS文件生成成功: ${build_file}${NC}"
        echo -e "${BLUE}📊 配置注入: $(echo "$apis_config" | grep -c '"description"') 个API${NC}"
        echo -e "${BLUE}🔧 保持模板的所有完整功能${NC}"
        return 0
    else
        echo -e "${RED}❌ JS文件生成失败${NC}"
        return 1
    fi
}

# 检查模板文件是否存在
check_template_file() {
    local template_file="lib/privacy_monitor_template.js"
    [ -f "$template_file" ]
}

# 获取生成脚本的路径
get_generated_script_path() {
    echo "build/privacy_monitor_generated.js"
}

# 验证生成的脚本
validate_generated_script() {
    local build_file="build/privacy_monitor_generated.js"
    if [ -f "$build_file" ]; then
        # 检查文件大小
        local file_size=$(wc -c < "$build_file")
        if [ "$file_size" -gt 100 ]; then
            return 0
        fi
    fi
    return 1
} 