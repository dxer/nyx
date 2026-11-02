import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_routing.dart';
import '../../providers/app_routing_provider.dart';
import '../../providers/vpn_provider.dart';
import '../components/glass_card.dart';

class AppRoutingScreen extends ConsumerStatefulWidget {
  const AppRoutingScreen({super.key});

  @override
  ConsumerState<AppRoutingScreen> createState() => _AppRoutingScreenState();
}

class _AppRoutingScreenState extends ConsumerState<AppRoutingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  bool _hideSystemApps = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routingConfig = ref.watch(appRoutingProvider);
    final appsAsync = ref.watch(installedAppsProvider);
    final vpnController = ref.read(vpnControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr.appRoutingTitle.toUpperCase()),
      ),
      body: Column(
        children: [
          // Mode Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  _buildModeTab(AppRoutingMode.all, 'All Proxied', routingConfig.mode),
                  _buildModeTab(AppRoutingMode.allowlist, 'Whitelist', routingConfig.mode),
                  _buildModeTab(AppRoutingMode.blocklist, 'Blacklist', routingConfig.mode),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              routingConfig.mode.description,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),

          if (routingConfig.mode != AppRoutingMode.all) ...[
            // Search and Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _search = v.trim()),
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Filter apps...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfacePrimary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _hideSystemApps ? Icons.android_rounded : Icons.android_outlined,
                      color: _hideSystemApps ? AppColors.accent : AppColors.textMuted,
                    ),
                    tooltip: _hideSystemApps ? 'Showing User Apps' : 'Showing All Apps',
                    onPressed: () => setState(() => _hideSystemApps = !_hideSystemApps),
                  ),
                ],
              ),
            ),

            // Selection summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected: ${routingConfig.selectedPackages.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          appsAsync.whenData((apps) {
                            ref.read(appRoutingProvider.notifier).selectAll(
                              apps.map((a) => a.packageName).toList(),
                            );
                            vpnController.reloadConfig();
                          });
                        },
                        child: const Text(
                          'Select All',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () {
                          ref.read(appRoutingProvider.notifier).clearAll();
                          vpnController.reloadConfig();
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // App List
          Expanded(
            child: routingConfig.mode == AppRoutingMode.all
                ? const Center(
                    child: Text(
                      'All applications are proxied by default.\nSelect Whitelist or Blacklist to customize.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  )
                : appsAsync.when(
                    data: (apps) {
                      final filtered = apps.where((app) {
                        if (_hideSystemApps && app.isSystemApp) return false;
                        if (_search.isEmpty) return true;
                        return app.appName.toLowerCase().contains(_search.toLowerCase()) ||
                            app.packageName.toLowerCase().contains(_search.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final app = filtered[index];
                          final isChecked = routingConfig.selectedPackages.contains(app.packageName);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              onTap: () {
                                ref.read(appRoutingProvider.notifier).togglePackage(app.packageName);
                                vpnController.reloadConfig();
                              },
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.surfaceHighlight,
                                    child: Text(
                                      app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.appName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          app.packageName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: isChecked,
                                    activeColor: AppColors.accent,
                                    checkColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (_) {
                                      ref.read(appRoutingProvider.notifier).togglePackage(app.packageName);
                                      vpnController.reloadConfig();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                    error: (_, __) => const Center(child: Text('Failed to load apps')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(AppRoutingMode mode, String label, AppRoutingMode activeMode) {
    final isSelected = mode == activeMode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(appRoutingProvider.notifier).setMode(mode);
          ref.read(vpnControllerProvider).reloadConfig();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceHighlight : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
