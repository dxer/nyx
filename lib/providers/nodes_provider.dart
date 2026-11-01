import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/proxy_node.dart';
import 'services_provider.dart';

class NodesNotifier extends StateNotifier<List<ProxyNode>> {
  final Ref _ref;

  NodesNotifier(this._ref, List<ProxyNode> initial) : super(initial);

  void addNode(ProxyNode node) {
    if (state.any((n) => n.id == node.id)) return;
    state = [...state, node];
    _ref.read(storageServiceProvider).saveNodes(state);
    
    // Select first node if none selected
    final currentSelected = _ref.read(selectedNodeIdProvider);
    if (currentSelected == null) {
      _ref.read(selectedNodeIdProvider.notifier).select(node.id);
    }
  }

  void addNodes(List<ProxyNode> nodes) {
    final existingIds = state.map((n) => n.id).toSet();
    final newNodes = nodes.filter((n) => !existingIds.contains(n.id)).toList();
    if (newNodes.isEmpty) return;

    state = [...state, ...newNodes];
    _ref.read(storageServiceProvider).saveNodes(state);

    final currentSelected = _ref.read(selectedNodeIdProvider);
    if (currentSelected == null && state.isNotEmpty) {
      _ref.read(selectedNodeIdProvider.notifier).select(state.first.id);
    }
  }

  void removeNode(String id) {
    state = state.where((n) => n.id != id).toList();
    _ref.read(storageServiceProvider).saveNodes(state);

    final currentSelected = _ref.read(selectedNodeIdProvider);
    if (currentSelected == id) {
      final next = state.isNotEmpty ? state.first.id : null;
      _ref.read(selectedNodeIdProvider.notifier).select(next);
    }
  }

  Future<void> testNodeLatency(String id) async {
    final node = state.firstWhere((n) => n.id == id, orElse: () => throw Exception('Not found'));
    final singbox = _ref.read(singBoxServiceProvider);
    final latency = await singbox.testLatency(node.server, node.port);

    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(latencyMs: latency) else n
    ];
    _ref.read(storageServiceProvider).saveNodes(state);
  }

  Future<void> testAllLatencies() async {
    for (final node in state) {
      await testNodeLatency(node.id);
    }
  }
}

extension _IterableFilter<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T element) test) => where(test);
}

final nodesProvider = StateNotifierProvider<NodesNotifier, List<ProxyNode>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final initialNodes = storage.loadNodes();
  return NodesNotifier(ref, initialNodes);
});

class SelectedNodeIdNotifier extends StateNotifier<String?> {
  final Ref _ref;

  SelectedNodeIdNotifier(this._ref, String? initial) : super(initial);

  void select(String? id) {
    state = id;
    _ref.read(storageServiceProvider).setSelectedNodeId(id);
  }
}

final selectedNodeIdProvider = StateNotifierProvider<SelectedNodeIdNotifier, String?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SelectedNodeIdNotifier(ref, storage.getSelectedNodeId());
});

final activeNodeProvider = Provider<ProxyNode?>((ref) {
  final selectedId = ref.watch(selectedNodeIdProvider);
  final nodes = ref.watch(nodesProvider);
  if (selectedId == null || nodes.isEmpty) return null;
  return nodes.firstWhere((n) => n.id == selectedId, orElse: () => nodes.first);
});
