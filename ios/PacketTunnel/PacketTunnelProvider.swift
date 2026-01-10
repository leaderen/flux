import NetworkExtension

// MARK: - ⚠️ IMPORTANT SETUP INSTRUCTIONS
// 1. Open project in Xcode (`ios/Runner.xcworkspace`)
// 2. File -> New -> Target -> Network Extension
// 3. Product Name: "PacketTunnel" (Language: Swift)
// 4. Finish. If asked to activate scheme, say "Cancel" or "Activate" (doesn't matter much).
// 5. Replace the content of the generated `PacketTunnelProvider.swift` (in the PacketTunnel folder) with this code.
// 6. ⚠️ You MUST link your V2Core framework (e.g. LibXray.xcframework) to the PacketTunnel Target in "Frameworks and Libraries".
// 7. Enable "App Groups" capability for both Runner and PacketTunnel targets if you need to share files (optional for basic memory config).

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    // MARK: - Xray Core Integration
    // Uncomment and implement when Xray core is integrated
    /*
    private var xrayCore: LibXray?
    */

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // 1. Retrieve config from Provider Configuration
        guard let conf = self.protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfig = conf.providerConfiguration,
              let configStr = providerConfig["config"] as? String else {
            let error = NSError(
                domain: "com.flux.app",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Missing VPN configuration"]
            )
            NSLog("[Flux] ❌ Error: Missing VPN configuration")
            completionHandler(error)
            return
        }
        
        NSLog("[Flux] 📋 Starting Tunnel with config length: \(configStr.count)")
        
        // 2. Validate config format
        guard let configData = configStr.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: configData) else {
            let error = NSError(
                domain: "com.flux.app",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON configuration"]
            )
            NSLog("[Flux] ❌ Error: Invalid JSON configuration")
            completionHandler(error)
            return
        }
        
        NSLog("[Flux] ✅ Config format is valid JSON")
        NSLog("[Flux] 📄 Config preview: \(String(configStr.prefix(200)))...")
        
        // 3. Start V2Ray/Xray Core
        // ⚠️ IMPORTANT: You need to integrate Xray core library (e.g. LibXray.xcframework)
        // The current implementation only sets up the network interface but doesn't start the proxy core
        // This means the VPN tunnel will be created but traffic won't be proxied
        /*
        do {
            // Initialize Xray core
            xrayCore = LibXray()
            
            // Start Xray with configuration
            try xrayCore?.start(config: configStr)
            NSLog("[Flux] ✅ Xray core started successfully")
        } catch {
            NSLog("[Flux] ❌ Failed to start Xray core: \(error.localizedDescription)")
            completionHandler(error)
            return
        }
        */
        NSLog("[Flux] ⚠️ WARNING: Xray core not integrated - VPN will not proxy traffic")
        NSLog("[Flux] ⚠️ The tunnel will be created but traffic won't be proxied")

        // 4. Configure Network Settings (Tun2Socks)
        // This sets up the virtual interface
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        
        let ipv4Settings = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.0"])
        // Route all traffic through the tunnel
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        // DNS Settings
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "1.1.1.1"])
        dnsSettings.matchDomains = [""] // Capture all DNS queries
        settings.dnsSettings = dnsSettings
        
        settings.mtu = 1500
        
        NSLog("[Flux] 🔧 Applying tunnel network settings...")
        self.setTunnelNetworkSettings(settings) { error in
            if let error = error {
                NSLog("[Flux] ❌ Failed to set tunnel settings: \(error.localizedDescription)")
                completionHandler(error)
            } else {
                NSLog("[Flux] ✅ Tunnel settings applied successfully")
                NSLog("[Flux] 📡 VPN tunnel interface created")
                // Note: Without Xray core, the tunnel will be created but won't proxy traffic
                // The completion handler should be called after Xray core is started
                completionHandler(nil)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("[Flux] 🛑 Stopping Tunnel (reason: \(reason.rawValue))")
        
        // Stop V2Ray/Xray Core
        /*
        xrayCore?.stop()
        xrayCore = nil
        NSLog("[Flux] ✅ Xray core stopped")
        */
        
        NSLog("[Flux] ✅ Tunnel stopped")
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Use this to communicate with main app if needed
        NSLog("[Flux] 📨 Received app message: \(messageData.count) bytes")
        completionHandler?(nil)
    }
    
    // MARK: - Helper Methods
    
    /// Validate Xray configuration
    private func validateConfig(_ configStr: String) -> Bool {
        guard let configData = configStr.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] else {
            return false
        }
        
        // Check for required fields
        guard config["outbounds"] != nil else {
            NSLog("[Flux] ⚠️ Config validation: Missing 'outbounds'")
            return false
        }
        
        NSLog("[Flux] ✅ Config validation passed")
        return true
    }
}

