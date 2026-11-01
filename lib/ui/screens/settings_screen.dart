import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_routing.dart';
import '../../providers/app_routing_provider.dart';
import '../../providers/custom_rules_provider.dart';
import '../../providers/proxy_groups_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/traffic_provider.dart';
import '../../providers/vpn_provider.dart';
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
    _detectLocalIp();
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

  @override
  Widget build(BuildContext context) {
    final storage = ref.read(storageServiceProvider);
    final appRouting = ref.watch(appRoutingProvider);
    final customRules = ref.watch(customRulesProvider);
    final proxyGroups = ref.watch(proxyGroupsProvider);
    final subscriptions = ref.watch(subscriptionsProvider);
    final monthly = ref.watch(monthlyTrafficProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PREFERENCES'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildSectionHeader('TRAFFIC ROUTING & SPLIT-TUNNELING'),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _NavigationTile(
                  icon: Icons.apps_rounded,
                  iconColor: AppColors.accent,
                  title: 'App Split Tunneling',
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
                  title: 'Custom Routing Rules',
                  subtitle: '${customRules.length} rules (App, Domain, Prefix to Nodes)',
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
                  title: 'Custom Proxy Groups',
                  subtitle: '${proxyGroups.length} groups (Auto-Test, Selector, Fallback)',
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
                  title: 'Airport Subscriptions',
                  subtitle: '${subscriptions.length} subscriptions (Auto-silent sync daily)',
                  onTap: () => _showSubscriptionsModal(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('LAN SHARING & NETWORK ACCELERATION'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Share Proxy with Local Network (LAN)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Allows Switch, PS5, TV, and iPad on local Wi-Fi to use proxy',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                              SnackBar(content: Text('Copied $_localIp:2080 to clipboard')),
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

          _buildSectionHeader('MONTHLY TRAFFIC BUDGET'),
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
                          '${monthly.period} Usage: ${Formatters.formatBytes(monthly.usedBytes)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          monthly.hasQuota ? 'Limit: ${monthly.quotaGigabytes} GB / month' : 'No monthly limit set',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    DropdownButton<int>(
                      value: monthly.quotaGigabytes,
                      dropdownColor: AppColors.surfaceElevated,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Unlimited', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 50, child: Text('50 GB', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 100, child: Text('100 GB', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 200, child: Text('200 GB', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 500, child: Text('500 GB', style: TextStyle(fontSize: 13))),
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

          _buildSectionHeader('GLOBAL BEHAVIOR & AUTOMATION'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Bypass Mainland China',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Route domestic websites & private IPs directly',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                  title: const Text(
                    'Auto-Connect on Launch',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Start proxy tunnel immediately when app opens',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                  title: const Text(
                    'Auto-Sync Subscriptions Daily',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Silently refresh airport nodes every 24 hours',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                    title: const Text(
                      'Close Window to System Tray',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Keep Nyx running in the Windows taskbar tray when clicking X',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    activeColor: AppColors.accent,
                    value: _closeToTray,
                    onChanged: (val) {
                      setState(() => _closeToTray = val);
                      storage.setCloseToTray(val);
                    },
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
