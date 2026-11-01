enum ProxyGroupType {
  selector('Manual Selector', 'selector', 'User chooses the active proxy manually'),
  urltest('Auto URL-Test', 'urltest', 'Automatically routes via lowest latency node'),
  fallback('Failover Fallback', 'fallback', 'Uses first working node in the priority list');

  final String label;
  final String singBoxType;
  final String description;

  const ProxyGroupType(this.label, this.singBoxType, this.description);
}

class ProxyGroup {
  final String id;
  final String name;
  final ProxyGroupType type;
  final List<String> nodeIds;
  final String selectedNodeId; // For selector groups
  final String testUrl;
  final int intervalMinutes;

  const ProxyGroup({
    required this.id,
    required this.name,
    this.type = ProxyGroupType.selector,
    this.nodeIds = const [],
    this.selectedNodeId = '',
    this.testUrl = 'https://www.gstatic.com/generate_204',
    this.intervalMinutes = 5,
  });

  ProxyGroup copyWith({
    String? id,
    String? name,
    ProxyGroupType? type,
    List<String>? nodeIds,
    String? selectedNodeId,
    String? testUrl,
    int? intervalMinutes,
  }) {
    return ProxyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      nodeIds: nodeIds ?? this.nodeIds,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
      testUrl: testUrl ?? this.testUrl,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'nodeIds': nodeIds,
    'selectedNodeId': selectedNodeId,
    'testUrl': testUrl,
    'intervalMinutes': intervalMinutes,
  };

  factory ProxyGroup.fromJson(Map<String, dynamic> json) => ProxyGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    type: ProxyGroupType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => ProxyGroupType.selector,
    ),
    nodeIds: (json['nodeIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    selectedNodeId: json['selectedNodeId'] as String? ?? '',
    testUrl: json['testUrl'] as String? ?? 'https://www.gstatic.com/generate_204',
    intervalMinutes: json['intervalMinutes'] as int? ?? 5,
  );
}
