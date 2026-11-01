class ProxyNode {
  final String id;
  final String name;
  final String protocol; // vless, vmess, ss, trojan, hysteria2, tuic, wireguard
  final String server;
  final int port;
  final int? latencyMs;
  final bool isFavorite;
  final String? subscriptionId;
  final Map<String, dynamic> rawConfig;

  const ProxyNode({
    required this.id,
    required this.name,
    required this.protocol,
    required this.server,
    required this.port,
    this.latencyMs,
    this.isFavorite = false,
    this.subscriptionId,
    this.rawConfig = const {},
  });

  ProxyNode copyWith({
    String? id,
    String? name,
    String? protocol,
    String? server,
    int? port,
    int? latencyMs,
    bool? isFavorite,
    String? subscriptionId,
    Map<String, dynamic>? rawConfig,
  }) {
    return ProxyNode(
      id: id ?? this.id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      server: server ?? this.server,
      port: port ?? this.port,
      latencyMs: latencyMs ?? this.latencyMs,
      isFavorite: isFavorite ?? this.isFavorite,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      rawConfig: rawConfig ?? this.rawConfig,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'protocol': protocol,
    'server': server,
    'port': port,
    'latencyMs': latencyMs,
    'isFavorite': isFavorite,
    'subscriptionId': subscriptionId,
    'rawConfig': rawConfig,
  };

  factory ProxyNode.fromJson(Map<String, dynamic> json) => ProxyNode(
    id: json['id'] as String,
    name: json['name'] as String,
    protocol: json['protocol'] as String,
    server: json['server'] as String,
    port: json['port'] as int,
    latencyMs: json['latencyMs'] as int?,
    isFavorite: json['isFavorite'] as bool? ?? false,
    subscriptionId: json['subscriptionId'] as String?,
    rawConfig: (json['rawConfig'] as Map<String, dynamic>?) ?? {},
  );
}
