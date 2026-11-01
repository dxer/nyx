enum RuleType {
  appPackage('Specific App / Process', 'package_name', 'e.g. org.telegram.messenger or telegram.exe'),
  domainPrefix('Domain Prefix', 'domain_prefix', 'e.g. api, auth, cdn (plain words, auto-converted)'),
  domainSuffix('Domain Suffix', 'domain_suffix', 'e.g. google.com, openai.com'),
  domainKeyword('Domain Keyword', 'domain_keyword', 'e.g. twitter, youtube'),
  domainExact('Exact Domain', 'domain', 'e.g. api.github.com'),
  ipCidr('IP CIDR Range', 'ip_cidr', 'e.g. 1.1.1.1/32, 192.168.0.0/16'),
  geosite('GeoSite Rule', 'geosite', 'e.g. cn, apple, netflix, telegram'),
  geoip('GeoIP Rule', 'geoip', 'e.g. cn, private, telegram');

  final String label;
  final String singBoxKey;
  final String placeholder;

  const RuleType(this.label, this.singBoxKey, this.placeholder);
}

enum RuleOutbound {
  proxy('Default Proxy', 'proxy'),
  direct('Direct Connection', 'direct'),
  block('Reject / Block', 'block');

  final String label;
  final String singBoxTag;

  const RuleOutbound(this.label, this.singBoxTag);
}

class CustomRule {
  final String id;
  final String name;
  final RuleType type;
  final List<String> values;
  final RuleOutbound outbound;
  final String? customGroupTag; // When routing to a specific custom proxy group
  final String? targetNodeTag;   // When routing directly to a specific proxy node
  final bool enabled;

  const CustomRule({
    required this.id,
    required this.name,
    required this.type,
    required this.values,
    this.outbound = RuleOutbound.proxy,
    this.customGroupTag,
    this.targetNodeTag,
    this.enabled = true,
  });

  String getEffectiveTarget(String activeTag) {
    if (targetNodeTag != null && targetNodeTag!.isNotEmpty) {
      return targetNodeTag!;
    }
    if (customGroupTag != null && customGroupTag!.isNotEmpty) {
      return customGroupTag!;
    }
    return switch (outbound) {
      RuleOutbound.direct => 'direct',
      RuleOutbound.block => 'block',
      RuleOutbound.proxy => activeTag,
    };
  }

  CustomRule copyWith({
    String? id,
    String? name,
    RuleType? type,
    List<String>? values,
    RuleOutbound? outbound,
    String? customGroupTag,
    String? targetNodeTag,
    bool? enabled,
  }) {
    return CustomRule(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      values: values ?? this.values,
      outbound: outbound ?? this.outbound,
      customGroupTag: customGroupTag ?? this.customGroupTag,
      targetNodeTag: targetNodeTag ?? this.targetNodeTag,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'values': values,
    'outbound': outbound.name,
    'customGroupTag': customGroupTag,
    'targetNodeTag': targetNodeTag,
    'enabled': enabled,
  };

  factory CustomRule.fromJson(Map<String, dynamic> json) => CustomRule(
    id: json['id'] as String,
    name: json['name'] as String,
    type: RuleType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => RuleType.domainSuffix,
    ),
    values: (json['values'] as List<dynamic>).map((e) => e.toString()).toList(),
    outbound: RuleOutbound.values.firstWhere(
      (o) => o.name == json['outbound'],
      orElse: () => RuleOutbound.proxy,
    ),
    customGroupTag: json['customGroupTag'] as String?,
    targetNodeTag: json['targetNodeTag'] as String?,
    enabled: json['enabled'] as bool? ?? true,
  );
}
