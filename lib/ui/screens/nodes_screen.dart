import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/proxy_node.dart';
import '../../providers/nodes_provider.dart';
import '../../providers/vpn_provider.dart';
import '../../services/parser/node_link_parser.dart';
import '../components/node_card.dart';

class NodesScreen extends ConsumerStatefulWidget {
  const NodesScreen({super.key});

  @override
  ConsumerState<NodesScreen> createState() => _NodesScreenState();
}

class _NodesScreenState extends ConsumerState<NodesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';
  bool _hideTimeouts = false;
  bool _isTesting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showImportDialog() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'IMPORT PROXIES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.paste_rounded, size: 16, color: AppColors.accent),
                  label: const Text('Paste', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      textController.text = data!.text!;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Paste links, Base64 airport subscription, or Clash YAML...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isNotEmpty) {
                    final parsed = NodeLinkParser.parseAny(text);
                    if (parsed.isNotEmpty) {
                      ref.read(nodesProvider.notifier).addNodes(parsed);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceElevated,
                          content: Text(
                            'Successfully imported ${parsed.length} node(s)',
                            style: const TextStyle(color: AppColors.connected, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No valid proxy nodes detected. Please check your links, base64 subscription, or Clash YAML.'),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'CONFIRM IMPORT',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodesProvider);
    final selectedId = ref.watch(selectedNodeIdProvider);
    final vpnController = ref.read(vpnControllerProvider);

    final timeoutCount = nodes.where((n) => n.latencyMs == -1).length;

    var filteredNodes = nodes.where((n) {
      if (_filter.isNotEmpty) {
        final matches = n.name.toLowerCase().contains(_filter.toLowerCase()) ||
            n.server.toLowerCase().contains(_filter.toLowerCase());
        if (!matches) return false;
      }
      if (_hideTimeouts && n.latencyMs == -1) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OUTBOUND NODES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textSecondary),
            tooltip: 'Sort by Latency (Fastest First)',
            onPressed: () {
              ref.read(nodesProvider.notifier).sortByLatency();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nodes sorted by latency (lowest first)')),
              );
            },
          ),
          IconButton(
            icon: _isTesting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                : const Icon(Icons.speed_rounded, color: AppColors.textSecondary),
            tooltip: 'Batch Ping Test',
            onPressed: _isTesting
                ? null
                : () async {
                    setState(() => _isTesting = true);
                    await ref.read(nodesProvider.notifier).testAllLatencies();
                    if (mounted) {
                      setState(() => _isTesting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Batch latency test complete & auto-sorted')),
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.accent),
            tooltip: 'Import Nodes',
            onPressed: _showImportDialog,
          ),
        ],
      ),
      body: nodes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'No Nodes Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to import from airport links, Base64, or Clash YAML',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _showImportDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('IMPORT NOW', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filter, Hide Timeouts & Quick Stats Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _filter = val.trim()),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Filter ${nodes.length} nodes...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.surfacePrimary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.borderSubtle),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Toggle Hide Timeouts
                      GestureDetector(
                        onTap: () => setState(() => _hideTimeouts = !_hideTimeouts),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: _hideTimeouts ? AppColors.accent.withOpacity(0.15) : AppColors.surfacePrimary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _hideTimeouts ? AppColors.accent : AppColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _hideTimeouts ? Icons.visibility_off : Icons.visibility,
                                size: 16,
                                color: _hideTimeouts ? AppColors.accent : AppColors.textMuted,
                              ),
                              if (timeoutCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '$timeoutCount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _hideTimeouts ? AppColors.accent : AppColors.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Timeout Cleanup Banner
                if (timeoutCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _hideTimeouts
                                ? 'Hidden $timeoutCount timeout node(s)'
                                : 'Found $timeoutCount timeout node(s)',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () {
                              final count = ref.read(nodesProvider.notifier).removeTimeoutNodes();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed $count dead node(s)')),
                              );
                            },
                            child: const Text('Clean All', style: TextStyle(color: AppColors.error, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Node List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    itemCount: filteredNodes.length,
                    itemBuilder: (context, index) {
                      final node = filteredNodes[index];
                      final isSelected = node.id == selectedId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NodeCard(
                          node: node,
                          isSelected: isSelected,
                          onTap: () {
                            vpnController.switchNode(node.id);
                          },
                          onTestLatency: () {
                            ref.read(nodesProvider.notifier).testNodeLatency(node.id);
                          },
                          onDelete: () {
                            ref.read(nodesProvider.notifier).removeNode(node.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
