[English](README_EN.md) | [简体中文](README.md) | [繁體中文](README_TW.md) | [日本語](README_JA.md) | 한국어 | [Русский](README_RU.md) | [हिन्दी](README_HI.md)

# Flux - 오픈 소스 V2Board 클라이언트

**Flux**는 [V2Board](https://github.com/wyx2685/v2board)에 완벽하게 호환되는 크로스 플랫폼 클라이언트입니다.

가장 간단하고 원활한 통합 경험을 제공하기 위해 노력하고 있습니다. V2Board 패널을 운영 중이시라면, Flux가 최고의 선택입니다.

---

## 📞 커스터마이징 & 상업적 지원

필요하신 경우:
-   🔥 **앱 이름 및 로고 변경**
-   🎨 **커스텀 UI 테마**
-   🚀 **고급 기능 추가**

텔레그램으로 연락주세요: 👉 **[@xiaoxiaonihaoya](https://t.me/xiaoxiaonihaoya)**

---

## 🎉 주요 특징

-   **간편한 통합**: **한 단계**로 완료! API URL만 수정하면 바로 사용 가능.
-   **다양한 프로토콜**: VLESS, VMess, Trojan, Shadowsocks, WireGuard, TUIC, Hysteria2 지원.
-   **크로스 플랫폼**: Android, iOS, Windows, macOS, Linux 지원.
-   **오픈 소스**: 완전 오픈 소스, 안전하고 커스터마이징 가능.
-   **다국어 지원**: 영어, 중국어, 일본어, 한국어, 러시아어, 스페인어 등 다양한 언어 지원。

---

## 🛠 지원 프로토콜

✅ **검증된 플랫폼 (Android & Windows)**:
- **Hysteria2**: 빠른 검열 우회 프로토콜
- **VLESS** (Vision / Reality)
- **VMess** (TCP / WebSocket)
- **Trojan**
- **Shadowsocks** (AEAD)
- **WireGuard**
- **TUIC**

---

## 🌐 OSS 원격 구성

Flux는 OSS/CDN을 통한 원격 구성을 지원하여 **자동 도메인 장애 조치**, **버전 업데이트 알림**, **공지사항** 등을 제공합니다.

### 설정 방법

1. JSON 설정 파일을 OSS/CDN(Alibaba Cloud OSS, Cloudflare R2, GitHub Raw 등)에 업로드합니다.
2. `lib/services/remote_config_service.dart`에서 `_ossUrls`를 설정합니다.

### JSON 구성 형식

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
    "title": "시스템 공지",
    "content": "서비스가 정상적으로 운영 중입니다.",
    "type": "info"
  },
  
  "maintenance": {
    "enabled": false,
    "message": "시스템 점검 중입니다"
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
    "changelog": "1. WireGuard 및 TUIC 지원 추가\n2. 버그 수정"
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

### 필드 설명

| 필드 | 설명 |
|------|------|
| `config_version` | 캐시 검증을 위한 구성 버전 번호 |
| `domains` | API 도메인 목록(우선순위 순), 가용성 자동 테스트 |
| `backup_subscription` | 백업 구독 URL |
| `announcement` | 공지 설정, `type`은 `info`/`warning`/`error` 가능 |
| `maintenance` | 유지 관리 모드, 활성화 시 사용자 작업 차단 |
| `update` | 버전 업데이트 정보, `force: true`는 강제 업데이트 |
| `min_version` | 최소 지원 버전, 구버전은 강제 업데이트 필요 |
| `contact` | 고객 지원 링크 |
| `features` | 기능 토글 |
| `recommended_nodes` | 추천 노드 이름 목록 |

---

## 🚀 빠른 시작

### 1. 저장소 클론

```bash
git clone https://github.com/flux-apphub/flux.git
cd flux
```

### 2. API URL 설정 (필수)

`lib/services/api_config.dart`를 열어 수정:

```dart
Future<String> getBaseUrl() async {
  // 패널 URL로 변경
  return 'https://your-panel-domain.com/api/v1'; 
}
```

### 3. 앱 ID 변경

`com.example.yourapp`을 자신의 App ID로 교체:

| 플랫폼 | 파일 경로 | 변경 항목 |
|--------|-----------|----------|
| **Android** | `android/app/build.gradle.kts` | `applicationId` 및 `namespace` |
| **iOS** | `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` |
| **macOS** | `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_BUNDLE_IDENTIFIER` |
| **Linux** | `linux/CMakeLists.txt` | `APPLICATION_ID` |
| **Windows** | `pubspec.yaml` | `msix_config`의 `identity_name` |

### 4. 앱 아이콘 교체

1. **1024x1024** PNG 이미지 준비
2. `assets/images/app_icon.png`에 배치
3. 실행:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

### 5. 빌드

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

## 🔗 관련 프로젝트

### 코어 프록시 엔진
-   [Xray-core](https://github.com/XTLS/Xray-core): 이 프로젝트에서 사용하는 코어 엔진
-   [V2Ray-core](https://github.com/v2fly/v2ray-core): 클래식 프록시 코어
-   [Hysteria](https://github.com/apernet/hysteria): 강력한 검열 우회 프로토콜

### 패널 & 관리
-   [V2Board](https://github.com/wyx2685/v2board): 강력한 V2Ray 패널

---

## 💬 커뮤니티 참여

- **텔레그램 그룹**: [https://t.me/+62Otr015kSs1YmNk](https://t.me/+62Otr015kSs1YmNk)

---

**Flux Open Source** - Make Connection Simple.
