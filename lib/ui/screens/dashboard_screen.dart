import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/nodes_provider.dart';
import '../../providers/traffic_provider.dart';
import '../../providers/vpn_provider.dart';
import '../components/glass_card.dart';
import '../components/oled_power_button.dart';
import '../components/traffic_hud.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback onNavigateToNodes;

  const DashboardScreen({
    super.key,
    required this.onNavigateToNodes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpnStatus = ref.watch(vpnStatusProvider);
    final traffic = ref.watch(trafficStatsProvider);
    final monthlyTraffic = ref.watch(monthlyTrafficProvider);
    final activeNode = ref.watch(activeNodeProvider);
    final vpnController = ref.read(vpnControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'NYX',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: const Text(
                'CORE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: AppColors.textSecondary),
            tooltip: 'Ping Test',
            onPressed: () {
              if (activeNode != null) {
                ref.read(nodesProvider.notifier).testNodeLatency(activeNode.id);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
            onPressed: onNavigateToNodes,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Central OLED Power Switch
              Expanded(
                flex: 4,
                child: Center(
                  child: OledPowerButton(
                    status: vpnStatus,
                    onTap: () => vpnController.toggle(),
                  ),
                ),
              ),

              // Live Traffic HUD with Monthly Data
              TrafficHud(
                stats: traffic,
                monthlyTraffic: monthlyTraffic,
              ),
              const SizedBox(height: 16),

              // Active Node Selector Card
              GlassCard(
                onTap: onNavigateToNodes,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dns_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ACTIVE OUTBOUND',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            activeNode?.name ?? 'No Node Selected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activeNode != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          Formatters.formatLatency(activeNode.latencyMs),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.connected,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
