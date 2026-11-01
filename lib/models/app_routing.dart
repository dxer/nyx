enum AppRoutingMode {
  all,        // All apps use VPN
  allowlist,  // Only selected apps use VPN (Proxy only selected)
  blocklist;  // Selected apps bypass VPN (Direct bypass)

  String get label {
    switch (this) {
      case AppRoutingMode.all:
        return 'All Apps Proxied';
      case AppRoutingMode.allowlist:
        return 'Whitelist (Only Selected)';
      case AppRoutingMode.blocklist:
        return 'Blacklist (Bypass Selected)';
    }
  }

  String get description {
    switch (this) {
      case AppRoutingMode.all:
        return 'Route all application traffic through the VPN tunnel';
      case AppRoutingMode.allowlist:
        return 'Only checked apps will be routed through the VPN';
      case AppRoutingMode.blocklist:
        return 'Checked domestic apps will bypass the VPN directly';
    }
  }
}

class AppInfo {
  final String packageName;
  final String appName;
  final bool isSystemApp;

  const AppInfo({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'isSystemApp': isSystemApp,
  };

  factory AppInfo.fromJson(Map<String, dynamic> json) => AppInfo(
    packageName: json['packageName'] as String,
    appName: json['appName'] as String,
    isSystemApp: json['isSystemApp'] as bool? ?? false,
  );
}

class AppRoutingConfig {
  final AppRoutingMode mode;
  final Set<String> selectedPackages;

  const AppRoutingConfig({
    this.mode = AppRoutingMode.all,
    this.selectedPackages = const {},
  });

  AppRoutingConfig copyWith({
    AppRoutingMode? mode,
    Set<String>? selectedPackages,
  }) {
    return AppRoutingConfig(
      mode: mode ?? this.mode,
      selectedPackages: selectedPackages ?? this.selectedPackages,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'selectedPackages': selectedPackages.toList(),
  };

  factory AppRoutingConfig.fromJson(Map<String, dynamic> json) => AppRoutingConfig(
    mode: AppRoutingMode.values.firstWhere(
      (m) => m.name == json['mode'],
      orElse: () => AppRoutingMode.all,
    ),
    selectedPackages: (json['selectedPackages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        {},
  );
}
