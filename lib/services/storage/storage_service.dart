import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_routing.dart';
import '../../models/custom_rule.dart';
import '../../models/proxy_group.dart';
import '../../models/proxy_node.dart';
import '../../models/subscription.dart';

class StorageService {
  static const String _keyNodes = 'saved_proxy_nodes';
  static const String _keySelectedNodeId = 'selected_node_id';
  static const String _keySubscriptions = 'saved_subscriptions';
  static const String _keyBypassChina = 'setting_bypass_china';
  static const String _keyAutoConnect = 'setting_auto_connect';
  static const String _keyAppRouting = 'setting_app_routing';
  static const String _keyCustomRules = 'setting_custom_rules';
  static const String _keyProxyGroups = 'setting_proxy_groups';
  static const String _keyAllowLan = 'setting_allow_lan';
  static const String _keyCloseToTray = 'setting_close_to_tray';
  static const String _keyLaunchOnStartup = 'setting_launch_on_startup';
  static const String _keyAutoUpdateSubscriptions = 'setting_auto_update_subs';
  static const String _keyMonthlyUsedBytes = 'traffic_monthly_used_bytes';
  static const String _keyMonthlyQuotaGb = 'traffic_monthly_quota_gb';
  static const String _keyMonthlyPeriod = 'traffic_monthly_period';
  static const String _keyAppLanguage = 'setting_app_language'; // 'system', 'zh', 'en'

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Nodes
  List<ProxyNode> loadNodes() {
    final jsonList = _prefs.getStringList(_keyNodes) ?? [];
    return jsonList.map((item) {
      try {
        return ProxyNode.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<ProxyNode>().toList();
  }

  Future<bool> saveNodes(List<ProxyNode> nodes) async {
    final jsonList = nodes.map((n) => jsonEncode(n.toJson())).toList();
    return await _prefs.setStringList(_keyNodes, jsonList);
  }

  String? getSelectedNodeId() {
    return _prefs.getString(_keySelectedNodeId);
  }

  Future<bool> setSelectedNodeId(String? id) async {
    if (id == null) {
      return await _prefs.remove(_keySelectedNodeId);
    }
    return await _prefs.setString(_keySelectedNodeId, id);
  }

  // Subscriptions
  List<Subscription> loadSubscriptions() {
    final jsonList = _prefs.getStringList(_keySubscriptions) ?? [];
    return jsonList.map((item) {
      try {
        return Subscription.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Subscription>().toList();
  }

  Future<bool> saveSubscriptions(List<Subscription> subs) async {
    final jsonList = subs.map((s) => jsonEncode(s.toJson())).toList();
    return await _prefs.setStringList(_keySubscriptions, jsonList);
  }

  // Settings
  bool getBypassChina() => _prefs.getBool(_keyBypassChina) ?? true;
  Future<bool> setBypassChina(bool value) => _prefs.setBool(_keyBypassChina, value);

  bool getAutoConnect() => _prefs.getBool(_keyAutoConnect) ?? false;
  Future<bool> setAutoConnect(bool value) => _prefs.setBool(_keyAutoConnect, value);

  bool getAllowLan() => _prefs.getBool(_keyAllowLan) ?? false;
  Future<bool> setAllowLan(bool value) => _prefs.setBool(_keyAllowLan, value);

  bool getCloseToTray() => _prefs.getBool(_keyCloseToTray) ?? true;
  Future<bool> setCloseToTray(bool value) => _prefs.setBool(_keyCloseToTray, value);

  bool getLaunchOnStartup() => _prefs.getBool(_keyLaunchOnStartup) ?? false;
  Future<bool> setLaunchOnStartup(bool value) => _prefs.setBool(_keyLaunchOnStartup, value);

  bool getAutoUpdateSubscriptions() => _prefs.getBool(_keyAutoUpdateSubscriptions) ?? true;
  Future<bool> setAutoUpdateSubscriptions(bool value) => _prefs.setBool(_keyAutoUpdateSubscriptions, value);

  // Monthly Traffic Data
  int getMonthlyUsedBytes() => _prefs.getInt(_keyMonthlyUsedBytes) ?? 0;
  Future<bool> setMonthlyUsedBytes(int value) => _prefs.setInt(_keyMonthlyUsedBytes, value);

  int getMonthlyQuotaGb() => _prefs.getInt(_keyMonthlyQuotaGb) ?? 0; // 0 = unlimited
  Future<bool> setMonthlyQuotaGb(int value) => _prefs.setInt(_keyMonthlyQuotaGb, value);

  String getMonthlyPeriod() => _prefs.getString(_keyMonthlyPeriod) ?? '';
  Future<bool> setMonthlyPeriod(String value) => _prefs.setString(_keyMonthlyPeriod, value);

  // Per-App Routing
  AppRoutingConfig loadAppRoutingConfig() {
    final raw = _prefs.getString(_keyAppRouting);
    if (raw == null) return const AppRoutingConfig();
    try {
      return AppRoutingConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppRoutingConfig();
    }
  }

  Future<bool> saveAppRoutingConfig(AppRoutingConfig config) async {
    return await _prefs.setString(_keyAppRouting, jsonEncode(config.toJson()));
  }

  // Custom Rules
  List<CustomRule> loadCustomRules() {
    final jsonList = _prefs.getStringList(_keyCustomRules) ?? [];
    return jsonList.map((item) {
      try {
        return CustomRule.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<CustomRule>().toList();
  }

  Future<bool> saveCustomRules(List<CustomRule> rules) async {
    final jsonList = rules.map((r) => jsonEncode(r.toJson())).toList();
    return await _prefs.setStringList(_keyCustomRules, jsonList);
  }

  // Proxy Groups
  List<ProxyGroup> loadProxyGroups() {
    final jsonList = _prefs.getStringList(_keyProxyGroups) ?? [];
    return jsonList.map((item) {
      try {
        return ProxyGroup.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<ProxyGroup>().toList();
  }

  Future<bool> saveProxyGroups(List<ProxyGroup> groups) async {
    final jsonList = groups.map((g) => jsonEncode(g.toJson())).toList();
    return await _prefs.setStringList(_keyProxyGroups, jsonList);
  }

  // Language
  String loadAppLanguage() {
    return _prefs.getString(_keyAppLanguage) ?? 'system';
  }

  Future<bool> saveAppLanguage(String language) async {
    return await _prefs.setString(_keyAppLanguage, language);
  }
}
