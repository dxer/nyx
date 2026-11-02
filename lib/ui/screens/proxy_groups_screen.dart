import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/proxy_group.dart';
import '../../models/proxy_node.dart';
import '../../providers/nodes_provider.dart';
import '../../providers/proxy_groups_provider.dart';
import '../../providers/vpn_provider.dart';
import '../components/glass_card.dart';

class ProxyGroupsScreen extends ConsumerWidget {
  const ProxyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(proxyGroupsProvider);
    final allNodes = ref.watch(nodesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PROXY GROUPS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            tooltip: 'Add Proxy Group',
            onPressed: () => _showGroupEditor(context, ref, allNodes),
          ),
        ],
      ),
      body: groups.isEmpty
          ? _buildEmptyState(context, ref, allNodes)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ProxyGroupCard(
                    group: group,
                    allNodes: allNodes,
                    onEdit: () => _showGroupEditor(context, ref, allNodes, group),
                    onDelete: () {
                      ref.read(proxyGroupsProvider.notifier).removeGroup(group.id);
                      ref.read(vpnControllerProvider).reloadConfig();
                    },
                    onSelectNode: (nodeId) {
                      ref.read(proxyGroupsProvider.notifier).selectGroupNode(group.id, nodeId);
                      ref.read(vpnControllerProvider).reloadConfig();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'NEW GROUP',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        onPressed: () => _showGroupEditor(context, ref, allNodes),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, List<ProxyNode> allNodes) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_tree_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No Proxy Groups Configured',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Organize your nodes into Auto-Fastest latency testers, Manual selectors, or Failover fallback clusters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showGroupEditor(context, ref, allNodes),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('CREATE FIRST GROUP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupEditor(
    BuildContext context,
    WidgetRef ref,
    List<ProxyNode> allNodes, [
    ProxyGroup? existingGroup,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _GroupEditorSheet(
        existingGroup: existingGroup,
        allNodes: allNodes,
      ),
    );
  }
}

class _ProxyGroupCard extends StatelessWidget {
  final ProxyGroup group;
  final List<ProxyNode> allNodes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onSelectNode;

  const _ProxyGroupCard({
    required this.group,
    required this.allNodes,
    required this.onEdit,
    required this.onDelete,
    required this.onSelectNode,
  });

