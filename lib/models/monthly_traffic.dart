class MonthlyTraffic {
  final String period; // e.g. "2026-11"
  final int usedBytes; // total bytes used this month
  final int quotaGigabytes; // e.g. 200 GB, 0 = unlimited

  const MonthlyTraffic({
    required this.period,
    this.usedBytes = 0,
    this.quotaGigabytes = 0,
  });

  bool get hasQuota => quotaGigabytes > 0;
  int get quotaBytes => quotaGigabytes * 1024 * 1024 * 1024;
  double get progress => hasQuota ? (usedBytes / quotaBytes).clamp(0.0, 1.0) : 0.0;
  bool get isWarning => hasQuota && progress >= 0.8;
  bool get isExceeded => hasQuota && progress >= 1.0;

  MonthlyTraffic copyWith({
    String? period,
    int? usedBytes,
    int? quotaGigabytes,
  }) {
    return MonthlyTraffic(
      period: period ?? this.period,
      usedBytes: usedBytes ?? this.usedBytes,
      quotaGigabytes: quotaGigabytes ?? this.quotaGigabytes,
    );
  }
}
