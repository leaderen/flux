[English](README_EN.md) | [简体中文](README.md) | [繁體中文](README_TW.md) | 日本語 | [한국어](README_KO.md) | [Русский](README_RU.md) | [हिन्दी](README_HI.md)

# Flux - オープンソース V2Board クライアント

**Flux** は [V2Board](https://github.com/wyx2685/v2board) に完璧に対応したクロスプラットフォームクライアントです。

最もシンプルでスムーズな統合体験を提供することに取り組んでいます。V2Board パネルを運営している場合、Flux は最適な選択です。

---

## 📞 カスタマイズ & 商用サポート

以下のサービスが必要な場合：
-   🔥 **アプリ名とロゴの変更**
-   🎨 **カスタム UI テーマ**
-   🚀 **高度な機能の追加**

Telegram でお問い合わせください：👉 **[@xiaoxiaonihaoya](https://t.me/xiaoxiaonihaoya)**

---

## 🎉 主な特徴

-   **シンプルな統合**: たった**一歩**で完了！API URL を変更するだけで使用開始。
-   **複数のプロトコル**: VLESS, VMess, Trojan, Shadowsocks, WireGuard, TUIC, Hysteria2 をサポート。
-   **クロスプラットフォーム**: Android, iOS, Windows, macOS, Linux に対応。
-   **オープンソース**: 完全にオープンソースで、安全かつカスタマイズ可能。
-   **多言語サポート**: 英語、中国語、日本語、韓国語、ロシア語、スペイン語などをサポート。

---

## 🛠 サポートされているプロトコル

✅ **検証済みプラットフォーム (Android & Windows)**:
- **Hysteria2**: 高速な検閲回避プロトコル
- **VLESS** (Vision / Reality)
- **VMess** (TCP / WebSocket)
- **Trojan**
- **Shadowsocks** (AEAD)
- **WireGuard**
- **TUIC**

---

## 🌐 OSS リモート設定

Flux は OSS/CDN 経由のリモート設定をサポートしており、**ドメインの自動フェイルオーバー**、**バージョン更新**、**お知らせ** などを実現します。

### 設定方法

1. JSON 設定ファイルを OSS/CDN (Alibaba Cloud OSS, Cloudflare R2, GitHub Raw など) にアップロードします。
2. `lib/services/remote_config_service.dart` の `_ossUrls` を設定します。

### JSON 設定フォーマット

```json
{
  "config_version": 1,
  "domains": [
    "https://api1.example.com/api/v1",
    "https://api2.example.com/api/v1"
  ],
  "backup_subscription": "https://backup-sub.example.com/sub",
  
  "announcement": {
    "enabled": true,
    "title": "システム通知",
    "content": "サービスは正常に稼働しています。",
    "type": "info"
  },
  
  "maintenance": {
    "enabled": false,
    "message": "システムメンテナンス中"
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
    "changelog": "1. WireGuard と TUIC のサポートを追加\n2. バグ修正"
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
  
  "recommended_nodes": ["HongKong01", "Japan02"]
}
```

### フィールド説明

| フィールド | 説明 |
|------------|------|
| `config_version` | キャッシュ検証用の設定バージョン番号 |
| `domains` | API ドメインリスト（優先順位順）、可用性を自動テスト |
| `backup_subscription` | バックアップ用サブスクリプション URL |
| `announcement` | お知らせ設定、`type` は `info`/`warning`/`error` が可能 |
| `maintenance` | メンテナンスモード、有効時はユーザー操作をブロック |
| `update` | バージョン更新情報、`force: true` で強制更新 |
| `min_version` | 最低サポートバージョン、これより古いバージョンは強制更新 |
| `contact` | カスタマーサポートリンク |
| `features` | 機能トグル |
| `recommended_nodes` | 推奨ノード名リスト |

---

## 🚀 クイックスタート

### 1. リポジトリのクローン

```bash
git clone https://github.com/flux-apphub/flux.git
cd flux
```

### 2. API URL の設定 (重要)

`lib/services/api_config.dart` を開いて変更：

```dart
Future<String> getBaseUrl() async {
  // パネルの URL に変更
  return 'https://your-panel-domain.com/api/v1'; 
}
```

### 3. アプリ ID の変更

`com.example.yourapp` を自分の App ID に置き換え：

| プラットフォーム | ファイルパス | 変更項目 |
|-----------------|-------------|----------|
| **Android** | `android/app/build.gradle.kts` | `applicationId` と `namespace` |
| **iOS** | `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` |
| **macOS** | `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_BUNDLE_IDENTIFIER` |
| **Linux** | `linux/CMakeLists.txt` | `APPLICATION_ID` |
| **Windows** | `pubspec.yaml` | `msix_config` の `identity_name` |

### 4. アプリアイコンの置き換え

1. **1024x1024** の PNG 画像を準備
2. `assets/images/app_icon.png` に配置
3. 実行：
   ```bash
   flutter pub run flutter_launcher_icons
   ```

### 5. ビルド

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

## 🔗 関連プロジェクト

### コアプロキシエンジン
-   [Xray-core](https://github.com/XTLS/Xray-core): このプロジェクトで使用されているコアエンジン
-   [V2Ray-core](https://github.com/v2fly/v2ray-core): クラシックなプロキシコア
-   [Hysteria](https://github.com/apernet/hysteria): 強力な検閲回避プロトコル

### パネル & 管理
-   [V2Board](https://github.com/wyx2685/v2board): 強力な V2Ray パネル

---

## 💬 コミュニティに参加

- **Telegram グループ**: [https://t.me/+62Otr015kSs1YmNk](https://t.me/+62Otr015kSs1YmNk)

---

**Flux Open Source** - Make Connection Simple.