  @override
  Widget build(BuildContext context) {
    final memberNodes = group.nodeIds.isEmpty
        ? allNodes
        : allNodes.where((n) => group.nodeIds.contains(n.id)).toList();

    final (badgeIcon, badgeColor) = switch (group.type) {
      ProxyGroupType.urltest => (Icons.bolt, AppColors.connected),
      ProxyGroupType.selector => (Icons.tune, AppColors.accent),
      ProxyGroupType.fallback => (Icons.shield, AppColors.connecting),
    };

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Icon(badgeIcon, size: 18, color: badgeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      group.type.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            group.type.description,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),

          // Meta telemetry
          Row(
            children: [
              Icon(Icons.device_hub, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${memberNodes.length} nodes',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (group.type != ProxyGroupType.selector) ...[
                const SizedBox(width: 16),
                Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Interval: ${group.intervalMinutes}m',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),

          if (group.type == ProxyGroupType.selector && memberNodes.isNotEmpty) ...[
            const Divider(height: 20),
            const Text(
              'ACTIVE SELECTION',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: AppColors.surfacePrimary,
                  value: memberNodes.any((n) => n.id == group.selectedNodeId)
                      ? group.selectedNodeId
                      : memberNodes.first.id,
                  items: memberNodes.map((n) {
                    return DropdownMenuItem<String>(
                      value: n.id,
                      child: Text(
                        '${n.name} (${n.protocol.toUpperCase()})',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) onSelectNode(id);
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupEditorSheet extends ConsumerStatefulWidget {
  final ProxyGroup? existingGroup;
  final List<ProxyNode> allNodes;

  const _GroupEditorSheet({this.existingGroup, required this.allNodes});

  @override
  ConsumerState<_GroupEditorSheet> createState() => _GroupEditorSheetState();
}

class _GroupEditorSheetState extends ConsumerState<_GroupEditorSheet> {
  final _nameController = TextEditingController();
  final _testUrlController = TextEditingController();
  final _intervalController = TextEditingController();
  late ProxyGroupType _selectedType;
  late Set<String> _selectedNodeIds;

  @override
  void initState() {
    super.initState();
    if (widget.existingGroup != null) {
      _nameController.text = widget.existingGroup!.name;
      _testUrlController.text = widget.existingGroup!.testUrl;
      _intervalController.text = widget.existingGroup!.intervalMinutes.toString();
      _selectedType = widget.existingGroup!.type;
      _selectedNodeIds = Set.from(widget.existingGroup!.nodeIds);
    } else {
      _nameController.text = '';
      _testUrlController.text = 'https://www.gstatic.com/generate_204';
      _intervalController.text = '5';
      _selectedType = ProxyGroupType.urltest;
      // Default to include all nodes
      _selectedNodeIds = Set.from(widget.allNodes.map((n) => n.id));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _testUrlController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a proxy group name')),
      );
      return;
    }

    final interval = int.tryParse(_intervalController.text.trim()) ?? 5;
    final testUrl = _testUrlController.text.trim().isNotEmpty
        ? _testUrlController.text.trim()
        : 'https://www.gstatic.com/generate_204';

    final group = ProxyGroup(
      id: widget.existingGroup?.id ?? 'group_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: _selectedType,
      nodeIds: _selectedNodeIds.toList(),
      selectedNodeId: widget.existingGroup?.selectedNodeId.isNotEmpty == true &&
              _selectedNodeIds.contains(widget.existingGroup!.selectedNodeId)
          ? widget.existingGroup!.selectedNodeId
          : (_selectedNodeIds.isNotEmpty ? _selectedNodeIds.first : ''),
      testUrl: testUrl,
      intervalMinutes: interval,
    );

    if (widget.existingGroup != null) {
      ref.read(proxyGroupsProvider.notifier).updateGroup(group);
    } else {
      ref.read(proxyGroupsProvider.notifier).addGroup(group);
    }

    // Dynamic config reload
    ref.read(vpnControllerProvider).reloadConfig();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingGroup != null ? 'EDIT PROXY GROUP' : 'NEW PROXY GROUP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Group Name
            const Text(
              'GROUP NAME',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Hong Kong Auto or Streaming Selector',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Group Type
            const Text(
              'STRATEGY TYPE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildTypeOption(ProxyGroupType.urltest, 'URL-Test', Icons.bolt, AppColors.connected),
                const SizedBox(width: 8),
                _buildTypeOption(ProxyGroupType.selector, 'Selector', Icons.tune, AppColors.accent),
                const SizedBox(width: 8),
                _buildTypeOption(ProxyGroupType.fallback, 'Fallback', Icons.shield, AppColors.connecting),
              ],
            ),
            const SizedBox(height: 16),

            if (_selectedType != ProxyGroupType.selector) ...[
              // Test URL & Interval
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BENCHMARK URL',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _testUrlController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.borderSubtle),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INTERVAL (MIN)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _intervalController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.borderSubtle),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Node Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MEMBER PROXIES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedNodeIds.length == widget.allNodes.length) {
                        _selectedNodeIds.clear();
                      } else {
                        _selectedNodeIds = Set.from(widget.allNodes.map((n) => n.id));
                      }
                    });
                  },
                  child: Text(
                    _selectedNodeIds.length == widget.allNodes.length ? 'Deselect All' : 'Select All',
                    style: const TextStyle(fontSize: 12, color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (widget.allNodes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No proxy nodes imported yet. You can still create the group, and nodes will automatically attach.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.allNodes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final node = widget.allNodes[i];
                    final isChecked = _selectedNodeIds.contains(node.id);
                    return CheckboxListTile(
                      dense: true,
                      activeColor: AppColors.accent,
                      checkColor: Colors.black,
                      title: Text(
                        node.name,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${node.protocol.toUpperCase()} • ${node.server}:${node.port}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedNodeIds.add(node.id);
                          } else {
                            _selectedNodeIds.remove(node.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _save,
                child: const Text(
                  'SAVE PROXY GROUP',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(ProxyGroupType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? color : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
