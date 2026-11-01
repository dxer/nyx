import 'dart:convert';
import 'dart:io';
import '../../models/proxy_node.dart';
import '../../models/subscription.dart';
import '../parser/node_link_parser.dart';

class SubscriptionService {
  /// Fetches subscription content from remote URL and parses proxy nodes
  static Future<List<ProxyNode>> fetchNodes(String url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      final uri = Uri.parse(url.trim());
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'sing-box/1.13.0 Nyx/1.0.0 ClashMeta');
      request.headers.set('Accept', '*/*');

      final response = await request.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = await response.transform(utf8.decoder).join();
        return NodeLinkParser.parseAny(body);
      }
    } catch (_) {
      // Return empty list on failure
    } finally {
      client.close();
    }
    return [];
  }
}
