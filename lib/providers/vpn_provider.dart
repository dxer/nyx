import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/connection_state.dart';
import '../../services/singbox/config_builder.dart';
import 'app_routing_provider.dart';
import 'custom_rules_provider.dart';
import 'nodes_provider.dart';
import 'proxy_groups_provider.dart';
import 'services_provider.dart';

final vpnStatusStreamProvider = StreamProvider<VpnConnectionStatus>((ref) {
  final singbox = ref.watch(singBoxServiceProvider);
  return singbox.statusStream;
});

final vpnStatusProvider = Provider<VpnConnectionStatus>((ref) {
  final asyncStatus = ref.watch(vpnStatusStreamProvider);
  return asyncStatus.value ?? VpnConnectionStatus.disconnected;
});

class VpnController {
  final Ref _ref;

  VpnController(this._ref);

  Future<bool> toggle() async {
    final status = _ref.read(vpnStatusProvider);
    if (status.isTransitioning) return false;

    if (status.isConnected) {
      return await _ref.read(singBoxServiceProvider).stop();
    } else {
      final activeNode = _ref.read(activeNodeProvider);
      if (activeNode == null) return false;

      final configJson = _generateConfig(activeNode);
      return await _ref.read(singBoxServiceProvider).start(configJson);
    }
  }

  Future<bool> switchNode(String nodeId) async {
    _ref.read(selectedNodeIdProvider.notifier).select(nodeId);
    final status = _ref.read(vpnStatusProvider);

    if (status.isConnected) {
      final activeNode = _ref.read(activeNodeProvider);
      if (activeNode == null) return false;

      final configJson = _generateConfig(activeNode);
      return await _ref.read(singBoxServiceProvider).restart(configJson);
    }
    return true;
  }

  Future<bool> reloadConfig() async {
    final status = _ref.read(vpnStatusProvider);
    if (!status.isConnected) return true;

    final activeNode = _ref.read(activeNodeProvider);
    if (activeNode == null) return false;

    final configJson = _generateConfig(activeNode);
    return await _ref.read(singBoxServiceProvider).restart(configJson);
  }

  String _generateConfig(dynamic activeNode) {
    return SingBoxConfigBuilder.buildJsonString(
      activeNode: activeNode,
      allNodes: _ref.read(nodesProvider),
      proxyGroups: _ref.read(proxyGroupsProvider),
      customRules: _ref.read(customRulesProvider),
      appRouting: _ref.read(appRoutingProvider),
      enableTun: true,
      bypassChina: _ref.read(storageServiceProvider).getBypassChina(),
      allowLan: _ref.read(storageServiceProvider).getAllowLan(),
    );
  }
}

final vpnControllerProvider = Provider<VpnController>((ref) {
  return VpnController(ref);
});
