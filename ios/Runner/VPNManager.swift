import Foundation
import NetworkExtension
import Flutter

class VPNManager: NSObject {
    static let shared = VPNManager()
    
    // The Bundle ID of the Network Extension
    // User must create a Target named 'PacketTunnel'
    let extensionBundleId = Bundle.main.bundleIdentifier! + ".PacketTunnel"
    
    var manager: NETunnelProviderManager?
    var statusSink: FlutterEventSink?
    
    override init() {
        super.init()
        loadManager()
    }
    
    private func loadManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard let self = self else { return }
            if let error = error {
                print("[VPNManager] ❌ Error loading VPN managers: \(error.localizedDescription)")
                return
            }
            
            if let managers = managers, !managers.isEmpty {
                self.manager = managers.first
                print("[VPNManager] ✅ Loaded existing VPN manager")
            } else {
                print("[VPNManager] 📝 Creating new VPN manager...")
                self.manager = NETunnelProviderManager()
                self.manager?.localizedDescription = "Flux VPN"
                
                let proto = NETunnelProviderProtocol()
                proto.providerBundleIdentifier = self.extensionBundleId
                proto.serverAddress = "Flux"
                self.manager?.protocolConfiguration = proto
                
                print("[VPNManager] 📝 Extension Bundle ID: \(self.extensionBundleId)")
                
                self.manager?.saveToPreferences(completionHandler: { (error) in
                    if let error = error {
                        print("[VPNManager] ❌ Error saving new manager: \(error.localizedDescription)")
                    } else {
                        print("[VPNManager] ✅ New VPN manager saved successfully")
                    }
                })
            }
            
