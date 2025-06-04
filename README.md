# Frida Android 隐私监控工具

🔍 基于Frida的Android应用隐私API调用监控系统，专门用于检测应用在隐私协议同意前的敏感数据获取行为

**作者**: GodQ  
**版本**: v3.6  
**更新时间**: 2025-06-04  
**新增功能**: 安全的eval配置解析

## 📋 第一部分：环境要求

### 🖥️ 本机环境要求

#### 操作系统支持
- **macOS** 10.14+ (推荐)
- **Linux** Ubuntu 18.04+ / CentOS 7+
- **Windows** 10+ (通过WSL2)

#### 必需工具
```bash
# Python环境
Python 3.7+

# Frida工具链
pip install frida-tools

# Android开发工具
Android SDK Platform Tools (adb命令)

# 网络工具 (二选一)
curl 或 wget

# 解压工具
unxz (用于解压frida-server)
```

#### 可选工具
```bash
# 磁盘空间检查
df 命令

# 数学计算 (磁盘空间检查)
bc 命令
```

**注意**: 新版本已移除jq依赖，使用安全的eval方法解析key=value配置格式

### 📱 目标设备要求

#### 设备类型
- **Android模拟器** (推荐)
  - Android Studio AVD
  - Genymotion
  - 其他x86/ARM模拟器
- **物理设备**
  - 已Root的Android手机/平板

#### 系统要求
- **Android版本**: 5.0+ (API Level 21+)
- **架构支持**: ARM64, ARM, x86_64, x86
- **Root权限**: 必需 ⚠️
- **USB调试**: 已开启
- **存储空间**: 至少50MB可用空间

#### Root权限验证
```bash
# 检查Root权限
adb shell "id"
# 应返回: uid=0(root) gid=0(root) ...

# 或者
adb shell "whoami"
# 应返回: root
```

### 🌐 网络要求

- **下载frida-server时需要**: 访问GitHub (github.com)
- **离线使用**: 如已有frida-server文件，可离线运行
- **代理支持**: 支持通过配置文件设置代理

## 🚀 第二部分：项目功能

### 🎯 核心功能

#### 隐私API监控
- **设备标识符**: Android ID、IMEI、MAC地址、序列号
- **位置信息**: GPS定位、网络定位、基站定位
- **SIM卡信息**: IMSI、SIM序列号、手机号码
- **设备信息**: 设备型号、系统版本、硬件信息
- **应用列表**: 已安装应用信息获取
- **联系人数据**: 联系人数据库访问
- **多媒体权限**: 相机、麦克风访问
- **剪贴板**: 剪贴板读写操作

#### 高级监控特性
- **调用时机检测**: 区分超早期、早期、正常调用
- **生命周期监控**: ContentProvider、Application生命周期
- **Flutter应用支持**: 专门适配Flutter框架
- **异常监控**: SecurityException等权限异常
- **反射调用检测**: 通过反射获取隐私信息
- **完整堆栈跟踪**: 精确定位调用源码位置

#### 智能化特性
- **9步环境检测**: 全面的运行环境验证
- **自动部署**: 缺失组件自动下载配置
- **架构适配**: 自动识别设备架构选择对应frida-server
- **按需网络检测**: 仅在需要下载时检测网络连接
- **应用状态处理**: 智能处理应用未安装、运行中等状态
- **简化配置**: key=value格式，无需额外工具 🆕
- **安全配置解析**: 使用eval方法替代source，避免环境污染 🆕

### 🔧 技术特点

#### Hook技术
- **方法Hook**: 直接Hook Java方法调用
- **字段访问Hook**: 监控静态字段访问
- **构造函数Hook**: 监控对象创建过程
- **异常处理Hook**: 捕获和分析异常信息

#### 数据采集
- **实时监控**: 应用运行时实时捕获API调用
- **详细日志**: 时间戳、调用参数、返回值、堆栈信息
- **分类统计**: 按API类型分类统计调用次数
- **调用链分析**: 完整的方法调用链路追踪

