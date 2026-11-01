import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monthly_traffic.dart';
import '../models/traffic_stats.dart';
import 'services_provider.dart';

final trafficStreamProvider = StreamProvider<TrafficStats>((ref) {
  final singbox = ref.watch(singBoxServiceProvider);
  return singbox.trafficStream;
});

final trafficStatsProvider = Provider<TrafficStats>((ref) {
  final asyncTraffic = ref.watch(trafficStreamProvider);
  return asyncTraffic.value ?? const TrafficStats();
});

class MonthlyTrafficNotifier extends StateNotifier<MonthlyTraffic> {
  final Ref _ref;
  int _lastSessionTotal = 0;

  MonthlyTrafficNotifier(this._ref, MonthlyTraffic initial) : super(initial) {
    _listenToTraffic();
  }

  void _listenToTraffic() {
    _ref.listen<TrafficStats>(trafficStatsProvider, (prev, next) {
      final currentTotal = next.uplinkTotal + next.downlinkTotal;
      if (_lastSessionTotal == 0) {
        _lastSessionTotal = currentTotal;
        return;
      }

      if (currentTotal > _lastSessionTotal) {
        final delta = currentTotal - _lastSessionTotal;
        _lastSessionTotal = currentTotal;
        addUsageBytes(delta);
      } else if (currentTotal < _lastSessionTotal) {
        // Core reconnected or restarted
        _lastSessionTotal = currentTotal;
      }
    });
  }

  void addUsageBytes(int bytes) {
    final currentPeriod = _getCurrentPeriod();
    final storage = _ref.read(storageServiceProvider);

    if (state.period != currentPeriod) {
      // Month rolled over -> reset for new month
      state = state.copyWith(period: currentPeriod, usedBytes: bytes);
      storage.setMonthlyPeriod(currentPeriod);
      storage.setMonthlyUsedBytes(bytes);
    } else {
      final newTotal = state.usedBytes + bytes;
      state = state.copyWith(usedBytes: newTotal);
      storage.setMonthlyUsedBytes(newTotal);
    }
  }

  void setQuotaGigabytes(int quotaGb) {
    state = state.copyWith(quotaGigabytes: quotaGb);
    _ref.read(storageServiceProvider).setMonthlyQuotaGb(quotaGb);
  }

  void resetUsage() {
    state = state.copyWith(usedBytes: 0);
    _ref.read(storageServiceProvider).setMonthlyUsedBytes(0);
  }

  static String _getCurrentPeriod() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }
}

final monthlyTrafficProvider = StateNotifierProvider<MonthlyTrafficNotifier, MonthlyTraffic>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final currentPeriod = MonthlyTrafficNotifier._getCurrentPeriod();

  var savedPeriod = storage.getMonthlyPeriod();
  var savedUsed = storage.getMonthlyUsedBytes();
  final savedQuota = storage.getMonthlyQuotaGb();

  if (savedPeriod != currentPeriod) {
    savedPeriod = currentPeriod;
    savedUsed = 0;
    storage.setMonthlyPeriod(currentPeriod);
    storage.setMonthlyUsedBytes(0);
  }

  final initial = MonthlyTraffic(
    period: savedPeriod,
    usedBytes: savedUsed,
    quotaGigabytes: savedQuota,
  );

  return MonthlyTrafficNotifier(ref, initial);
});
