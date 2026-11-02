import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('zh'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isZh => locale.languageCode == 'zh';

  // Navigation
  String get tabOverview => isZh ? '概览' : 'Overview';
  String get tabNodes => isZh ? '节点' : 'Nodes';
  String get tabSettings => isZh ? '设置' : 'Settings';

  // Dashboard
  String get vpnConnected => isZh ? '已安全连接' : 'Secured & Active';
  String get vpnConnecting => isZh ? '正在建立安全连接...' : 'Establishing Tunnel...';
  String get vpnDisconnected => isZh ? '未连接' : 'Disconnected';
  String get vpnDisconnecting => isZh ? '正在断开连接...' : 'Disconnecting...';
  String get tapToConnect => isZh ? '点击中心按钮开启安全隧道' : 'Tap to establish secure tunnel';
  String get tapToDisconnect => isZh ? '点击断开安全连接' : 'Tap to disconnect tunnel';
  String get uplink => isZh ? '实时上行' : 'UPLINK';
  String get downlink => isZh ? '实时下行' : 'DOWNLINK';
  String get totalTraffic => isZh ? '本次会话总流量' : 'SESSION TOTAL';
  String get monthlyUsage => isZh ? '本月已用' : 'Monthly Usage';
  String get activeNode => isZh ? '当前选中节点' : 'Active Node';
  String get noActiveNode => isZh ? '未选择节点' : 'No Node Selected';
  String get switchNode => isZh ? '更换节点' : 'Switch';

  // Nodes Screen
  String get nodesTitle => isZh ? '节点管理' : 'Nodes';
  String get addNode => isZh ? '添加节点' : 'Add Node';
  String get testAll => isZh ? '全部测速' : 'Ping All';
  String get sortByPing => isZh ? '延迟排序' : 'Sort by Ping';
  String get cleanTimeout => isZh ? '清理超时' : 'Clean Dead';
  String get searchNodes => isZh ? '搜索节点名称、协议或服务器...' : 'Search nodes, protocols, server...';
  String get hideTimeoutNodes => isZh ? '隐藏不可用节点' : 'Hide Timeout Nodes';
  String get deadNodesNotice => isZh ? '已检测到超时不可用节点' : 'Timeout dead nodes detected';
  String get oneClickClean => isZh ? '一键清理' : 'Clean All';
  String get importNodes => isZh ? '导入节点 / 订阅' : 'Import Nodes / Subscription';
  String get enterNodeOrSub => isZh ? '粘贴单节点链接或机场订阅链接 (Clash / Base64 / 节点URL)' : 'Paste node link or subscription URL (Clash, Base64, raw)';
  String get importBtn => isZh ? '确认导入' : 'Import';
  String get cancelBtn => isZh ? '取消' : 'Cancel';
  String get importSuccess => isZh ? '成功导入节点' : 'Successfully imported';
  String get noNodesFound => isZh ? '暂无可用节点' : 'No Nodes Available';
  String get noNodesFoundDesc => isZh ? '请导入单节点链接或机场订阅' : 'Import a single link or airport subscription';
  String get deleteNodeConfirm => isZh ? '确认删除该节点？' : 'Delete this node?';

  // Settings Screen
  String get settingsTitle => isZh ? '系统设置' : 'Settings';
  String get generalSection => isZh ? '通用设置' : 'General';
  String get languageTitle => isZh ? '显示语言' : 'Language';
  String get languageSubtitle => isZh ? '跟随系统或手动指定语言' : 'Follow system or choose custom display language';
  String get languageSystem => isZh ? '跟随系统' : 'System Default';
  String get languageZh => isZh ? '简体中文' : '简体中文 (Chinese)';
  String get languageEn => isZh ? 'English' : 'English';

  String get routingSection => isZh ? '分流与分组' : 'Routing & Groups';
  String get customRulesTitle => isZh ? '分流规则' : 'Routing Rules';
  String get customRulesSubtitle => isZh ? '为指定应用、域名、域名前缀单独设置路由' : 'Route specific apps, domains, prefixes';
  String get proxyGroupsTitle => isZh ? '代理分组' : 'Proxy Groups';
  String get proxyGroupsSubtitle => isZh ? '自动测速优选、手动选择、故障转移' : 'URL-Test auto-fastest, selector, fallback';
  String get subscriptionsTitle => isZh ? '订阅管理' : 'Subscriptions';
  String get subscriptionsSubtitle => isZh ? '管理机场订阅链接与自动静默同步' : 'Manage airport subs & 24h auto silent sync';
  String get appRoutingTitle => isZh ? '分应用代理' : 'Split Tunneling';
  String get appRoutingSubtitle => isZh ? '配置白名单模式或黑名单绕过模式' : 'Configure app whitelist or blacklist';

  String get networkSection => isZh ? '网络与统计' : 'Network & Statistics';
  String get lanSharingTitle => isZh ? '局域网共享' : 'LAN Proxy Sharing';
  String get lanSharingSubtitle => isZh ? '共享本机代理端口 (0.0.0.0:2080) 给同局域网其他设备' : 'Share proxy port (0.0.0.0:2080) to LAN devices';
  String get ipCopied => isZh ? '已复制代理地址' : 'Proxy address copied';
  String get monthlyTrafficTitle => isZh ? '月度流量配额' : 'Monthly Traffic Budget';
  String get monthlyTrafficSubtitle => isZh ? '实时监控每月使用量，支持超额预警' : 'Monitor usage with visual progress bar';
  String get unlimited => isZh ? '无限制' : 'Unlimited';

  String get platformSection => isZh ? '系统集成' : 'Platform Integration';
  String get winStartupTitle => isZh ? '开机自启动' : 'Launch on Startup';
  String get winStartupSubtitle => isZh ? 'Windows 开机自动在托盘静默运行' : 'Automatically run in background tray on Windows boot';
  String get batteryOptTitle => isZh ? '电池优化白名单' : 'Battery Keep-Alive';
  String get batteryOptSubtitle => isZh ? '允许后台长驻，避免被系统省电策略杀后台' : 'Ignore battery optimizations to keep tunnel active';
  String get batteryOptGranted => isZh ? '已获得后台长驻权限' : 'Protected from battery optimizations';
  String get batteryOptAction => isZh ? '前往开启' : 'Grant Permission';

  // Subscriptions Modal
  String get subscriptionsSheetTitle => isZh ? '机场订阅管理' : 'AIRPORT SUBSCRIPTIONS';
  String get subscriptionsSheetDesc => isZh ? '节点链接每日在后台静默自动同步更新' : 'Node links are automatically synchronized and updated in the background.';
  String get noSubscriptions => isZh ? '暂未添加任何订阅' : 'No Subscriptions Added';
  String get addSubscription => isZh ? '添加订阅' : 'Add Subscription';
  String get syncAll => isZh ? '全部同步' : 'Sync All';
  String get subNameHint => isZh ? '订阅名称 (例如: 我的主力机场)' : 'Subscription Name (e.g. My Fast Airport)';
  String get subUrlHint => isZh ? '订阅链接 (https://... 支持 Clash/Base64)' : 'Subscription URL (https://...)';
  String get saveAndFetch => isZh ? '保存并拉取' : 'Save & Fetch';
  String get syncSuccess => isZh ? '所有订阅已完成同步' : 'All subscriptions synchronized';
  String get pendingSync => isZh ? '等待同步' : 'Pending sync';
  String get updatedAt => isZh ? '更新于' : 'Updated';

  // Common Dialogs & Actions
  String get confirm => isZh ? '确定' : 'Confirm';
  String get delete => isZh ? '删除' : 'Delete';
  String get save => isZh ? '保存' : 'Save';
  String get reset => isZh ? '重置' : 'Reset';
  String get enabled => isZh ? '已启用' : 'Enabled';
  String get disabled => isZh ? '已关闭' : 'Disabled';
  String get copied => isZh ? '已复制到剪贴板' : 'Copied to clipboard';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this);
}
