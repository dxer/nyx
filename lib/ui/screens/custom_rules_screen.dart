import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/custom_rule.dart';
import '../../providers/custom_rules_provider.dart';
import '../../providers/nodes_provider.dart';
import '../../providers/proxy_groups_provider.dart';
import '../../providers/vpn_provider.dart';
import '../components/glass_card.dart';

class CustomRulesScreen extends ConsumerWidget {
  const CustomRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(customRulesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CUSTOM RULES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            tooltip: 'Add Rule',
            onPressed: () => _showAddRuleSheet(context, ref),
          ),
        ],
      ),
      body: rules.isEmpty
          ? _buildEmptyState(context, ref)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RuleCard(
                    rule: rule,
                    onToggle: () {
                      ref.read(customRulesProvider.notifier).toggleRule(rule.id);
                      ref.read(vpnControllerProvider).reloadConfig();
                    },
                    onDelete: () {
                      ref.read(customRulesProvider.notifier).removeRule(rule.id);
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
          'NEW RULE',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        onPressed: () => _showAddRuleSheet(context, ref),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alt_route, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No Custom Rules Defined',
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
              'Route specific apps, domain prefixes, domains, or IP ranges to dedicated nodes, proxy groups, or direct connections.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddRuleSheet(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('CREATE FIRST RULE'),
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

  void _showAddRuleSheet(BuildContext context, WidgetRef ref, [CustomRule? existingRule]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RuleEditorSheet(existingRule: existingRule),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final CustomRule rule;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String targetLabel;
    final Color targetColor;
    final IconData targetIcon;

    if (rule.targetNodeTag != null && rule.targetNodeTag!.isNotEmpty) {
      targetLabel = 'NODE: ${rule.targetNodeTag}';
      targetColor = AppColors.connected;
      targetIcon = Icons.dns_rounded;
    } else if (rule.customGroupTag != null && rule.customGroupTag!.isNotEmpty) {
      targetLabel = 'GROUP: ${rule.customGroupTag}';
      targetColor = AppColors.connecting;
      targetIcon = Icons.hub_rounded;
    } else {
      switch (rule.outbound) {
        case RuleOutbound.direct:
          targetLabel = 'DIRECT';
          targetColor = AppColors.connected;
          targetIcon = Icons.arrow_outward_rounded;
          break;
        case RuleOutbound.block:
          targetLabel = 'BLOCK';
          targetColor = AppColors.error;
          targetIcon = Icons.block_rounded;
          break;
        case RuleOutbound.proxy:
          targetLabel = 'DEFAULT PROXY';
          targetColor = AppColors.accent;
          targetIcon = Icons.vpn_lock_rounded;
          break;
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rule.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: rule.enabled ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
              Switch(
                value: rule.enabled,
                activeColor: AppColors.accent,
                onChanged: (_) => onToggle(),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Rule Type Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  rule.type.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Outbound Target Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: targetColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: targetColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(targetIcon, size: 12, color: targetColor),
                    const SizedBox(width: 4),
                    Text(
                      targetLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: targetColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Values chip list
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rule.values.take(6).map((val) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  val,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }).toList()
              ..addAll(rule.values.length > 6
                  ? [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text(
                          '+${rule.values.length - 6} more',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      )
                    ]
                  : []),
          ),
        ],
      ),
    );
  }
}

class _RuleEditorSheet extends ConsumerStatefulWidget {
  final CustomRule? existingRule;

  const _RuleEditorSheet({this.existingRule});

  @override
  ConsumerState<_RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends ConsumerState<_RuleEditorSheet> {
  final _nameController = TextEditingController();
  final _valuesController = TextEditingController();
  late RuleType _selectedType;
  late RuleOutbound _selectedOutbound;
  String? _selectedCustomGroup;
  String? _selectedNodeTag;

  @override
  void initState() {
    super.initState();
    if (widget.existingRule != null) {
      _nameController.text = widget.existingRule!.name;
      _valuesController.text = widget.existingRule!.values.join('\n');
      _selectedType = widget.existingRule!.type;
      _selectedOutbound = widget.existingRule!.outbound;
      _selectedCustomGroup = widget.existingRule!.customGroupTag;
      _selectedNodeTag = widget.existingRule!.targetNodeTag;
    } else {
      _nameController.text = '';
      _valuesController.text = '';
      _selectedType = RuleType.appPackage;
      _selectedOutbound = RuleOutbound.proxy;
      _selectedCustomGroup = null;
      _selectedNodeTag = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valuesController.dispose();
    super.dispose();
  }

  void _appendChipValue(String val) {
    final current = _valuesController.text.trim();
    if (current.isEmpty) {
      _valuesController.text = val;
    } else {
      final list = current.split(RegExp(r'[\n,]+')).map((s) => s.trim()).toList();
      if (!list.contains(val)) {
        _valuesController.text = '$current\n$val';
      }
    }
    setState(() {});
  }

  void _save() {
    final name = _nameController.text.trim();
    final rawValues = _valuesController.text
        .split(RegExp(r'[\n,]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a descriptive rule name')),
      );
      return;
    }

    if (rawValues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one target value (app, domain, prefix)')),
      );
      return;
    }

