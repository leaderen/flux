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
                print("Error loading VPN managers: \(error)")
                return
            }
            
            if let managers = managers, !managers.isEmpty {
                self.manager = managers.first
            } else {
                self.manager = NETunnelProviderManager()
                self.manager?.localizedDescription = "Flux VPN"
                
                let proto = NETunnelProviderProtocol()
                proto.providerBundleIdentifier = self.extensionBundleId
                proto.serverAddress = "Flux"
                self.manager?.protocolConfiguration = proto
                
                self.manager?.saveToPreferences(completionHandler: { (error) in
                    if let error = error {
                        print("Error saving new manager: \(error)")
                    }
                })
            }
            
            // Listen for status changes
            NotificationCenter.default.addObserver(self, selector: #selector(self.statusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
        }
    }
    
    func connect(config: String, result: @escaping FlutterResult) {
        print("[VPNManager] connect called with config length: \(config.count)")
        
        guard let manager = self.manager else {
            print("[VPNManager] Manager not ready, loading...")
            loadManager()
            // 等待 manager 加载完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let manager = self.manager {
                    self._doConnect(manager: manager, config: config, result: result)
                } else {
                    result(FlutterError(code: "MANAGER_NOT_READY", message: "VPN Manager not loaded yet", details: nil))
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
        do {
            try manager.connection.startVPNTunnel(options: [:])
            let status = manager.connection.status
            print("[VPNManager] ✅ VPN tunnel start initiated")
            print("[VPNManager] 📊 VPN status after start: \(status.rawValue)")
            
            // 立即返回 true，让 Flutter 端通过状态流监听连接结果
            // iOS VPN 连接是异步的，需要通过状态流来获取实际连接结果
            result(true)
        } catch {
            print("[VPNManager] ❌ Start error: \(error.localizedDescription)")
            result(FlutterError(code: "START_ERROR", message: error.localizedDescription, details: nil))
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
        // 从通知中获取连接对象，如果没有则使用 manager 的连接
        let connection: NEVPNConnection
        if let notifConnection = notification.object as? NEVPNConnection {
            connection = notifConnection
        } else if let manager = self.manager {
            connection = manager.connection
        } else {
            return
        }
        
        let status = connection.status
        let isConnected = (status == .connected)
        
        print("[VPNManager] Status changed: \(status.rawValue) - isConnected: \(isConnected)")
        
        // 发送状态更新
        statusSink?(isConnected)
        
        // 如果连接失败，记录错误
        if status == .invalid {
            print("[VPNManager] VPN status is invalid")
        } else if status == .disconnected {
            print("[VPNManager] VPN disconnected")
        } else if status == .connecting {
            print("[VPNManager] VPN connecting...")
        } else if status == .connected {
            print("[VPNManager] VPN connected successfully")
        } else if status == .reasserting {
            print("[VPNManager] VPN reasserting...")
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
