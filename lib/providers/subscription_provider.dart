import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/subscription/subscription_service.dart';
import 'nodes_provider.dart';
import 'services_provider.dart';
import 'vpn_provider.dart';

class SubscriptionsNotifier extends StateNotifier<List<Subscription>> {
  final Ref _ref;

  SubscriptionsNotifier(this._ref, List<Subscription> initial) : super(initial) {
    _checkAutoSync();
  }

  void _checkAutoSync() {
    final storage = _ref.read(storageServiceProvider);
    if (!storage.getAutoUpdateSubscriptions()) return;

    Future.microtask(() async {
      final now = DateTime.now();
      for (final sub in state) {
        final last = sub.lastUpdated;
        final needsSync = last == null ||
            now.difference(last).inMinutes >= sub.updateIntervalMinutes;
        if (needsSync) {
          await syncSubscription(sub.id);
        }
      }
    });
  }

  Future<int> addSubscription({required String name, required String url, int intervalMinutes = 1440}) async {
    final newSub = Subscription(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      url: url.trim(),
      updateIntervalMinutes: intervalMinutes,
    );

    state = [...state, newSub];
    _ref.read(storageServiceProvider).saveSubscriptions(state);

    // Immediately fetch nodes
    return await syncSubscription(newSub.id);
  }

  Future<int> syncSubscription(String id) async {
    final index = state.indexWhere((s) => s.id == id);
    if (index == -1) return 0;

    final sub = state[index];
    final nodes = await SubscriptionService.fetchNodes(sub.url);

    if (nodes.isNotEmpty) {
      _ref.read(nodesProvider.notifier).addNodes(nodes);

      final updatedSub = Subscription(
        id: sub.id,
        name: sub.name,
        url: sub.url,
        updateIntervalMinutes: sub.updateIntervalMinutes,
        lastUpdated: DateTime.now(),
        nodeCount: nodes.length,
      );

      state = [
        for (final s in state)
          if (s.id == id) updatedSub else s
      ];

      _ref.read(storageServiceProvider).saveSubscriptions(state);
      _ref.read(vpnControllerProvider).reloadConfig();
      return nodes.length;
    }
    return 0;
  }

  Future<void> syncAll() async {
    for (final s in state) {
      await syncSubscription(s.id);
    }
  }

  void removeSubscription(String id) {
    state = state.where((s) => s.id != id).toList();
    _ref.read(storageServiceProvider).saveSubscriptions(state);
  }
}

final subscriptionsProvider = StateNotifierProvider<SubscriptionsNotifier, List<Subscription>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadSubscriptions();
  return SubscriptionsNotifier(ref, saved);
});
