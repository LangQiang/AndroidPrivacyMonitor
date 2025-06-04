# 🚀 新电脑环境一键搭建指南

## 📋 快速开始

如果您在一台全新的电脑上需要搭建Frida Android隐私监控环境，只需要运行一个命令：

```bash
./setup_frida_environment.sh
```

## 🔍 frida-server-android-arm64 的来源

### 官方来源
- **GitHub仓库**: https://github.com/frida/frida/releases
- **文件类型**: 预编译的二进制文件
- **命名规则**: `frida-server-{版本}-android-{架构}.xz`
- **当前版本**: frida-server-17.0.7-android-arm64.xz

### 自动下载过程
我们的脚本会自动：
1. 检测当前Frida版本
2. 构建下载URL
3. 从GitHub下载对应的frida-server
4. 解压并重命名文件
5. 部署到Android设备

## 📦 完整搭建步骤

### 第一步：运行搭建脚本
```bash
# 下载或创建搭建脚本
curl -O https://your-repo/setup_frida_environment.sh
chmod +x setup_frida_environment.sh

# 运行一键搭建
./setup_frida_environment.sh
```

### 第二步：脚本自动完成的任务

1. **环境检测** 🔍
   - 检查操作系统 (macOS/Linux)
   - 验证Python3和pip3
   - 检查下载工具 (curl/wget)
   - 验证解压工具 (xz)

2. **Android环境检查** 📱
   - 检查ADB工具
   - 检测Android设备连接
   - 验证设备架构

3. **Frida工具安装** ⚙️
   - 安装/升级frida-tools
   - 获取Frida版本信息

4. **frida-server下载** 📥
   - 自动构建下载URL
   - 下载对应版本的frida-server
   - 解压并重命名文件

5. **设备部署** 🚀
   - 推送frida-server到设备
   - 设置执行权限
   - 启动frida-server服务

6. **环境验证** ✅
   - 测试Frida连接
   - 显示设备进程列表
   - 验证环境完整性

## 🛠️ 手动搭建步骤 (备用方案)

如果自动脚本失败，可以手动执行：

### 1. 安装基础工具
```bash
# macOS
brew install python3 android-platform-tools xz

# Ubuntu/Debian
sudo apt-get install python3 python3-pip android-tools-adb xz-utils

# CentOS/RHEL
sudo yum install python3 python3-pip android-tools xz
```

### 2. 安装Frida
```bash
pip3 install frida-tools
```

### 3. 下载frida-server
```bash
# 获取Frida版本
FRIDA_VERSION=$(frida --version)

# 下载frida-server
curl -L -o frida-server-${FRIDA_VERSION}-android-arm64.xz \
  https://github.com/frida/frida/releases/download/${FRIDA_VERSION}/frida-server-${FRIDA_VERSION}-android-arm64.xz

# 解压
unxz frida-server-${FRIDA_VERSION}-android-arm64.xz
mv frida-server-${FRIDA_VERSION}-android-arm64 frida-server-android-arm64
```

### 4. 部署到设备
```bash
# 推送到设备
adb push frida-server-android-arm64 /data/local/tmp/frida-server

# 设置权限
adb shell chmod 755 /data/local/tmp/frida-server

# 启动服务
adb shell "/data/local/tmp/frida-server &"
```

### 5. 验证环境
```bash
# 测试连接
frida-ps -U
```

## 📁 生成的文件说明

运行完成后，您将得到以下文件：

```
frida/
├── setup_frida_environment.sh    # 一键搭建脚本
├── frida-server-android-arm64     # Frida服务端程序
├── start_monitor.sh               # 监控启动脚本模板
├── frida_setup.log               # 详细安装日志
├── privacy_monitor_ultimate.js    # 监控脚本 (需要单独创建)
└── README.md                     # 项目文档
```

## 🔧 常见问题解决

### 1. 下载失败
```bash
# 检查网络连接
curl -I https://github.com

# 使用代理 (如果需要)
export https_proxy=http://your-proxy:port
./setup_frida_environment.sh
```

### 2. 权限问题
```bash
# 确保设备有root权限
adb shell su -c "whoami"

# 检查frida-server权限
adb shell ls -la /data/local/tmp/frida-server
```

### 3. 架构不匹配
```bash
# 检查设备架构
adb shell getprop ro.product.cpu.abi

# 下载对应架构的frida-server
# arm64-v8a -> arm64
# armeabi-v7a -> arm
# x86_64 -> x86_64
# x86 -> x86
```

## 🎯 下一步操作

环境搭建完成后：

1. **安装目标应用**
   ```bash
   adb install com.frog.educate.apk
   ```

2. **创建监控脚本**
   - 复制现有的 `privacy_monitor_ultimate.js`
   - 或参考项目文档创建新的监控脚本

3. **开始监控**
   ```bash
   ./start_monitor.sh
   ```

## 📊 脚本特性

✅ **智能检测**: 自动检测系统环境和已安装组件  
✅ **错误处理**: 详细的错误信息和解决建议  
✅ **彩色输出**: 清晰的状态显示和进度提示  
✅ **日志记录**: 完整的安装过程日志  
✅ **交互式**: 支持用户选择和确认  
✅ **兼容性**: 支持macOS和Linux系统  
✅ **自动化**: 一键完成所有配置步骤  

这个脚本让您可以在任何新电脑上快速搭建完整的Frida Android隐私监控环境！🎉 