## 📊 第三部分：输入输出

### 📥 输入

#### 目标应用
- **包名**: 通过配置文件设置 (默认: `com.frog.educate`)
- **应用状态**: 自动处理未安装、运行中等状态
- **版本兼容**: 支持不同版本的目标应用

#### 配置参数
- **监控脚本**: `lib/privacy_monitor_ultimate.js`
- **配置文件**: `config.conf` 🆕
- **frida-server**: 自动选择对应架构版本
- **日志目录**: 可配置 (默认: `./logs/`)

### 📤 输出

#### 实时输出
```
🚨 [1] [12:01:021.369] 序列号获取(异常)
⏰ 调用时机: 📱 正常调用 (Application.onCreate()后)
📋 API: Build.getSerial
📝 详情: SecurityException: getSerial权限不足
📤 返回值: unknown
📍 调用堆栈: [完整堆栈信息]
```

#### 日志文件
1. **完整日志**: `logs/frida_log_YYYY-MM-DD_HH-MM-SS.txt`
   - 包含所有监控信息
   - Frida系统输出
   - 详细的API调用记录
   - 完整的堆栈跟踪信息

2. **纯堆栈文件**: `logs/frida_log_YYYY-MM-DD_HH-MM-SS_stacks_only.txt`
   - 仅包含堆栈信息
   - 便于代码分析
   - 自动提取生成

#### 统计信息
```
📊 Hook设置完成统计:
✅ 成功: 14 个
❌ 失败: 0 个  
📱 成功率: 100%
```

## 🏗️ 第四部分：项目结构

```
frida/
├── start_monitor.sh              # 🚀 主启动脚本 (v3.6)
├── config.conf                   # ⚙️ 配置文件 🆕
├── lib/                          # 📚 库文件目录
│   ├── privacy_monitor_ultimate.js  # 核心监控脚本
│   ├── extract_stacks.sh            # 堆栈提取工具
│   └── frida-server-android-arm64   # Frida服务端程序
├── logs/                         # 📁 日志输出目录
│   ├── frida_log_2025-06-04_12-01-20.txt
│   └── frida_log_2025-06-04_12-01-20_stacks_only.txt
├── docs/                         # 📚 文档目录
│   ├── SETUP_GUIDE.md                # 详细搭建指南
│   └── setup_frida_environment.sh    # 一键环境配置
└── README.md                     # 项目说明文档
```

## ⚙️ 第五部分：配置文件

### 📝 配置文件格式 (config.conf)

```bash
# Frida Android 隐私监控工具配置文件
# 作者: GodQ
# 版本: v3.6
# 格式: key=value (不要有空格)

# 目标应用包名 (必填)
TARGET_PACKAGE=com.frog.educate

# 日志输出路径 (可选，默认: ./logs)
LOG_DIR=./logs

# 代理地址 (可选，用于下载frida-server)
# 格式示例: http://proxy.company.com:8080
# 留空表示不使用代理
PROXY_URL=

# 其他可选配置
# 日志文件前缀 (可选，默认: frida_log)
LOG_PREFIX=frida_log

# 是否自动提取堆栈信息 (可选，默认: true)
AUTO_EXTRACT_STACKS=true
```

### 🔧 主要配置项

#### 目标应用配置
```bash
# 修改目标应用包名
TARGET_PACKAGE=com.your.app
```

#### 日志配置
```bash
# 自定义日志目录
LOG_DIR=./custom_logs

# 自定义文件前缀
LOG_PREFIX=my_log

# 禁用自动堆栈提取
AUTO_EXTRACT_STACKS=false
```

#### 网络配置
```bash
# 设置代理（用于下载frida-server）
PROXY_URL=http://proxy.company.com:8080

# 或者使用SOCKS代理
PROXY_URL=socks5://127.0.0.1:1080
```

