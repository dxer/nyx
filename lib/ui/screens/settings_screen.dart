import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_routing.dart';
import '../../providers/app_routing_provider.dart';
import '../../providers/custom_rules_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/proxy_groups_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/traffic_provider.dart';
import '../../providers/vpn_provider.dart';
import '../../services/system_proxy/windows_proxy_service.dart';
import '../components/glass_card.dart';
import 'app_routing_screen.dart';
import 'custom_rules_screen.dart';
import 'proxy_groups_screen.dart';
import 'subscriptions_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _bypassChina;
  late bool _autoConnect;
  late bool _allowLan;
  late bool _closeToTray;
  late bool _autoUpdateSubs;
  late bool _launchOnStartup;
  bool _isBatteryExempt = false;
  String _localIp = '127.0.0.1';

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageServiceProvider);
    _bypassChina = storage.getBypassChina();
    _autoConnect = storage.getAutoConnect();
    _allowLan = storage.getAllowLan();
    _closeToTray = storage.getCloseToTray();
    _autoUpdateSubs = storage.getAutoUpdateSubscriptions();
    _launchOnStartup = storage.getLaunchOnStartup();
    _detectLocalIp();
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.nyx.vpn/service');
        final exempt = await channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
        if (mounted) setState(() => _isBatteryExempt = exempt ?? false);
      } catch (_) {}
    }
  }

  Future<void> _requestBatteryOptimization() async {
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.nyx.vpn/service');
        await channel.invokeMethod('requestIgnoreBatteryOptimizations');
        await Future.delayed(const Duration(seconds: 1));
        _checkBatteryOptimization();
      } catch (_) {}
    }
  }

  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            if (mounted) setState(() => _localIp = addr.address);
            return;
          }
        }
      }
    } catch (_) {}
  }

  void _showSubscriptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SubscriptionsSheet(),
    );
  }

  void _showLanguageModal(BuildContext context) {
    final tr = context.tr;
    final currentCode = ref.read(localeProvider.notifier).currentLanguageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language_rounded, color: AppColors.accent, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      tr.languageTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  ctx,
                  title: tr.languageSystem,
                  subtitle: tr.isZh ? '跟随系统语言设置' : 'Auto-match system language',
                  code: 'system',
                  isSelected: currentCode == 'system',
                ),
                const Divider(height: 1),
                _buildLanguageOption(
                  ctx,
                  title: '简体中文',
                  subtitle: 'Chinese (Simplified)',
                  code: 'zh',
                  isSelected: currentCode == 'zh',
                ),
                const Divider(height: 1),
                _buildLanguageOption(
                  ctx,
                  title: 'English',
                  subtitle: 'English (US)',
                  code: 'en',
                  isSelected: currentCode == 'en',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext ctx, {
    required String title,
    required String subtitle,
    required String code,
    required bool isSelected,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 22)
          : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLanguage(code);
        Navigator.pop(ctx);
      },
    );
  }

  String _getLanguageSubtitle(String code, AppLocalizations tr) {
    if (code == 'zh') return tr.languageZh;
    if (code == 'en') return tr.languageEn;
    return tr.languageSystem;
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final currentLangCode = ref.watch(localeProvider.notifier).currentLanguageCode;
    final storage = ref.read(storageServiceProvider);
    final appRouting = ref.watch(appRoutingProvider);
    final customRules = ref.watch(customRulesProvider);
    final proxyGroups = ref.watch(proxyGroupsProvider);
    final subscriptions = ref.watch(subscriptionsProvider);
    final monthly = ref.watch(monthlyTrafficProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr.settingsTitle.toUpperCase()),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildSectionHeader(tr.generalSection.toUpperCase()),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _NavigationTile(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.accent,
                  title: tr.languageTitle,
                  subtitle: _getLanguageSubtitle(currentLangCode, tr),
                  onTap: () => _showLanguageModal(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(tr.routingSection.toUpperCase()),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _NavigationTile(
                  icon: Icons.apps_rounded,
                  iconColor: AppColors.accent,
                  title: tr.appRoutingTitle,
                  subtitle: _formatAppRoutingSubtitle(appRouting),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AppRoutingScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _NavigationTile(
                  icon: Icons.alt_route_rounded,
                  iconColor: AppColors.connected,
                  title: tr.customRulesTitle,
                  subtitle: '${customRules.length} ${tr.isZh ? "条规则 (应用/域名/前缀定向路由)" : "rules (App, Domain, Prefix to Nodes)"}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CustomRulesScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _NavigationTile(
                  icon: Icons.account_tree_rounded,
                  iconColor: AppColors.connecting,
                  title: tr.proxyGroupsTitle,
                  subtitle: '${proxyGroups.length} ${tr.isZh ? "个分组 (自动优选/手动选择/故障转移)" : "groups (Auto-Test, Selector, Fallback)"}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProxyGroupsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _NavigationTile(
                  icon: Icons.cloud_sync_rounded,
                  iconColor: AppColors.accent,
                  title: tr.subscriptionsTitle,
                  subtitle: '${subscriptions.length} ${tr.isZh ? "个订阅 (支持静默自动同步)" : "subscriptions (Auto-silent sync daily)"}',
                  onTap: () => _showSubscriptionsModal(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(tr.networkSection.toUpperCase()),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tr.lanSharingTitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    tr.lanSharingSubtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  activeColor: AppColors.accent,
                  value: _allowLan,
                  onChanged: (val) {
                    setState(() => _allowLan = val);
                    storage.setAllowLan(val);
                    ref.read(vpnControllerProvider).reloadConfig();
                  },
                ),
                if (_allowLan) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.connected.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LAN PROXY HOST & PORT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_localIp:2080',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.connected),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: AppColors.accent, size: 20),
                          tooltip: 'Copy Proxy Address',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '$_localIp:2080'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${tr.ipCopied}: $_localIp:2080')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Set HTTP / SOCKS5 proxy on your game console or TV to this IP and port.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(tr.monthlyTrafficTitle.toUpperCase()),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${monthly.period} ${tr.monthlyUsage}: ${Formatters.formatBytes(monthly.usedBytes)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          monthly.hasQuota ? '${tr.isZh ? "限额" : "Limit"}: ${monthly.quotaGigabytes} GB / ${tr.isZh ? "月" : "month"}' : tr.unlimited,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    DropdownButton<int>(
                      value: monthly.quotaGigabytes,
                      dropdownColor: AppColors.surfaceElevated,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(value: 0, child: Text(tr.unlimited, style: const TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 50, child: Text('50 GB', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 100, child: Text('100 GB', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 200, child: Text('200 GB', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 500, child: Text('500 GB', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(monthlyTrafficProvider.notifier).setQuotaGigabytes(val);
                        }
                      },
                    ),
                  ],
                ),
                if (monthly.hasQuota) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: monthly.progress,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceHighlight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        monthly.isWarning ? AppColors.connecting : AppColors.connected,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(tr.platformSection.toUpperCase()),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tr.isZh ? '绕过大陆局域网及域名' : 'Bypass Mainland China',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    tr.isZh ? '国内网站与私有 IP 直连，降低延迟并节省节点流量' : 'Route domestic websites & private IPs directly',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  activeColor: AppColors.accent,
                  value: _bypassChina,
                  onChanged: (val) {
                    setState(() => _bypassChina = val);
                    storage.setBypassChina(val);
                    ref.read(vpnControllerProvider).reloadConfig();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tr.isZh ? '启动应用时自动连接' : 'Auto-Connect on Launch',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    tr.isZh ? '打开应用后自动激活上次使用的代理节点' : 'Start proxy tunnel immediately when app opens',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  activeColor: AppColors.accent,
                  value: _autoConnect,
                  onChanged: (val) {
                    setState(() => _autoConnect = val);
                    storage.setAutoConnect(val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tr.isZh ? '订阅每日静默自动同步' : 'Auto-Sync Subscriptions Daily',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    tr.isZh ? '每 24 小时在后台自动拉取更新机场节点列表' : 'Silently refresh airport nodes every 24 hours',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  activeColor: AppColors.accent,
                  value: _autoUpdateSubs,
                  onChanged: (val) {
                    setState(() => _autoUpdateSubs = val);
                    storage.setAutoUpdateSubscriptions(val);
                  },
                ),
                if (Platform.isWindows) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tr.isZh ? '关闭窗口时最小化到系统托盘' : 'Close Window to System Tray',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      tr.isZh ? '点击关闭按钮时隐藏到右下角通知区域，不中断代理' : 'Keep Nyx running in the Windows taskbar tray when clicking X',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    activeColor: AppColors.accent,
                    value: _closeToTray,
                    onChanged: (val) {
                      setState(() => _closeToTray = val);
                      storage.setCloseToTray(val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tr.winStartupTitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      tr.winStartupSubtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    activeColor: AppColors.accent,
                    value: _launchOnStartup,
                    onChanged: (val) {
                      setState(() => _launchOnStartup = val);
                      storage.setLaunchOnStartup(val);
                      WindowsProxyService.setLaunchOnStartup(val);
                    },
                  ),
                ],
                if (Platform.isAndroid) ...[
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tr.batteryOptTitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _isBatteryExempt
                          ? (tr.isZh ? '已获得后台长驻保护（系统不会杀进程）' : 'Unrestricted (Protected from system kill)')
                          : (tr.isZh ? '受限（点击加入白名单，避免息屏断连）' : 'Restricted (Tap to exempt from vendor battery saver)'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isBatteryExempt ? AppColors.connected : AppColors.connecting,
                      ),
                    ),
                    trailing: Icon(
                      _isBatteryExempt ? Icons.shield_rounded : Icons.shield_outlined,
                      color: _isBatteryExempt ? AppColors.connected : AppColors.connecting,
                    ),
                    onTap: _requestBatteryOptimization,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('ABOUT CORE & SYSTEM'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: const Column(
              children: [
                _InfoRow(label: 'Client Name', value: 'Nyx'),
                Divider(height: 20),
                _InfoRow(label: 'Client Version', value: 'v1.0.0'),
                Divider(height: 20),
                _InfoRow(label: 'Core Engine', value: 'sing-box v1.13.x (libbox)'),
                Divider(height: 20),
                _InfoRow(label: 'Design Aesthetics', value: 'OLED Pure Black (#000000)'),
                Divider(height: 20),
                _InfoRow(label: 'Build Pipeline', value: 'GitHub Actions Automated CI'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatAppRoutingSubtitle(AppRoutingConfig config) {
    switch (config.mode) {
      case AppRoutingMode.all:
        return 'All installed apps routed through VPN';
      case AppRoutingMode.allowlist:
        return 'Whitelist: Only ${config.selectedPackages.length} selected apps proxy';
      case AppRoutingMode.blocklist:
        return 'Blacklist: ${config.selectedPackages.length} apps bypass proxy directly';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
