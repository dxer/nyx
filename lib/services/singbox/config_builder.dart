import 'dart:convert';
import '../../models/app_routing.dart';
import '../../models/custom_rule.dart';
import '../../models/proxy_group.dart';
import '../../models/proxy_node.dart';

class SingBoxConfigBuilder {
  static Map<String, dynamic> build({
    required ProxyNode activeNode,
    List<ProxyNode> allNodes = const [],
    List<ProxyGroup> proxyGroups = const [],
    List<CustomRule> customRules = const [],
    AppRoutingConfig appRouting = const AppRoutingConfig(),
    bool enableTun = true,
    int mixedPort = 2080,
    bool bypassChina = true,
    bool allowLan = false,
  }) {
    final activeTag = activeNode.name.isNotEmpty ? activeNode.name : 'proxy';

    // 1. Build all node outbounds
    final nodeOutbounds = <Map<String, dynamic>>[];
    final addedTags = <String>{};

    void addNode(ProxyNode node) {
      final tag = node.name.isNotEmpty ? node.name : node.id;
      if (addedTags.contains(tag)) return;
      addedTags.add(tag);
      final raw = Map<String, dynamic>.from(node.rawConfig);
      raw['tag'] = tag;
      nodeOutbounds.add(raw);
    }

    addNode(activeNode);
    for (final node in allNodes) {
      addNode(node);
    }

    // 2. Build Proxy Groups outbounds (selector, urltest, fallback)
    final groupOutbounds = <Map<String, dynamic>>[];
    for (final group in proxyGroups) {
      final memberTags = group.nodeIds.map((id) {
        final found = allNodes.firstWhere(
          (n) => n.id == id,
          orElse: () => ProxyNode(id: id, name: id, protocol: 'vless', server: '', port: 0),
        );
        return found.name.isNotEmpty ? found.name : found.id;
      }).where((tag) => tag.isNotEmpty).toList();

      if (memberTags.isEmpty && addedTags.isNotEmpty) {
        memberTags.addAll(addedTags);
      }

      final groupMap = <String, dynamic>{
        'type': group.type.singBoxType,
        'tag': group.name,
        'outbounds': memberTags,
      };

      if (group.type == ProxyGroupType.selector) {
        if (group.selectedNodeId.isNotEmpty) {
          final selected = allNodes.firstWhere(
            (n) => n.id == group.selectedNodeId,
            orElse: () => activeNode,
          );
          groupMap['default'] = selected.name;
        }
      } else if (group.type == ProxyGroupType.urltest) {
        groupMap['url'] = group.testUrl;
        groupMap['interval'] = '${group.intervalMinutes}m';
        groupMap['tolerance'] = 50;
      }

      groupOutbounds.add(groupMap);
    }

    // 3. Build Inbounds (TUN + Mixed SOCKS5/HTTP)
    final inbounds = <Map<String, dynamic>>[
      {
        'type': 'mixed',
        'tag': 'mixed-in',
        'listen': allowLan ? '0.0.0.0' : '127.0.0.1',
        'listen_port': mixedPort,
        'sniff': true,
      }
    ];

    if (enableTun) {
      inbounds.add({
        'type': 'tun',
        'tag': 'tun-in',
        'inet4_address': '172.19.0.1/30',
        'auto_route': true,
        'strict_route': true,
        'stack': 'mixed',
        'sniff': true,
      });
    }

    // 4. Build Custom & Standard Route Rules
    final routeRules = <Map<String, dynamic>>[
      {
        'protocol': 'dns',
        'outbound': 'dns-out',
      },
    ];

    // 4.1 Per-App routing rules (if in sing-box layer)
    if (appRouting.mode == AppRoutingMode.blocklist && appRouting.selectedPackages.isNotEmpty) {
      routeRules.add({
        'package_name': appRouting.selectedPackages.toList(),
        'outbound': 'direct',
      });
    } else if (appRouting.mode == AppRoutingMode.allowlist && appRouting.selectedPackages.isNotEmpty) {
      routeRules.add({
        'package_name': appRouting.selectedPackages.toList(),
        'outbound': activeTag,
      });
      // Non-selected apps go direct in allowlist mode
      routeRules.add({
        'network': 'tcp',
        'outbound': 'direct',
      });
      routeRules.add({
        'network': 'udp',
        'outbound': 'direct',
      });
    }

    // 4.2 User Custom Dedicated Rules (processed with highest user priority)
    for (final rule in customRules) {
      if (!rule.enabled || rule.values.isEmpty) continue;

      final targetOutbound = rule.getEffectiveTarget(activeTag);
      final cleanValues = rule.values.map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
      if (cleanValues.isEmpty) continue;

      if (rule.type == RuleType.appPackage) {
        // Dedicated routing for specific App / Process
        routeRules.add({
          'package_name': cleanValues,
          'outbound': targetOutbound,
        });
        routeRules.add({
          'process_name': cleanValues,
          'outbound': targetOutbound,
        });
      } else if (rule.type == RuleType.domainPrefix) {
        // Dedicated routing for Domain Prefixes:
        // Automatically converts plain text input (e.g. "api", "cdn", "live-stream") into regex
        final regexes = cleanValues.map((raw) {
          var cleaned = raw.trim();
          // Strip accidental regex hats, wildcards, or trailing dots
          if (cleaned.startsWith('^')) cleaned = cleaned.substring(1);
          if (cleaned.startsWith('*.')) cleaned = cleaned.substring(2);
          if (cleaned.endsWith('.*')) cleaned = cleaned.substring(0, cleaned.length - 2);
          if (cleaned.endsWith('.')) cleaned = cleaned.substring(0, cleaned.length - 1);
          cleaned = cleaned.replaceAll(r'\.', '.');

          if (cleaned.isEmpty) return '';
          // Escape any special characters and anchor as subdomain prefix: e.g. "^api\."
          return '^${RegExp.escape(cleaned)}\\.';
        }).where((r) => r.isNotEmpty).toList();

        if (regexes.isNotEmpty) {
          routeRules.add({
            'domain_regex': regexes,
            'outbound': targetOutbound,
          });
        }
      } else {
        routeRules.add({
          rule.type.singBoxKey: cleanValues,
          'outbound': targetOutbound,
        });
      }
    }

    // 4.3 Default geo rules (China bypass)
    if (bypassChina) {
      routeRules.addAll([
        {
          'geoip': ['private', 'cn'],
          'outbound': 'direct',
        },
        {
          'geosite': ['cn'],
          'outbound': 'direct',
        },
      ]);
    }

    return {
      'log': {
        'level': 'warn',
        'timestamp': true,
      },
      'dns': {
        'servers': [
          {
            'tag': 'remote-dns',
            'address': 'https://1.1.1.1/dns-query',
            'detour': activeTag,
          },
          {
            'tag': 'local-dns',
            'address': '223.5.5.5',
            'detour': 'direct',
          },
          {
            'tag': 'fakeip-dns',
            'address': 'fakeip',
          },
        ],
        'rules': [
          {
            'outbound': ['any'],
            'server': 'local-dns',
          },
          if (bypassChina)
            {
              'geosite': ['cn'],
              'server': 'local-dns',
            },
          {
            'query_type': ['A', 'AAAA'],
            'server': 'fakeip-dns',
          },
        ],
        'fakeip': {
          'enabled': true,
          'inet4_range': '198.18.0.0/15',
          'inet6_range': 'fc00::/18',
        },
        'final': 'remote-dns',
        'strategy': 'prefer_ipv4',
      },
      'inbounds': inbounds,
      'outbounds': [
        ...groupOutbounds,
        ...nodeOutbounds,
        {
          'type': 'direct',
          'tag': 'direct',
        },
        {
          'type': 'block',
          'tag': 'block',
        },
        {
          'type': 'dns',
          'tag': 'dns-out',
        },
      ],
      'route': {
        'rules': routeRules,
        'final': activeTag,
        'auto_detect_interface': true,
      },
      'experimental': {
        'cache_file': {
          'enabled': true,
        }
      }
    };
  }

  static String buildJsonString({
    required ProxyNode activeNode,
    List<ProxyNode> allNodes = const [],
    List<ProxyGroup> proxyGroups = const [],
    List<CustomRule> customRules = const [],
    AppRoutingConfig appRouting = const AppRoutingConfig(),
    bool enableTun = true,
    int mixedPort = 2080,
    bool bypassChina = true,
    bool allowLan = false,
  }) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(build(
      activeNode: activeNode,
      allNodes: allNodes,
      proxyGroups: proxyGroups,
      customRules: customRules,
      appRouting: appRouting,
      enableTun: enableTun,
      mixedPort: mixedPort,
      bypassChina: bypassChina,
    ));
  }
}
