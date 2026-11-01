class Subscription {
  final String id;
  final String name;
  final String url;
  final int updateIntervalMinutes;
  final DateTime? lastUpdated;
  final int nodeCount;

  const Subscription({
    required this.id,
    required this.name,
    required this.url,
    this.updateIntervalMinutes = 1440, // 24 hours
    this.lastUpdated,
    this.nodeCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'updateIntervalMinutes': updateIntervalMinutes,
    'lastUpdated': lastUpdated?.toIso8601String(),
    'nodeCount': nodeCount,
  };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] as String,
    name: json['name'] as String,
    url: json['url'] as String,
    updateIntervalMinutes: json['updateIntervalMinutes'] as int? ?? 1440,
    lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated'] as String) : null,
    nodeCount: json['nodeCount'] as int? ?? 0,
  );
}
