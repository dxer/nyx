import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_routing.dart';
import 'services_provider.dart';

class AppRoutingNotifier extends StateNotifier<AppRoutingConfig> {
  final Ref _ref;

  AppRoutingNotifier(this._ref, AppRoutingConfig initial) : super(initial);

  void setMode(AppRoutingMode mode) {
    state = state.copyWith(mode: mode);
    _ref.read(storageServiceProvider).saveAppRoutingConfig(state);
  }

  void togglePackage(String packageName) {
    final updated = Set<String>.from(state.selectedPackages);
    if (updated.contains(packageName)) {
      updated.remove(packageName);
    } else {
      updated.add(packageName);
    }
    state = state.copyWith(selectedPackages: updated);
    _ref.read(storageServiceProvider).saveAppRoutingConfig(state);
  }

  void selectAll(List<String> packages) {
    state = state.copyWith(selectedPackages: packages.toSet());
    _ref.read(storageServiceProvider).saveAppRoutingConfig(state);
  }

  void clearAll() {
    state = state.copyWith(selectedPackages: {});
    _ref.read(storageServiceProvider).saveAppRoutingConfig(state);
  }
}

final appRoutingProvider = StateNotifierProvider<AppRoutingNotifier, AppRoutingConfig>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AppRoutingNotifier(ref, storage.loadAppRoutingConfig());
});

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  const channel = MethodChannel('com.nyx.vpn/service');
  try {
    final result = await channel.invokeListMethod<Map>('getInstalledApps');
    if (result != null) {
      return result.map((item) {
        return AppInfo(
          packageName: item['packageName'] as String? ?? '',
          appName: item['appName'] as String? ?? '',
          isSystemApp: item['isSystemApp'] as bool? ?? false,
        );
      }).where((app) => app.packageName.isNotEmpty).toList();
    }
  } catch (_) {
    // Simulator/Desktop mock apps list
  }

  // Realistic fallback app list for local development
  return const [
    AppInfo(packageName: 'com.android.chrome', appName: 'Google Chrome'),
    AppInfo(packageName: 'org.telegram.messenger', appName: 'Telegram'),
    AppInfo(packageName: 'com.google.android.youtube', appName: 'YouTube'),
    AppInfo(packageName: 'com.twitter.android', appName: 'X (Twitter)'),
    AppInfo(packageName: 'com.instagram.android', appName: 'Instagram'),
    AppInfo(packageName: 'com.tencent.mm', appName: 'WeChat (微信)'),
    AppInfo(packageName: 'com.eg.android.AlipayGphone', appName: 'Alipay (支付宝)'),
    AppInfo(packageName: 'com.ss.android.ugc.aweme', appName: 'Douyin (抖音)'),
    AppInfo(packageName: 'com.alibaba.android.rimet', appName: 'DingTalk (钉钉)'),
    AppInfo(packageName: 'com.bilibili.app.in', appName: 'Bilibili (哔哩哔哩)'),
  ];
});
