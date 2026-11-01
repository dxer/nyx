import 'dart:convert';
import 'package:yaml/yaml.dart';
import '../../core/utils/safe_url_decoder.dart';
import '../../models/proxy_node.dart';

class NodeLinkParser {
  /// Parses any input text:
  /// 1. Single link (vless, vmess, ss, trojan, hysteria2)
  /// 2. Multi-line links
  /// 3. Base64 encoded subscription (standard airport subscription)
  /// 4. Clash / Mihomo YAML subscription
  static List<ProxyNode> parseAny(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return [];

    // 1. Try Clash / Mihomo YAML configuration
    if (trimmed.contains('proxies:') || trimmed.startsWith('port:') || trimmed.startsWith('mode:')) {
      final yamlNodes = _parseClashYaml(trimmed);
      if (yamlNodes.isNotEmpty) return yamlNodes;
    }

    // 2. Try Base64 airport subscription
    if (!trimmed.contains('://') && trimmed.length > 20) {
      try {
        final decoded = utf8.decode(base64Decode(base64.normalize(trimmed.replaceAll(RegExp(r'\s+'), ''))));
        if (decoded.contains('://')) {
          return _parseMultiLineLinks(decoded);
        }
      } catch (_) {
        // Not a valid base64 subscription, continue
      }
    }

    // 3. Multi-line or single link parsing
    return _parseMultiLineLinks(trimmed);
  }

