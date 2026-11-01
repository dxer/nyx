# Nyx (sing-box VPN)

> *Silent speed in pure darkness.*  
> A lightweight, power-efficient, OLED hyper-minimalist cross-platform VPN client based on the **sing-box (`libbox`)** core.

---

## 🌟 Highlights & Features

- **Ultra-Lightweight & Battery Saving**: Pure OLED Black theme (`#000000`). UI runtime sleeps when in background; only native `VpnService` with compiled Go sing-box runs in background (~25MB RAM, near-zero CPU drain).
- **Custom App Split-Tunneling (应用分流)**:
  - Whitelist Mode: Only selected applications use proxy.
  - Blacklist Mode: Selected domestic / local applications bypass VPN directly.
  - Built-in search & system package filter toggle.
- **Custom Routing Rules (自定义分流规则)**:
  - Match criteria: Domain Suffix, Domain Keyword, Exact Domain, IP CIDR, GeoSite, GeoIP.
  - Target outbounds: Proxy tunnel, Direct connection, Block/Drop, or routed directly to any custom proxy group.
- **Custom Proxy Groups (自定义代理组)**:
  - **Auto URL-Test**: Automatically benchmarks and routes traffic through the lowest latency node.
  - **Manual Selector**: User switches active node on the fly.
  - **Failover Fallback**: Automatically switches to backup node if primary node times out.
- **Cross-Platform Architecture**: Unified Flutter 3.x UI codebase targeting **Android, iOS, Windows, macOS, and Linux**.
- **Modern Protocol Matrix**: Full support for VLESS (Reality/Vision), VMess, Shadowsocks, Trojan, Hysteria 2, and TUIC.
- **Resilient URL Parsing**: Robust percent-encoding sanitizer preventing crashes on special characters or tags (`HK 50%`).
- **Telemetry HUD**: Real-time dual-channel uplink & downlink throughput gauge and cumulative data transfer counter.
- **Clean State Management**: Powered by **Riverpod 2.x**, guaranteeing reactivity, testability, and zero memory leaks.

---

## 📁 Architecture & Project Structure

```
nyx/
├── .github/workflows/
│   └── build-apk.yml              # Automated cloud compilation for Nyx release APKs
├── lib/
│   ├── main.dart                  # App entry point & Riverpod Scope initialization
│   ├── app.dart                   # Global Navigation Shell & Bottom bar (NyxApp)
│   ├── core/
│   │   ├── theme/                 # OLED Hyper-Minimalist design system (AppColors, AppTheme)
│   │   └── utils/                 # Safe URL decoding, byte formatters
│   ├── models/                    # Data models:
│   │   ├── app_routing.dart       # AppInfo, AppRoutingMode, AppRoutingConfig
│   │   ├── custom_rule.dart       # RuleType, RuleOutbound, CustomRule
│   │   ├── proxy_group.dart       # ProxyGroupType, ProxyGroup
│   │   ├── proxy_node.dart        # ProxyNode & configuration map
│   │   ├── traffic_stats.dart     # Uplink/Downlink throughput
│   │   └── connection_state.dart  # VPN status lifecycle
│   ├── services/
│   │   ├── parser/                # Protocol link parsers (VLESS, Trojan, SS, Hy2)
│   │   ├── singbox/               # Dynamic sing-box JSON generator & Platform bridge
│   │   └── storage/               # SharedPreferences persistent cache
│   ├── providers/                 # Riverpod business logic:
│   │   ├── app_routing_provider.dart
│   │   ├── custom_rules_provider.dart
│   │   ├── proxy_groups_provider.dart
│   │   ├── nodes_provider.dart
│   │   ├── vpn_provider.dart
│   │   └── traffic_provider.dart
│   └── ui/
│       ├── components/            # GlassCard, OLED Power Button, Traffic HUD, Node Card
│       └── screens/               # Dashboard, Nodes Screen, Settings, App Routing, Custom Rules, Proxy Groups
└── android/                       # Native Android VpnService & MethodChannel IPC glue
```

---

## 🛠️ How to Build Your APK

### Option A: Zero-Config Cloud Build (GitHub Actions)
You don't need Flutter or Android Studio installed locally on your computer:
1. Create a private repository on GitHub (e.g. `nyx-vpn`).
2. Push this repository to GitHub:
   ```bash
   cd nyx
   git remote add origin https://github.com/<your-username>/nyx-vpn.git
   git branch -M main
   git push -u origin main
   ```
3. GitHub Actions will automatically trigger `.github/workflows/build-apk.yml`.
4. In ~3 minutes, download your ready-to-install `Nyx-Release-APKs` directly from the **Actions -> Artifacts** tab!

### Option B: Local Build
```bash
# 1. Install dependencies
flutter pub get

# 2. Build Release APK (Per-ABI split generates ~20MB lean APKs)
flutter build apk --split-per-abi --release

# 3. Locate compiled APKs
# Generated at: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```