    final newRule = CustomRule(
      id: widget.existingRule?.id ?? 'rule_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: _selectedType,
      values: rawValues,
      outbound: _selectedOutbound,
      customGroupTag: _selectedCustomGroup,
      targetNodeTag: _selectedNodeTag,
      enabled: widget.existingRule?.enabled ?? true,
    );

    if (widget.existingRule != null) {
      ref.read(customRulesProvider.notifier).updateRule(newRule);
    } else {
      ref.read(customRulesProvider.notifier).addRule(newRule);
    }

    ref.read(vpnControllerProvider).reloadConfig();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final proxyGroups = ref.watch(proxyGroupsProvider);
    final allNodes = ref.watch(nodesProvider);

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
                  widget.existingRule != null ? 'EDIT DEDICATED RULE' : 'NEW DEDICATED ROUTE RULE',
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

            // Rule Name
            const Text(
              'RULE NAME',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Telegram to SG Node or OpenAI to US Group',
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

            // Match Type
            const Text(
              'MATCH CRITERIA (APP / DOMAIN / PREFIX)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<RuleType>(
                  isExpanded: true,
                  dropdownColor: AppColors.surfacePrimary,
                  value: _selectedType,
                  items: RuleType.values.map((type) {
                    return DropdownMenuItem<RuleType>(
                      value: type,
                      child: Text(
                        '${type.label} (${type.singBoxKey})',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (newType) {
                    if (newType != null) {
                      setState(() => _selectedType = newType);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Target Outbound Selection
            const Text(
              'TARGET OUTBOUND DESTINATION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildOutboundOption(RuleOutbound.proxy, 'Default Proxy', Icons.vpn_lock, AppColors.accent),
                const SizedBox(width: 8),
                _buildOutboundOption(RuleOutbound.direct, 'Direct', Icons.arrow_outward, AppColors.connected),
                const SizedBox(width: 8),
                _buildOutboundOption(RuleOutbound.block, 'Block', Icons.block, AppColors.error),
              ],
            ),

            // Dedicated Single Node Dropdown
            if (allNodes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'OR ROUTE TO SPECIFIC PROXY NODE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedNodeTag != null ? AppColors.connected : AppColors.borderSubtle,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    dropdownColor: AppColors.surfacePrimary,
                    value: _selectedNodeTag,
                    hint: const Text('None (Use Default or Group below)', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None (Use Above)', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ),
                      ...allNodes.map((n) {
                        return DropdownMenuItem<String?>(
                          value: n.name.isNotEmpty ? n.name : n.id,
                          child: Text(
                            '🎯 ${n.name} (${n.protocol.toUpperCase()} • ${n.address})',
                            style: const TextStyle(fontSize: 13, color: AppColors.connected),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedNodeTag = val;
                        if (val != null) _selectedCustomGroup = null;
                      });
                    },
                  ),
                ),
              ),
            ],

            // Dedicated Proxy Group Dropdown
            if (proxyGroups.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'OR ROUTE TO SPECIFIC PROXY GROUP',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedCustomGroup != null ? AppColors.connecting : AppColors.borderSubtle,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    dropdownColor: AppColors.surfacePrimary,
                    value: _selectedCustomGroup,
                    hint: const Text('None (Use Default or Node above)', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None (Use Above)', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ),
                      ...proxyGroups.map((g) {
                        return DropdownMenuItem<String?>(
                          value: g.name,
                          child: Text(
                            '🌐 Group: ${g.name} (${g.type.label})',
                            style: const TextStyle(fontSize: 13, color: AppColors.connecting),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCustomGroup = val;
                        if (val != null) _selectedNodeTag = null;
                      });
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Target Values with Quick Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TARGET VALUES (${_selectedType.placeholder})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Quick Preset Chips depending on type
            _buildPresetChips(),
            const SizedBox(height: 6),

            TextField(
              controller: _valuesController,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: _selectedType == RuleType.domainPrefix
                    ? 'Enter plain prefixes separated by comma or newline (e.g. api, cdn, auth)\nSystem automatically converts them into prefix matching rules (no regex required).'
                    : 'Enter values separated by commas or newlines:\n${_selectedType.placeholder}',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
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
                  'SAVE DEDICATED RULE',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChips() {
    final List<String> chips = switch (_selectedType) {
      RuleType.appPackage => ['org.telegram.messenger', 'com.twitter.android', 'com.zhiliaoapp.musically', 'com.google.android.youtube', 'Telegram.exe', 'chrome.exe'],
      RuleType.domainPrefix => ['api', 'auth', 'cdn', 'stream', 'live', 'dl'],
      RuleType.domainSuffix => ['openai.com', 'anthropic.com', 'google.com', 'apple.com', 'netflix.com'],
      RuleType.domainKeyword => ['telegram', 'twitter', 'youtube', 'netflix', 'spotify'],
      _ => [],
    };

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips.map((c) {
        return GestureDetector(
          onTap: () => _appendChipValue(c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              '+ $c',
              style: const TextStyle(fontSize: 11, color: AppColors.accent),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOutboundOption(RuleOutbound outbound, String label, IconData icon, Color color) {
    final isSelected = _selectedNodeTag == null && _selectedCustomGroup == null && _selectedOutbound == outbound;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOutbound = outbound;
            _selectedCustomGroup = null;
            _selectedNodeTag = null;
          });
        },
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