            // Listen for status changes - 监听所有 VPN 状态变化
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.statusDidChange(_:)),
                name: .NEVPNStatusDidChange,
                object: nil
            )
            print("[VPNManager] 👂 Listening for VPN status changes")
        }
    }
    
    func connect(config: String, result: @escaping FlutterResult) {
        print("[VPNManager] 🔌 connect called with config length: \(config.count)")
        
        // 诊断信息
        print("[VPNManager] 📋 Diagnostic info:")
        print("[VPNManager]    - Extension Bundle ID: \(self.extensionBundleId)")
        print("[VPNManager]    - Manager exists: \(self.manager != nil)")
        if let manager = self.manager {
            print("[VPNManager]    - Manager enabled: \(manager.isEnabled)")
            print("[VPNManager]    - Current status: \(manager.connection.status.rawValue)")
        }
        
        guard let manager = self.manager else {
            print("[VPNManager] ⚠️ Manager not ready, loading...")
            loadManager()
            // 等待 manager 加载完成，增加等待时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let manager = self.manager {
                    print("[VPNManager] ✅ Manager loaded, proceeding with connection")
                    self._doConnect(manager: manager, config: config, result: result)
                } else {
                    let errorMsg = "VPN Manager not loaded yet. Please try again. Extension ID: \(self.extensionBundleId)"
                    print("[VPNManager] ❌ Manager still not available after 2 seconds")
                    result(FlutterError(
                        code: "MANAGER_NOT_READY",
                        message: errorMsg,
                        details: ["extension_id": self.extensionBundleId, "error": "Manager not loaded"]
                    ))
                }
            }
            return
        }
        
        _doConnect(manager: manager, config: config, result: result)
    }
    
    private func _doConnect(manager: NETunnelProviderManager, config: String, result: @escaping FlutterResult) {
        // Validate config format before proceeding
        guard let configData = config.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: configData) else {
            print("[VPNManager] ❌ Invalid config format: Not valid JSON")
            result(FlutterError(code: "INVALID_CONFIG", message: "Configuration is not valid JSON", details: nil))
            return
        }
        
        print("[VPNManager] ✅ Config format validated")
        
        manager.loadFromPreferences { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                print("[VPNManager] ❌ Load error: \(error.localizedDescription)")
                result(FlutterError(code: "LOAD_ERROR", message: error.localizedDescription, details: nil))
                return
            }
            
            print("[VPNManager] 📋 Creating protocol configuration...")
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = self.extensionBundleId
            proto.serverAddress = "Flux"
            // Pass V2Ray config to extension
            proto.providerConfiguration = ["config": config]
            
            manager.protocolConfiguration = proto
            manager.isEnabled = true
            
            print("[VPNManager] 💾 Saving preferences...")
            manager.saveToPreferences { (error) in
                if let error = error {
                    print("[VPNManager] ❌ Save error: \(error.localizedDescription)")
                    result(FlutterError(code: "SAVE_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                
                print("[VPNManager] ✅ Preferences saved successfully")
                print("[VPNManager] 🚀 Starting VPN tunnel...")
                
                // Check current connection status
                let currentStatus = manager.connection.status
                print("[VPNManager] 📊 Current VPN status: \(currentStatus.rawValue)")
                
                // If already connected, stop first
                if currentStatus == .connected || currentStatus == .connecting {
                    print("[VPNManager] ⚠️ VPN is already \(currentStatus == .connected ? "connected" : "connecting"), stopping first...")
                    manager.connection.stopVPNTunnel()
                    // Wait a bit before starting new connection
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self._startTunnel(manager: manager, result: result)
                    }
                } else {
                    self._startTunnel(manager: manager, result: result)
                }
            }
        }
    }
    
    private func _startTunnel(manager: NETunnelProviderManager, result: @escaping FlutterResult) {
        // 检查 extension bundle ID
        let extensionId = self.extensionBundleId
        print("[VPNManager] 🔍 Extension Bundle ID: \(extensionId)")
        
        // 直接尝试启动 VPN 隧道（不需要再次 loadFromPreferences）
        do {
            print("[VPNManager] 🚀 Attempting to start VPN tunnel...")
            try manager.connection.startVPNTunnel(options: [:])
            
            let status = manager.connection.status
            print("[VPNManager] ✅ VPN tunnel start initiated")
            print("[VPNManager] 📊 VPN status after start: \(status.rawValue) (\(self._statusDescription(status)))")
            
            // 立即返回 true，让 Flutter 端通过状态流监听连接结果
            // iOS VPN 连接是异步的，需要通过状态流来获取实际连接结果
            result(true)
            
            // 设置定时器，定期检查状态（用于调试和诊断）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let currentStatus = manager.connection.status
                print("[VPNManager] 📊 Status after 1s: \(currentStatus.rawValue) (\(self._statusDescription(currentStatus)))")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                let currentStatus = manager.connection.status
                print("[VPNManager] 📊 Status after 3s: \(currentStatus.rawValue) (\(self._statusDescription(currentStatus)))")
                if currentStatus == .disconnected || currentStatus == .invalid {
                    print("[VPNManager] ⚠️ Connection failed - status is \(self._statusDescription(currentStatus))")
                }
            }
        } catch {
            let errorMsg = error.localizedDescription
            let errorType = String(describing: type(of: error))
            print("[VPNManager] ❌ Start error: \(errorMsg)")
            print("[VPNManager] ❌ Error type: \(errorType)")
            print("[VPNManager] ❌ Error details: \(error)")
            
            // 检查是否是 extension 不存在的问题
            let errorLower = errorMsg.lowercased()
            var errorCode = "START_ERROR"
            var detailedMessage = errorMsg
            
            if errorLower.contains("extension") || errorLower.contains("bundle") || errorLower.contains("not found") || errorLower.contains("unable to find") {
                errorCode = "EXTENSION_NOT_FOUND"
                detailedMessage = "PacketTunnel extension may not be configured. Extension ID: \(extensionId)"
                print("[VPNManager] ⚠️⚠️⚠️ CRITICAL: PacketTunnel extension may not be configured in Xcode")
                print("[VPNManager] ⚠️ Please ensure:")
                print("[VPNManager]    1. PacketTunnel target exists in Xcode project")
                print("[VPNManager]    2. Bundle ID is: \(extensionId)")
                print("[VPNManager]    3. PacketTunnelProvider.swift is added to PacketTunnel target")
            }
            
            result(FlutterError(
                code: errorCode,
                message: detailedMessage,
                details: [
                    "extension_id": extensionId,
                    "error_type": errorType,
                    "error_description": errorMsg,
                    "suggestion": "Please check if PacketTunnel target exists in Xcode"
                ]
            ))
        }
    }
    
    func disconnect(result: @escaping FlutterResult) {
        guard let manager = self.manager else {
            print("[VPNManager] ⚠️ Manager not available for disconnect")
            result(false)
            return
        }
        
        let status = manager.connection.status
        print("[VPNManager] 🛑 Disconnecting VPN (current status: \(status.rawValue))")
        
        if status == .connected || status == .connecting {
            manager.connection.stopVPNTunnel()
            print("[VPNManager] ✅ VPN disconnect initiated")
            result(true)
        } else {
            print("[VPNManager] ⚠️ VPN is not connected (status: \(status.rawValue))")
            result(true) // Return true anyway since we're already disconnected
        }
    }
    
    func isConnected() -> Bool {
        guard let manager = self.manager else {
            return false
        }
        let status = manager.connection.status
        let connected = (status == .connected)
        print("[VPNManager] 📊 Connection status check: \(status.rawValue) -> \(connected)")
        return connected
    }
    
    @objc func statusDidChange(_ notification: Notification) {
        // iOS 的 NEVPNStatusDidChange 通知的 object 是 NETunnelProviderManager，不是 NEVPNConnection
        // 我们需要从 manager 获取 connection
        guard let manager = self.manager else {
            print("[VPNManager] ⚠️ Manager not available in statusDidChange")
            return
        }
        
        let connection = manager.connection
        let status = connection.status
        let isConnected = (status == .connected)
        
        print("[VPNManager] 📊 Status changed: \(status.rawValue) - isConnected: \(isConnected)")
        print("[VPNManager] 📊 Status description: \(_statusDescription(status))")
        
        // 发送状态更新到 Flutter
        if let sink = statusSink {
            sink(isConnected)
            print("[VPNManager] ✅ Status update sent to Flutter: \(isConnected)")
        } else {
            print("[VPNManager] ⚠️ Status sink is nil, cannot send update to Flutter")
        }
        
        // 记录详细状态信息
        switch status {
        case .invalid:
            print("[VPNManager] ❌ VPN status is invalid - connection failed")
        case .disconnected:
            print("[VPNManager] 🔌 VPN disconnected")
        case .connecting:
            print("[VPNManager] 🔄 VPN connecting...")
        case .connected:
            print("[VPNManager] ✅ VPN connected successfully")
        case .reasserting:
            print("[VPNManager] 🔄 VPN reasserting...")
        @unknown default:
            print("[VPNManager] ⚠️ Unknown VPN status: \(status.rawValue)")
        }
    }
    
    private func _statusDescription(_ status: NEVPNStatus) -> String {
        switch status {
        case .invalid: return "invalid"
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .reasserting: return "reasserting"
        @unknown default: return "unknown(\(status.rawValue))"
        }
    }
}

class VPNStatusStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        VPNManager.shared.statusSink = events
        // Send initial status
        events(VPNManager.shared.isConnected())
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        VPNManager.shared.statusSink = nil
        return nil
    }
}
