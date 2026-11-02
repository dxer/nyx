import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/monthly_traffic.dart';
import '../../models/traffic_stats.dart';

class TrafficHud extends StatelessWidget {
  final TrafficStats stats;
  final MonthlyTraffic? monthlyTraffic;

  const TrafficHud({
    super.key,
    required this.stats,
    this.monthlyTraffic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.connected,
                  label: context.tr.downlink,
                  speed: Formatters.formatSpeed(stats.downlinkSpeed),
                  total: Formatters.formatBytes(stats.downlinkTotal),
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: AppColors.borderSubtle,
              ),
              Expanded(
                child: _buildMetric(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: AppColors.accent,
                  label: context.tr.uplink,
                  speed: Formatters.formatSpeed(stats.uplinkSpeed),
                  total: Formatters.formatBytes(stats.uplinkTotal),
                ),
              ),
            ],
          ),
          if (monthlyTraffic != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _buildMonthlyBar(monthlyTraffic!),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyBar(MonthlyTraffic monthly) {
    final usedStr = Formatters.formatBytes(monthly.usedBytes);
    final quotaStr = monthly.hasQuota ? '${monthly.quotaGigabytes} GB' : 'Unlimited';
    final progress = monthly.progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${monthly.period} USAGE',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            Text(
              monthly.hasQuota ? '$usedStr / $quotaStr (${(progress * 100).toStringAsFixed(1)}%)' : '$usedStr used',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: monthly.isWarning ? AppColors.connecting : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (monthly.hasQuota) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation<Color>(
                monthly.isExceeded
                    ? AppColors.error
                    : (monthly.isWarning ? AppColors.connecting : AppColors.connected),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String speed,
    required String total,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              speed,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$label: $total',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
