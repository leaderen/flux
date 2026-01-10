# 如何查看 iOS VPN 连接日志

## 📱 方法 1: Xcode Console（推荐，开发时）

### 步骤：
1. **打开 Xcode**
   ```
   打开项目: ios/Runner.xcworkspace
   ```

2. **连接设备或启动模拟器**
   - 通过 USB 连接 iPhone/iPad
   - 或启动 iOS 模拟器

3. **运行应用**
   - 在 Xcode 中点击运行按钮（▶️）
   - 或按 `Cmd + R`

4. **查看 Console**
   - 在 Xcode 底部打开 Console 面板
   - 或按 `Cmd + Shift + Y` 打开/关闭 Console
   - 在 Console 中搜索以下关键词：
     - `[VPNManager]` - VPN 管理器日志
     - `[Flux]` - PacketTunnel 日志
     - `[V2rayService]` - Flutter 端日志

### 过滤日志：
在 Console 的搜索框中输入：
- `[VPNManager]` - 只看 VPN 管理器日志
- `[Flux]` - 只看 PacketTunnel 日志
- `Error` 或 `❌` - 只看错误日志

## 📱 方法 2: 设备日志（真机调试）

### 通过 Xcode：
1. **打开 Xcode**
2. **Window → Devices and Simulators**（或按 `Cmd + Shift + 2`）
3. **选择你的设备**
4. **点击 "Open Console"**
5. **在搜索框中输入应用名称或 Bundle ID**: `com.flux.app`

### 通过命令行：
```bash
# 查看实时日志
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Runner"' --level debug

# 或者使用 idevicesyslog（需要安装 libimobiledevice）
idevicesyslog | grep -i "flux\|vpn\|v2ray"
```

## 📱 方法 3: 应用内日志（如果实现了）

如果应用有日志查看功能，可以在应用内查看。

## 🔍 关键日志标记

### VPNManager 日志标记：
- `[VPNManager] connect called` - 开始连接
- `[VPNManager] ✅ Config format validated` - 配置验证通过
- `[VPNManager] ❌ Invalid config format` - 配置格式错误
- `[VPNManager] 🚀 Starting VPN tunnel` - 启动 VPN 隧道
- `[VPNManager] ✅ VPN tunnel start initiated` - 隧道启动成功
- `[VPNManager] ❌ Start error` - 启动失败
- `[VPNManager] Status changed` - 状态变化

### PacketTunnel 日志标记：
- `[Flux] 📋 Starting Tunnel` - 开始启动隧道
- `[Flux] ✅ Config format is valid JSON` - 配置验证通过
- `[Flux] ❌ Error: Missing VPN configuration` - 配置缺失
- `[Flux] ❌ Error: Invalid JSON configuration` - JSON 格式错误
- `[Flux] 🔧 Applying tunnel network settings` - 应用网络设置
- `[Flux] ✅ Tunnel settings applied successfully` - 设置成功
- `[Flux] ❌ Failed to set tunnel settings` - 设置失败
- `[Flux] ⚠️ WARNING: Xray core not integrated` - Xray 核心未集成警告

### Flutter 端日志标记：
- `[V2rayService] Connecting to` - 开始连接
- `[V2rayService] Connection initiated successfully` - 连接启动成功
- `[V2rayService] Connection failed` - 连接失败
- `[V2rayService] PlatformException` - 平台异常

## 🐛 常见错误和解决方案

### 1. "Missing VPN configuration"
**日志**: `[Flux] ❌ Error: Missing VPN configuration`
**原因**: 配置未正确传递到 PacketTunnel
**解决**: 检查 VPNManager 是否正确传递配置

### 2. "Invalid JSON configuration"
**日志**: `[Flux] ❌ Error: Invalid JSON configuration`
**原因**: 配置 JSON 格式错误
**解决**: 检查 V2rayService 生成的配置格式

### 3. "MANAGER_NOT_READY"
**日志**: `[VPNManager] Manager not ready`
**原因**: VPN Manager 未加载完成
**解决**: 等待几秒后重试

### 4. "START_ERROR"
**日志**: `[VPNManager] ❌ Start error`
**原因**: VPN 隧道启动失败
**可能原因**:
- 权限问题（检查 entitlements）
- PacketTunnel target 未正确配置
- 系统限制

### 5. "Failed to set tunnel settings"
**日志**: `[Flux] ❌ Failed to set tunnel settings`
**原因**: 网络设置应用失败
**解决**: 检查网络权限和配置

## 📋 日志收集清单

当连接失败时，请收集以下日志：

1. **VPNManager 日志**（搜索 `[VPNManager]`）
   - 连接开始时间
   - 配置验证结果
   - 启动 VPN 隧道的步骤
   - 任何错误消息

2. **PacketTunnel 日志**（搜索 `[Flux]`）
   - 配置接收情况
   - 配置验证结果
   - 网络设置应用情况
   - 任何错误消息

3. **Flutter 端日志**（搜索 `[V2rayService]`）
   - 配置生成情况
   - 连接调用情况
   - 任何异常信息

4. **系统日志**
   - VPN 相关的系统错误
   - 权限相关的错误

## 💡 快速诊断命令

```bash
# 在 Xcode Console 中运行这些过滤命令：

# 只看错误
[VPNManager] ❌ OR [Flux] ❌ OR Error

# 只看连接相关
connect OR Connecting OR Connected

# 只看配置相关
config OR Config OR configuration

# 完整日志流
[VPNManager] OR [Flux] OR [V2rayService]
```

## 🔧 调试技巧

1. **启用详细日志**
   - 确保应用以 Debug 模式运行
   - 在 Xcode 中查看 Console

2. **实时监控**
   - 保持 Console 打开
   - 在连接时观察日志输出

3. **保存日志**
   - 在 Xcode Console 中右键 → "Export Log"
   - 或复制日志文本保存

4. **检查时间戳**
   - 注意日志的时间顺序
   - 找出失败的具体步骤

