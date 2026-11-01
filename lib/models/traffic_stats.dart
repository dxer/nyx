class TrafficStats {
  final int uplinkSpeed;     // Bytes per second
  final int downlinkSpeed;   // Bytes per second
  final int uplinkTotal;     // Total bytes uploaded
  final int downlinkTotal;   // Total bytes downloaded

  const TrafficStats({
    this.uplinkSpeed = 0,
    this.downlinkSpeed = 0,
    this.uplinkTotal = 0,
    this.downlinkTotal = 0,
  });

  TrafficStats copyWith({
    int? uplinkSpeed,
    int? downlinkSpeed,
    int? uplinkTotal,
    int? downlinkTotal,
  }) {
    return TrafficStats(
      uplinkSpeed: uplinkSpeed ?? this.uplinkSpeed,
      downlinkSpeed: downlinkSpeed ?? this.downlinkSpeed,
      uplinkTotal: uplinkTotal ?? this.uplinkTotal,
      downlinkTotal: downlinkTotal ?? this.downlinkTotal,
    );
  }
}