### 🆕 配置文件优势

- **安全性强**: 使用eval方法，只解析符合格式的配置行
- **注释友好**: 支持#注释，便于理解
- **容错性强**: 缺失配置项自动使用默认值
- **跨平台**: 所有系统都支持，无依赖
- **环境隔离**: 避免source方法的环境污染问题

## 🚀 第六部分：快速开始

### 一键启动
```bash
# 克隆或下载项目后
cd frida

# 一键启动监控 (v3.6支持简化配置)
./start_monitor.sh
```

### 启动流程
1. **配置文件检查** (检查config.conf，使用安全eval解析)
2. **环境检测** (9步验证)
3. **自动部署** (如需要)
4. **应用监控** (实时Hook)
5. **日志记录** (自动保存)
6. **堆栈提取** (自动处理)

### 监控操作
```bash
# 启动监控
./start_monitor.sh

# 停止监控
按 Ctrl+C

# 查看日志
ls logs/

# 分析堆栈
cat logs/*_stacks_only.txt
```

## 🔧 第七部分：高级配置

### 修改目标应用
```bash
# 编辑配置文件
vim config.conf
# 修改: TARGET_PACKAGE=com.your.app
```

### 设置代理
```bash
# 编辑配置文件
vim config.conf
# 添加: PROXY_URL=http://proxy.company.com:8080
```

### 自定义日志
```bash
# 编辑配置文件
vim config.conf
# 修改: LOG_DIR=./my_logs
# 修改: LOG_PREFIX=my_app_log
```

### 环境问题排查
```bash
# 检查配置文件
cat config.conf

# 检查Frida版本
frida --version

# 检查设备连接
adb devices

# 检查Root权限
adb shell "whoami"

# 手动启动frida-server
adb shell "/data/local/tmp/frida-server &"
```

## 📚 第八部分：使用场景

### 隐私合规检测
- **隐私协议前检测**: 监控应用在用户同意隐私协议前的数据获取
- **权限滥用检测**: 发现应用过度获取设备信息
- **第三方SDK审计**: 识别第三方SDK的隐私数据收集行为

### 安全研究
- **API调用分析**: 深入了解应用的数据获取行为
- **代码逆向辅助**: 通过堆栈信息定位关键代码
- **行为模式分析**: 分析应用的隐私数据使用模式

### 开发调试
- **隐私API测试**: 验证应用的隐私保护措施
- **权限申请优化**: 优化权限申请时机和方式
- **合规性验证**: 确保应用符合隐私保护法规

## ⚠️ 第九部分：注意事项

### 法律合规
- 仅用于合法的安全研究和开发测试
- 不得用于恶意攻击或非法获取他人隐私
- 使用前请确保符合当地法律法规

### 技术限制
- 需要Root权限，无法在普通设备上使用
- 部分加固应用可能无法完全监控
- 网络环境可能影响frida-server下载

### 使用建议
- 建议在测试环境中使用
- 定期更新Frida版本以获得最佳兼容性
- 监控结果仅供参考，需结合实际情况分析
- 配置文件格式简单，易于维护和修改

## 📞 第十部分：支持与反馈

### 👨‍💻 作者信息
- **作者**: GodQ
- **专业领域**: Android开发、隐私合规检测
- **项目维护**: 持续更新和优化

### 版本信息
- **当前版本**: v3.6
- **更新内容**: 安全的eval配置解析
- **兼容性**: Frida 17.0.7+

### 问题反馈
如遇到问题，请提供以下信息：
- 操作系统版本
- Frida版本
- 设备类型和Android版本
- 完整的错误日志
- 配置文件内容

---

🎯 **项目目标**: 为Android应用隐私合规检测提供专业、高效的技术工具

⭐ **核心优势**: 全自动化、高精度、易使用、专业级监控能力、安全配置解析

👨‍💻 **开发者**: GodQ