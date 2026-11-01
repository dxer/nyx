import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proxy_node.dart';
import 'services_provider.dart';

class NodesNotifier extends StateNotifier<List<ProxyNode>> {
  final Ref _ref;

  NodesNotifier(this._ref, List<ProxyNode> initial) : super(initial);

  void addNode(ProxyNode node) {
    if (state.any((n) => n.id == node.id)) return;
    state = [...state, node];
    _ref.read(storageServiceProvider).saveNodes(state);

    final currentSelected = _ref.read(selectedNodeIdProvider);
    if (currentSelected == null) {
      _ref.read(selectedNodeIdProvider.notifier).select(node.id);
    }
  }

  void addNodes(List<ProxyNode> nodes) {
    final existingIds = state.map((n) => n.id).toSet();
    final newNodes = nodes.where((n) => !existingIds.contains(n.id)).toList();
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

  int removeTimeoutNodes() {
    final before = state.length;
    state = state.where((n) => n.latencyMs != -1).toList();
    final removed = before - state.length;
    if (removed > 0) {
      _ref.read(storageServiceProvider).saveNodes(state);
      final currentSelected = _ref.read(selectedNodeIdProvider);
      if (currentSelected != null && !state.any((n) => n.id == currentSelected)) {
        final next = state.isNotEmpty ? state.first.id : null;
        _ref.read(selectedNodeIdProvider.notifier).select(next);
      }
    }
    return removed;
  }

  void sortByLatency() {
    final sorted = List<ProxyNode>.from(state);
    sorted.sort((a, b) {
      final latA = a.latencyMs;
      final latB = b.latencyMs;

      // Both valid positive latencies
      if (latA != null && latA > 0 && latB != null && latB > 0) {
        return latA.compareTo(latB);
      }
      // A is valid, B is not
      if (latA != null && latA > 0) return -1;
      if (latB != null && latB > 0) return 1;

      // Untested (null) before failed (-1)
      if (latA == null && latB == -1) return -1;
      if (latB == null && latA == -1) return 1;

      return a.name.compareTo(b.name);
    });

    state = sorted;
    _ref.read(storageServiceProvider).saveNodes(state);
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
    // Concurrent batch testing (5 parallel queries at a time)
    final nodesToTest = List<ProxyNode>.from(state);
    const batchSize = 5;

    for (var i = 0; i < nodesToTest.length; i += batchSize) {
      final end = (i + batchSize < nodesToTest.length) ? i + batchSize : nodesToTest.length;
      final batch = nodesToTest.sublist(i, end);
      await Future.wait(batch.map((n) => testNodeLatency(n.id)));
    }

    // Auto sort after full test
    sortByLatency();
  }
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