  static List<ProxyNode> _parseMultiLineLinks(String text) {
    final results = <ProxyNode>[];
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final node = parse(trimmed);
      if (node != null) results.add(node);
    }
    return results;
  }

  static List<ProxyNode> _parseClashYaml(String yamlContent) {
    final nodes = <ProxyNode>[];
    try {
      final doc = loadYaml(yamlContent);
      if (doc is! Map || !doc.containsKey('proxies')) return [];

      final proxies = doc['proxies'];
      if (proxies is! List) return [];

      for (final p in proxies) {
        if (p is! Map) continue;
        final type = (p['type']?.toString() ?? '').toLowerCase();
        final name = p['name']?.toString() ?? 'Proxy';
        final server = p['server']?.toString() ?? '';
        final port = int.tryParse(p['port']?.toString() ?? '') ?? 0;

        if (server.isEmpty || port <= 0) continue;

        switch (type) {
          case 'vless':
            final uuid = p['uuid']?.toString() ?? '';
            final outbound = <String, dynamic>{
              'type': 'vless',
              'tag': name,
              'server': server,
              'server_port': port,
              'uuid': uuid,
              'flow': p['flow']?.toString(),
            };
            if (p['reality-opts'] is Map) {
              final reality = p['reality-opts'] as Map;
              outbound['tls'] = {
                'enabled': true,
                'server_name': p['servername']?.toString() ?? server,
                'reality': {
                  'enabled': true,
                  'public_key': reality['public-key']?.toString(),
                  'short_id': reality['short-id']?.toString(),
                },
                'utls': {
                  'enabled': true,
                  'fingerprint': p['client-fingerprint']?.toString() ?? 'chrome',
                }
              };
            } else if (p['tls'] == true) {
              outbound['tls'] = {
                'enabled': true,
                'server_name': p['servername']?.toString() ?? server,
                'insecure': p['skip-cert-verify'] == true,
              };
            }
            nodes.add(ProxyNode(
              id: 'vless_${server}_$port',
              name: name,
              protocol: 'VLESS',
              server: server,
              port: port,
              rawConfig: outbound,
            ));
            break;

          case 'ss':
            final cipher = p['cipher']?.toString() ?? 'chacha20-ietf-poly1305';
            final password = p['password']?.toString() ?? '';
            nodes.add(ProxyNode(
              id: 'ss_${server}_$port',
              name: name,
              protocol: 'Shadowsocks',
              server: server,
              port: port,
              rawConfig: {
                'type': 'shadowsocks',
                'tag': name,
                'server': server,
                'server_port': port,
                'method': cipher,
                'password': password,
              },
            ));
            break;

          case 'trojan':
            final password = p['password']?.toString() ?? '';
            nodes.add(ProxyNode(
              id: 'trojan_${server}_$port',
              name: name,
              protocol: 'Trojan',
              server: server,
              port: port,
              rawConfig: {
                'type': 'trojan',
                'tag': name,
                'server': server,
                'server_port': port,
                'password': password,
                'tls': {
                  'enabled': true,
                  'server_name': p['sni']?.toString() ?? p['servername']?.toString() ?? server,
                  'insecure': p['skip-cert-verify'] == true,
                }
              },
            ));
            break;

          case 'hysteria2':
          case 'hy2':
            final password = p['password']?.toString() ?? '';
            nodes.add(ProxyNode(
              id: 'hy2_${server}_$port',
              name: name,
              protocol: 'Hysteria2',
              server: server,
              port: port,
              rawConfig: {
                'type': 'hysteria2',
                'tag': name,
                'server': server,
                'server_port': port,
                'password': password,
                'tls': {
                  'enabled': true,
                  'server_name': p['sni']?.toString() ?? server,
                  'insecure': p['skip-cert-verify'] == true,
                }
              },
            ));
            break;

          case 'vmess':
            final uuid = p['uuid']?.toString() ?? '';
            nodes.add(ProxyNode(
              id: 'vmess_${server}_$port',
              name: name,
              protocol: 'VMess',
              server: server,
              port: port,
              rawConfig: {
                'type': 'vmess',
                'tag': name,
                'server': server,
                'server_port': port,
                'uuid': uuid,
                'security': p['cipher']?.toString() ?? 'auto',
              },
            ));
            break;
        }
      }
    } catch (_) {}
    return nodes;
  }

  static ProxyNode? parse(String link) {
    final trimmed = link.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('vless://')) return _parseVless(trimmed);
    if (trimmed.startsWith('vmess://')) return _parseVmess(trimmed);
    if (trimmed.startsWith('ss://')) return _parseShadowsocks(trimmed);
    if (trimmed.startsWith('trojan://')) return _parseTrojan(trimmed);
    if (trimmed.startsWith('hysteria2://') || trimmed.startsWith('hy2://')) {
      return _parseHysteria2(trimmed);
    }
    return null;
  }

  static ProxyNode? _parseVless(String link) {
    try {
      final uri = Uri.parse(link);
      final uuid = uri.userInfo;
      final server = uri.host;
      final port = uri.port;
      final name = safeUrlDecode(uri.fragment.isNotEmpty ? uri.fragment : '$server:$port');
      final params = uri.queryParameters;

      if (uuid.isEmpty || server.isEmpty || port <= 0) return null;

      final outbound = <String, dynamic>{
        'type': 'vless',
        'tag': name,
        'server': server,
        'server_port': port,
        'uuid': uuid,
        'flow': params['flow'],
      };

      if (params['security'] == 'reality') {
        outbound['tls'] = {
          'enabled': true,
          'server_name': params['sni'] ?? server,
          'reality': {
            'enabled': true,
            'public_key': params['pbk'],
            'short_id': params['sid'],
          },
          'utls': {
            'enabled': true,
            'fingerprint': params['fp'] ?? 'chrome',
          }
        };
      } else if (params['security'] == 'tls') {
        outbound['tls'] = {
          'enabled': true,
          'server_name': params['sni'] ?? server,
          'insecure': params['allowInsecure'] == '1',
        };
      }

      return ProxyNode(
        id: 'vless_${server}_$port',
        name: name,
        protocol: 'VLESS',
        server: server,
        port: port,
        rawConfig: outbound,
      );
    } catch (_) {
      return null;
    }
  }

  static ProxyNode? _parseTrojan(String link) {
    try {
      final uri = Uri.parse(link);
      final password = uri.userInfo;
      final server = uri.host;
      final port = uri.port;
      final name = safeUrlDecode(uri.fragment.isNotEmpty ? uri.fragment : '$server:$port');
      final params = uri.queryParameters;

      if (password.isEmpty || server.isEmpty || port <= 0) return null;

      final outbound = <String, dynamic>{
        'type': 'trojan',
        'tag': name,
        'server': server,
        'server_port': port,
        'password': password,
        'tls': {
          'enabled': true,
          'server_name': params['sni'] ?? server,
          'insecure': params['allowInsecure'] == '1',
        }
      };

      return ProxyNode(
        id: 'trojan_${server}_$port',
        name: name,
        protocol: 'Trojan',
        server: server,
        port: port,
        rawConfig: outbound,
      );
    } catch (_) {
      return null;
    }
  }

  static ProxyNode? _parseHysteria2(String link) {
    try {
      final uri = Uri.parse(link);
      final auth = uri.userInfo;
      final server = uri.host;
      final port = uri.port;
      final name = safeUrlDecode(uri.fragment.isNotEmpty ? uri.fragment : '$server:$port');
      final params = uri.queryParameters;

      if (server.isEmpty || port <= 0) return null;

      final outbound = <String, dynamic>{
        'type': 'hysteria2',
        'tag': name,
        'server': server,
        'server_port': port,
        'password': auth,
        'tls': {
          'enabled': true,
          'server_name': params['sni'] ?? server,
          'insecure': params['insecure'] == '1',
        }
      };

      return ProxyNode(
        id: 'hy2_${server}_$port',
        name: name,
        protocol: 'Hysteria2',
        server: server,
        port: port,
        rawConfig: outbound,
      );
    } catch (_) {
      return null;
    }
  }

  static ProxyNode? _parseShadowsocks(String link) {
    try {
      final uri = Uri.parse(link);
      String rawUserInfo = uri.userInfo;
      String server = uri.host;
      int port = uri.port;
      String name = safeUrlDecode(uri.fragment.isNotEmpty ? uri.fragment : '$server:$port');

      String method = '';
      String password = '';

      if (rawUserInfo.contains(':')) {
        final parts = rawUserInfo.split(':');
        method = parts[0];
        password = parts.sublist(1).join(':');
      } else {
        final decoded = utf8.decode(base64Decode(base64.normalize(rawUserInfo)));
        final parts = decoded.split(':');
        method = parts[0];
        password = parts.sublist(1).join(':');
      }

      if (server.isEmpty || port <= 0) return null;

      final outbound = {
        'type': 'shadowsocks',
        'tag': name,
        'server': server,
        'server_port': port,
        'method': method,
        'password': password,
      };

      return ProxyNode(
        id: 'ss_${server}_$port',
        name: name,
        protocol: 'Shadowsocks',
        server: server,
        port: port,
        rawConfig: outbound,
      );
    } catch (_) {
      return null;
    }
  }

  static ProxyNode? _parseVmess(String link) {
    try {
      final rawBase64 = link.substring('vmess://'.length).trim();
      final decodedJson = utf8.decode(base64Decode(base64.normalize(rawBase64)));
      final map = jsonDecode(decodedJson) as Map<String, dynamic>;

      final server = map['add']?.toString() ?? '';
      final port = int.tryParse(map['port']?.toString() ?? '') ?? 0;
      final uuid = map['id']?.toString() ?? '';
      final name = map['ps']?.toString() ?? '$server:$port';

      if (server.isEmpty || port <= 0 || uuid.isEmpty) return null;

      final outbound = {
        'type': 'vmess',
        'tag': name,
        'server': server,
        'server_port': port,
        'uuid': uuid,
        'security': 'auto',
      };

      return ProxyNode(
        id: 'vmess_${server}_$port',
        name: name,
        protocol: 'VMess',
        server: server,
        port: port,
        rawConfig: outbound,
      );
    } catch (_) {
      return null;
    }
  }
}
