Java.perform(function() {
    console.log("🔍 Frida隐私监控系统启动...");
    console.log("🎯 目标应用: com.frog.educate");
    console.log("📅 启动时间: " + new Date().toLocaleString());
    console.log("🔖 版本: Unified v1.0 (配置化统一监控)");
    console.log("=".repeat(60));
    
    // 创建日志文件名
    var now = new Date();
    var logFileName = now.getFullYear() + 
        String(now.getMonth() + 1).padStart(2, '0') + 
        String(now.getDate()).padStart(2, '0') + 
        String(now.getHours()).padStart(2, '0') + 
        String(now.getMinutes()).padStart(2, '0') + 
        String(now.getSeconds()).padStart(2, '0') + '.txt';
    
    console.log("📁 日志文件: ./build/logs/" + logFileName);
    
    // 颜色定义
    var RED = '\x1b[31m';
    var GREEN = '\x1b[32m';
    var YELLOW = '\x1b[33m';
    var BLUE = '\x1b[34m';
    var MAGENTA = '\x1b[35m';
    var CYAN = '\x1b[36m';
    var WHITE = '\x1b[37m';
    var RESET = '\x1b[0m';
    var BOLD = '\x1b[1m';
    
    var hooks = [];
    var callCount = 0;
    var sensitiveCallsLog = [];
    var applicationCreated = false;
    var applicationConstructed = false;
    var contentProviderCreated = false;
    
    // 监控ContentProvider生命周期
    try {
        var ContentProvider = Java.use("android.content.ContentProvider");
        ContentProvider.onCreate.implementation = function() {
            contentProviderCreated = true;
            console.log(BOLD + MAGENTA + "\n🏛️ [生命周期] ContentProvider.onCreate()被调用" + RESET);
            console.log(CYAN + "⏰ 时间: " + getTimestamp() + RESET);
            console.log(YELLOW + "📍 Provider: " + this.getClass().getName() + RESET);
            var result = this.onCreate();
            return result;
        };
        
        console.log(GREEN + "✅ ContentProvider生命周期监控已设置" + RESET);
    } catch (e) {
        console.log(YELLOW + "⚠️ ContentProvider生命周期监控设置失败: " + e + RESET);
    }
    
    // 监控Application生命周期
    try {
        var Application = Java.use("android.app.Application");
        Application.$init.implementation = function() {
            applicationConstructed = true;
            console.log(BOLD + MAGENTA + "\n🏗️ [生命周期] Application构造函数被调用" + RESET);
            console.log(CYAN + "⏰ 时间: " + getTimestamp() + RESET);
            return this.$init();
        };
        
        Application.onCreate.implementation = function() {
            applicationCreated = true;
            console.log(BOLD + MAGENTA + "\n🚀 [生命周期] Application.onCreate()被调用" + RESET);
            console.log(CYAN + "⏰ 时间: " + getTimestamp() + RESET);
            return this.onCreate();
        };
        
        console.log(GREEN + "✅ Application生命周期监控已设置" + RESET);
    } catch (e) {
        console.log(YELLOW + "⚠️ Application生命周期监控设置失败: " + e + RESET);
    }
    
    // Hook状态跟踪
    function testHook(name, hookFunction) {
        try {
            hookFunction();
            hooks.push({name: name, status: "✅ 成功", error: null});
            console.log(GREEN + "✅ " + name + " - Hook设置成功" + RESET);
        } catch (e) {
            hooks.push({name: name, status: "❌ 失败", error: e.toString()});
            console.log(RED + "❌ " + name + " - Hook设置失败: " + e.toString().substring(0, 80) + "..." + RESET);
        }
    }
    
    // 获取当前时间戳
    function getTimestamp() {
        var now = new Date();
        return now.getHours().toString().padStart(2, '0') + ':' + 
               now.getMinutes().toString().padStart(2, '0') + ':' + 
               now.getSeconds().toString().padStart(3, '0') + '.' + 
               now.getMilliseconds().toString().padStart(3, '0');
    }
    
    // 判断调用时机
    function getCallTiming() {
        if (!contentProviderCreated && !applicationConstructed) {
            return "🌟 超早期调用 (ContentProvider创建前)";
        } else if (contentProviderCreated && !applicationConstructed) {
            return "🏛️ ContentProvider期调用 (Application构造前)";
        } else if (!applicationCreated) {
            return "⚡ 早期调用 (Application.onCreate()前)";
        } else {
            return "📱 正常调用 (Application.onCreate()后)";
        }
    }
    
    // 增强的API调用记录函数
    function logCall(type, apiName, details, returnValue, args) {
        callCount++;
        var timestamp = getTimestamp();
        var timing = getCallTiming();
        
        console.log(BOLD + YELLOW + "\n🚨 [" + callCount + "] [" + timestamp + "] " + type + RESET);
        console.log(BOLD + RED + "⏰ 调用时机: " + timing + RESET);
        console.log(CYAN + "📋 API: " + apiName + RESET);
        if (details) console.log(BLUE + "📝 详情: " + details + RESET);
        
        // 显示传入参数
        if (args && args.length > 0) {
            console.log(GREEN + "📥 传入参数: [" + RESET);
            args.forEach(function(arg, index) {
                try {
                    var argStr = arg ? arg.toString() : "null";
                    console.log(GREEN + "   [" + index + "] " + argStr + RESET);
                } catch (e) {
                    console.log(GREEN + "   [" + index + "] <参数解析失败: " + e + ">" + RESET);
                }
            });
            console.log(GREEN + "]" + RESET);
        }
        
        if (returnValue) console.log(MAGENTA + "📤 返回值: " + returnValue + RESET);
        
        // 获取调用堆栈
        try {
            var stack = Java.use("android.util.Log").getStackTraceString(Java.use("java.lang.Exception").$new());
            var lines = stack.split('\n').slice(0, 10);
            console.log(WHITE + "📍 调用堆栈:" + RESET);
            console.log(YELLOW + "===== STACK_START =====" + RESET);
            
            var stackOutput = "";
            lines.forEach(function(line) {
                if (line.trim()) {
                    var lineStr = line.trim();
                    // 高亮Flutter相关的调用
                    if (lineStr.includes("flutter") || lineStr.includes("device_info") || lineStr.includes("MethodCallHandler")) {
                        console.log(BOLD + MAGENTA + "   ⭐ " + lineStr + RESET);
                        stackOutput += "   ⭐ " + lineStr + "\n";
                    } else {
                        console.log(CYAN + "   " + lineStr + RESET);
                        stackOutput += "   " + lineStr + "\n";
                    }
                }
            });
            
            console.log(YELLOW + "===== STACK_END =====" + RESET);
            
            // 记录到日志数组
            sensitiveCallsLog.push({
                id: callCount,
                timestamp: timestamp,
                timing: timing,
                type: type,
                api: apiName,
                details: details,
                returnValue: returnValue ? returnValue.toString() : null,
                stack: stack
            });
            
        } catch (e) {
            console.log(RED + "📍 堆栈获取失败: " + e + RESET);
        }
        console.log(YELLOW + "-".repeat(60) + RESET);
    }
    
    // 条件评估函数
    function evaluateCondition(conditionStr, args) {
        if (!conditionStr) return true;
        
        try {
            // 创建一个安全的评估环境
            var evalFunc = new Function('args', 'return ' + conditionStr);
            return evalFunc(args);
        } catch (e) {
            console.log(YELLOW + "⚠️ 条件评估失败: " + e + RESET);
            return true; // 默认通过
        }
    }
    
    // 统一的API监控创建函数
    function createUnifiedApiMonitor(config) {
        testHook(config.description, function() {
            // 1. 创建直接API调用监控
            createDirectApiMonitor(config);
            
            // 2. 创建反射监控
            createReflectionMonitor(config);
            
            console.log(BLUE + "📋 统一监控: " + config.className + "." + config.methodName + RESET);
            console.log(BLUE + "📋 反射监控: 自动生成" + RESET);
        });
    }
    
    // 创建直接API调用监控
    function createDirectApiMonitor(config) {
        try {
            var TargetClass = Java.use(config.className);
            var method = TargetClass[config.methodName];
            
            // 处理方法重载 - 支持新格式 [[], ["int"]]
            if (config.overloads && Array.isArray(config.overloads) && config.overloads.length > 0) {
                // 检查是否是新的重载格式（数组的数组）
                if (Array.isArray(config.overloads[0])) {
                    // 新格式：为每个重载版本分别创建hook
                    config.overloads.forEach(function(overloadParams, index) {
                        try {
                            var specificMethod = overloadParams.length === 0 ? 
                                method.overload() : 
                                method.overload.apply(method, overloadParams);
                            
                            specificMethod.implementation = function() {
                                var args = Array.prototype.slice.call(arguments);
                                
                                // 检查条件过滤
                                if (evaluateCondition(config.condition, args)) {
                                    var result = specificMethod.apply(this, args);
                                    logCall(config.description + " (重载" + index + ")", 
                                           config.className + "." + config.methodName, 
                                           config.logMessage + " [" + overloadParams.join(",") + "]", result, args);
                                    return result;
                                }
                                
                                return specificMethod.apply(this, args);
                            };
                        } catch (e) {
                            console.log(YELLOW + "⚠️ " + config.className + "." + config.methodName + " 重载" + index + " [" + overloadParams.join(",") + "] hook失败: " + e + RESET);
                        }
                    });
                } else {
                    // 旧格式：单个重载版本
                    method = method.overload.apply(method, config.overloads);
                    method.implementation = function() {
                        var args = Array.prototype.slice.call(arguments);
                        
                        // 检查条件过滤
                        if (evaluateCondition(config.condition, args)) {
                            var result = method.apply(this, args);
                            logCall(config.description, config.className + "." + config.methodName, 
                                   config.logMessage, result, args);
                            return result;
                        }
                        
                        return method.apply(this, args);
                    };
                }
            } else {
                // 无重载或空数组：hook默认方法
                method.implementation = function() {
                    var args = Array.prototype.slice.call(arguments);
                    
                    // 检查条件过滤
                    if (evaluateCondition(config.condition, args)) {
                        var result = method.apply(this, args);
                        logCall(config.description, config.className + "." + config.methodName, 
                               config.logMessage, result, args);
                        return result;
                    }
                    
                    return method.apply(this, args);
                };
            }
        } catch (e) {
            console.log(YELLOW + "⚠️ " + config.className + "." + config.methodName + " 直接监控失败: " + e + RESET);
        }
    }
    
    // 全局反射监控变量
    var reflectionHooksInstalled = false;
    
    // API配置变量 - 将从外部注入或使用默认配置
    var monitoredApis = APIS_CONFIG_PLACEHOLDER || [];
    
    // 创建反射监控
    function createReflectionMonitor(config) {
        // 将配置添加到监控列表（如果还没有的话）
        if (!monitoredApis.find(api => api.className === config.className && api.methodName === config.methodName)) {
            monitoredApis.push(config);
        }
        
        // 只安装一次全局反射Hook
        if (!reflectionHooksInstalled) {
            installGlobalReflectionHooks();
            reflectionHooksInstalled = true;
        }
    }
    
    // 安装全局反射Hook
    function installGlobalReflectionHooks() {
        try {
            // 1. Method.invoke监控
            var Method = Java.use("java.lang.reflect.Method");
            Method.invoke.overload('java.lang.Object', '[Ljava.lang.Object;').implementation = function(obj, args) {
                var methodName = this.getName();
                var className = this.getDeclaringClass().getName();
                
                // 检查是否是我们要监控的API
                var matchedConfig = monitoredApis.find(function(config) {
                    return config.methodName === methodName && config.className === className;
                });
                
                if (matchedConfig) {
                    // 检查条件过滤
                    if (evaluateCondition(matchedConfig.condition, args)) {
                        console.log(BOLD + RED + "\n🚨 [反射调用] " + className + "." + methodName + "()通过Method.invoke()被调用!" + RESET);
                        console.log(CYAN + "⏰ 时间: " + new Date().toLocaleString() + RESET);
                        console.log(BLUE + "📋 监控: " + matchedConfig.description + RESET);
                        
                        // 获取调用堆栈
                        try {
                            var stack = Java.use("android.util.Log").getStackTraceString(Java.use("java.lang.Exception").$new());
                            console.log(YELLOW + "📍 反射调用堆栈:" + RESET);
                            var lines = stack.split('\n').slice(0, 10);
                            lines.forEach(function(line, index) {
                                if (line.trim()) {
                                    var lineStr = line.trim();
                                    if (lineStr.includes("flutter") || lineStr.includes("device_info")) {
                                        console.log(BOLD + MAGENTA + "   [" + index + "] ⭐ " + lineStr + RESET);
                                    } else {
                                        console.log(BLUE + "   [" + index + "] " + lineStr + RESET);
                                    }
                                }
                            });
                        } catch (e) {
                            console.log(RED + "📍 堆栈获取失败: " + e + RESET);
                        }
                    }
                }
                
                var result = this.invoke(obj, args);
                
                if (matchedConfig && evaluateCondition(matchedConfig.condition, args)) {
                    console.log(GREEN + "📤 反射调用返回值: " + result + RESET);
                    console.log(YELLOW + "=".repeat(60) + RESET);
                }
                
                return result;
            };
            
            // 2. Class.getMethod监控
            var Class = Java.use("java.lang.Class");
            Class.getMethod.overload('java.lang.String', '[Ljava.lang.Class;').implementation = function(name, parameterTypes) {
                var result = this.getMethod(name, parameterTypes);
                
                var matchedConfig = monitoredApis.find(function(config) {
                    return config.methodName === name && config.className === this.getName();
                }.bind(this));
                
                if (matchedConfig) {
                    console.log(BOLD + YELLOW + "\n🔍 [反射获取] " + this.getName() + "." + name + "方法通过Class.getMethod()被获取!" + RESET);
                    console.log(CYAN + "⏰ 时间: " + new Date().toLocaleString() + RESET);
                    console.log(BLUE + "📋 监控: " + matchedConfig.description + RESET);
                }
                
                return result;
            };
            
            // 3. Class.getDeclaredMethod监控
            Class.getDeclaredMethod.overload('java.lang.String', '[Ljava.lang.Class;').implementation = function(name, parameterTypes) {
                var result = this.getDeclaredMethod(name, parameterTypes);
                
                var matchedConfig = monitoredApis.find(function(config) {
                    return config.methodName === name && config.className === this.getName();
                }.bind(this));
                
                if (matchedConfig) {
                    console.log(BOLD + YELLOW + "\n🔍 [反射获取] " + this.getName() + "." + name + "方法通过Class.getDeclaredMethod()被获取!" + RESET);
                    console.log(CYAN + "⏰ 时间: " + new Date().toLocaleString() + RESET);
                    console.log(BLUE + "📋 监控: " + matchedConfig.description + RESET);
                }
                
                return result;
            };
            
            // 4. Class.getDeclaredField监控
            Class.getDeclaredField.implementation = function(name) {
                var result = this.getDeclaredField(name);
                
                var matchedConfig = monitoredApis.find(function(config) {
                    return config.relatedFields && config.relatedFields.includes(name) && config.className === this.getName();
                }.bind(this));
                
                if (matchedConfig) {
                    console.log(BOLD + YELLOW + "\n🔍 [反射获取] " + this.getName() + "." + name + "字段通过Class.getDeclaredField()被获取!" + RESET);
                    console.log(CYAN + "⏰ 时间: " + new Date().toLocaleString() + RESET);
                    console.log(BLUE + "📋 监控: " + matchedConfig.description + RESET);
                }
                
                return result;
            };
            
            console.log(GREEN + "✅ 全局反射监控已安装" + RESET);
            
        } catch (e) {
            console.log(RED + "❌ 反射监控安装失败: " + e + RESET);
        }
    }
    
    // 从配置变量创建监控
    try {
        console.log(BLUE + "\n📋 从配置变量加载监控..." + RESET);
        console.log(BLUE + "📊 配置的API数量: " + monitoredApis.length + RESET);
        
        // 验证配置格式
        if (!Array.isArray(monitoredApis) || monitoredApis.length === 0) {
            console.log(YELLOW + "⚠️ 配置变量为空或格式错误，使用内置默认配置" + RESET);
            
            // 提供默认配置
            monitoredApis = [
                {
                    "description": "序列号监控",
                    "className": "android.os.Build",
                    "methodName": "getSerial",
                    "overloads": [],
                    "condition": null,
                    "logMessage": "获取设备序列号",
                    "relatedFields": ["SERIAL"]
                },
                {
                    "description": "Android ID监控", 
                    "className": "android.provider.Settings$Secure",
                    "methodName": "getString",
                    "overloads": ["android.content.ContentResolver", "java.lang.String"],
                    "condition": "args[1] === 'android_id'",
                    "logMessage": "获取设备唯一标识",
                    "relatedFields": []
                }
            ];
        }
        
        // 为每个配置创建统一监控
        monitoredApis.forEach(function(apiConfig) {
            createUnifiedApiMonitor(apiConfig);
        });
        
    } catch (e) {
        console.log(RED + "❌ 配置加载失败: " + e + RESET);
        console.log(RED + "🚨 使用最小默认配置继续运行" + RESET);
        
        // 最小配置继续运行
        var minimalConfig = [{
            "description": "Android ID监控", 
            "className": "android.provider.Settings$Secure",
            "methodName": "getString",
            "overloads": ["android.content.ContentResolver", "java.lang.String"],
            "condition": "args[1] === 'android_id'",
            "logMessage": "获取设备唯一标识",
            "relatedFields": []
        }];
        
        minimalConfig.forEach(function(apiConfig) {
            createUnifiedApiMonitor(apiConfig);
        });
    }
    
    // 显示Hook设置结果
    setTimeout(function() {
        console.log(BOLD + BLUE + "\n📊 Hook设置完成统计:" + RESET);
        var successCount = 0;
        var failCount = 0;
        
        hooks.forEach(function(hook) {
            if (hook.status.includes("成功")) {
                successCount++;
                console.log(GREEN + "✅ " + hook.name + RESET);
            } else {
                failCount++;
                console.log(RED + "❌ " + hook.name + ": " + (hook.error ? hook.error.substring(0, 50) + "..." : "未知错误") + RESET);
            }
        });
        
        console.log(BOLD + GREEN + "\n🎯 监控设置完成!" + RESET);
        console.log(GREEN + "✅ 成功: " + successCount + " 个" + RESET);
        console.log(RED + "❌ 失败: " + failCount + " 个" + RESET);
        console.log(BLUE + "📱 成功率: " + Math.round((successCount / (successCount + failCount)) * 100) + "%" + RESET);
        console.log(YELLOW + "🔍 开始监控隐私API调用..." + RESET);
        console.log("=".repeat(60));
    }, 1000);
}); 