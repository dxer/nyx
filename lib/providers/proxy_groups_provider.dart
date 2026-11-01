import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/proxy_group.dart';
import 'services_provider.dart';

class ProxyGroupsNotifier extends StateNotifier<List<ProxyGroup>> {
  final Ref _ref;

  ProxyGroupsNotifier(this._ref, List<ProxyGroup> initial) : super(initial);

  void addGroup(ProxyGroup group) {
    state = [...state, group];
    _ref.read(storageServiceProvider).saveProxyGroups(state);
  }

  void updateGroup(ProxyGroup updated) {
    state = [
      for (final g in state)
        if (g.id == updated.id) updated else g
    ];
    _ref.read(storageServiceProvider).saveProxyGroups(state);
  }

  void removeGroup(String id) {
    state = state.where((g) => g.id != id).toList();
    _ref.read(storageServiceProvider).saveProxyGroups(state);
  }

  void selectGroupNode(String groupId, String nodeId) {
    state = [
      for (final g in state)
        if (g.id == groupId) g.copyWith(selectedNodeId: nodeId) else g
    ];
    _ref.read(storageServiceProvider).saveProxyGroups(state);
  }
}

final proxyGroupsProvider = StateNotifierProvider<ProxyGroupsNotifier, List<ProxyGroup>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadProxyGroups();

  if (saved.isEmpty) {
    final defaults = [
      const ProxyGroup(
        id: 'group_auto_fastest',
        name: '⚡ AUTO FASTEST',
        type: ProxyGroupType.urltest,
        testUrl: 'https://www.gstatic.com/generate_204',
        intervalMinutes: 5,
      ),
      const ProxyGroup(
        id: 'group_manual_select',
        name: '🚀 MAIN SELECTOR',
        type: ProxyGroupType.selector,
      ),
    ];
    storage.saveProxyGroups(defaults);
    return ProxyGroupsNotifier(ref, defaults);
  }
  return ProxyGroupsNotifier(ref, saved);
});
