import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/proxy_node.dart';
import 'glass_card.dart';

class NodeCard extends StatelessWidget {
  final ProxyNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onTestLatency;
  final VoidCallback? onDelete;

  const NodeCard({
    super.key,
    required this.node,
    required this.isSelected,
    required this.onTap,
    this.onTestLatency,
    this.onDelete,
  });

  Color _latencyColor(int? latency) {
    if (latency == null || latency <= 0) return AppColors.textMuted;
    if (latency < 100) return AppColors.connected;
    if (latency < 250) return AppColors.connecting;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.accent : AppColors.borderSubtle;
    final backgroundColor = isSelected ? AppColors.surfaceSecondary : AppColors.surfacePrimary;

    return GlassCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      customBorder: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Radio indicator
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.borderMedium,
                width: 2,
              ),
              color: isSelected ? AppColors.accent : Colors.transparent,
            ),
            child: isSelected
                ? const Center(
                    child: Icon(Icons.check, size: 12, color: Colors.black),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Protocol Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              node.protocol.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Node Name & Address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${node.server}:${node.port}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Latency Pill
          GestureDetector(
            onTap: onTestLatency,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _latencyColor(node.latencyMs).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _latencyColor(node.latencyMs),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    Formatters.formatLatency(node.latencyMs),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _latencyColor(node.latencyMs),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: AppColors.textMuted,
              splashRadius: 18,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
