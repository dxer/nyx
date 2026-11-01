class Formatters {
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(count >= 100 || i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  static String formatSpeed(int bytesPerSecond) {
    return '${formatBytes(bytesPerSecond)}/s';
  }

  static String formatLatency(int? latencyMs) {
    if (latencyMs == null || latencyMs < 0) return '-';
    if (latencyMs == 0) return 'Timeout';
    return '${latencyMs}ms';
  }
}
