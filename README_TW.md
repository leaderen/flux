[English](README_EN.md) | [简体中文](README.md) | 繁體中文 | [日本語](README_JA.md) | [한국어](README_KO.md) | [Русский](README_RU.md) | [हिन्दी](README_HI.md)

# Flux - 開源 V2Board 客戶端

**Flux** 是一個完美適配 [V2Board](https://github.com/wyx2685/v2board) 的跨平台客戶端。

我們致力於提供最簡單、最流暢的對接體驗。如果您正在運營 V2Board 面板，Flux 是您客戶端的最佳選擇。

---

## 📞 客製化與商業支援

如果您需要：
-   🔥 **修改 App 名稱和 Logo**
-   🎨 **客製專屬 UI 主題**
-   🚀 **增加進階功能**

請透過 Telegram 聯繫我：👉 **[@xiaoxiaonihaoya](https://t.me/xiaoxiaonihaoya)**

---

## 🎉 核心優勢

-   **極簡對接**: 真的只需要**一步**！修改 API 網址即可直接使用，告別繁瑣設定。
-   **多種協定**: 支援 VLESS, VMess, Trojan, Shadowsocks, WireGuard, TUIC, Hysteria2。
-   **全平台支援**: Android, iOS, Windows, macOS, Linux 全覆蓋。
-   **開源透明**: 程式碼完全開源，安全可控，隨時客製。
-   **多語言支持**: 支持英語、簡體中文、繁體中文、日語、韓語、俄語、西班牙語等多種語言。

---

## 🛠 支援協定 / Supported Protocols

✅ **已驗證平台 (Verified on Android & Windows)**:
- **Hysteria2**: 極速抗封鎖協定
- **VLESS** (Vision / Reality)
- **VMess** (TCP / WebSocket)
- **Trojan**
- **Shadowsocks** (AEAD)
- **WireGuard**
- **TUIC**

---

## 🌐 OSS 遠端配置 (網域名稱下發)

Flux 支援透過 OSS/CDN 下發遠端配置，實現 **網域名稱自動切換**、**版本更新通知**、**公告推播** 等功能。

### 配置方法

1. 將以下 JSON 設定檔上傳到您的 OSS/CDN（如阿里雲 OSS、Cloudflare R2、GitHub Raw 等）
2. 在 `lib/services/remote_config_service.dart` 中設定 `_ossUrls` 清單

### JSON 配置格式

```json
{
  "config_version": 1,
  "domains": [
    "https://api1.example.com/api/v1",
    "https://api2.example.com/api/v1",
    "https://backup.example.com/api/v1"
  ],
  "backup_subscription": "https://backup-sub.example.com/sub",
  
  "announcement": {
    "enabled": true,
    "title": "系統公告",
    "content": "春節期間正常服務，祝大家新年快樂！",
    "type": "info"
  },
  
  "maintenance": {
    "enabled": false,
    "message": "系統維護中，預計2小時後恢復"
  },
  
  "update": {
    "min_version": "1.0.0",
    "latest": {
      "android": { "version": "1.2.0", "url": "https://example.com/flux-1.2.0.apk", "force": false },
      "ios": { "version": "1.2.0", "url": "https://apps.apple.com/app/id123456", "force": false },
      "windows": { "version": "1.2.0", "url": "https://example.com/flux-1.2.0-win.zip", "force": false },
      "macos": { "version": "1.2.0", "url": "https://example.com/flux-1.2.0-mac.dmg", "force": false },
      "linux": { "version": "1.2.0", "url": "https://example.com/flux-1.2.0-linux.tar.gz", "force": false }
    },
    "changelog": "1. 新增 WireGuard 和 TUIC 協定支援\n2. 修復若干 bug"
  },
  
  "contact": {
    "telegram": "https://t.me/your_group",
    "website": "https://yoursite.com"
  },
  
  "features": {
    "invite_enabled": true,
    "purchase_enabled": true,
    "ssr_enabled": false
  },
  
  "recommended_nodes": ["香港01", "日本02"]
}
```

### 欄位說明

| 欄位 | 說明 |
|------|------|
| `config_version` | 配置版本號，用於判斷是否需要更新快取 |
| `domains` | API 網域名稱清單，按優先順序排序，自動測試可用性 |
| `backup_subscription` | 備用訂閱地址 |
| `announcement` | 公告配置，`type` 可選 `info`/`warning`/`error` |
| `maintenance` | 維護模式，啟用時阻止用戶操作 |
| `update` | 版本更新資訊，`force: true` 表示強制更新 |
| `min_version` | 最低支援版本，低於此版本強制更新 |
| `contact` | 客服聯繫方式 |
| `features` | 功能開關 |
| `recommended_nodes` | 推薦節點名稱清單 |

---

## 🚀 快速開始

### 1. 下載程式碼

```bash
git clone https://github.com/flux-apphub/flux.git
cd flux
```

### 2. 替換 API 網址 (核心步驟)

開啟 `lib/services/api_config.dart`，修改：

```dart
Future<String> getBaseUrl() async {
  // 改為您的面板網址
  return 'https://您的面板網域.com/api/v1'; 
}
```

### 3. 修改 App ID

將 `com.example.yourapp` 替換為您自己的 App ID：

| 平台 | 檔案路徑 | 修改項 |
|------|---------|--------|
| **Android** | `android/app/build.gradle.kts` | `applicationId` 和 `namespace` |
| **iOS** | `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` |
| **macOS** | `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_BUNDLE_IDENTIFIER` |
| **Linux** | `linux/CMakeLists.txt` | `APPLICATION_ID` |
| **Windows** | `pubspec.yaml` | `msix_config` 下的 `identity_name` |

### 4. 替換應用程式圖示

1. 準備一張 **1024x1024** 的 PNG 圖片
2. 放到 `assets/images/app_icon.png`
3. 執行：
   ```bash
   flutter pub run flutter_launcher_icons
   ```

### 5. 開始打包

```bash
# Android
flutter build apk --release

# iOS
flutter build ipa

# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

---

## 🔗 相關專案

### 核心代理引擎
-   [Xray-core](https://github.com/XTLS/Xray-core): 本專案使用的核心代理引擎
-   [V2Ray-core](https://github.com/v2fly/v2ray-core): 經典的代理核心
-   [Hysteria](https://github.com/apernet/hysteria): 強大的抗封鎖代理協定

### 面板 & 管理
-   [V2Board](https://github.com/wyx2685/v2board): 強大的 V2Ray 面板

---

## 💬 加入社群

- **Telegram 群組**: [https://t.me/+62Otr015kSs1YmNk](https://t.me/+62Otr015kSs1YmNk)

---

**Flux Open Source** - Make Connection Simple.
