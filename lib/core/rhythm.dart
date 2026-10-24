import 'dart:math';

import 'models.dart';

/// Learned window for one activity on weekdays or weekends.
class Expectation {
  const Expectation({
    required this.type,
    required this.weekend,
    required this.medianMin,
    required this.toleranceMin,
    required this.samples,
  });

  final ActivityType type;
  final bool weekend;
  final int medianMin;
  final int toleranceMin;
  final int samples;

  int get startMin => medianMin - toleranceMin;
  int get endMin => medianMin + toleranceMin;

  String get windowText => '${minToHm(startMin)}-${minToHm(endMin)}';

  /// After this moment a missing activity counts as a routine deviation.
  DateTime deadlineOn(DateTime day) =>
      dayOf(day).add(Duration(minutes: endMin));
}

/// Daily rhythm learned from each day's first event per activity.
/// Window = median +/- max(1.5 * std, 45 min); weekdays and weekends apart.
class Rhythm {
  Rhythm(this._map);

  static const minToleranceMin = 45;
  // Activities seen on fewer days than this share are not "daily" (e.g. door).
  static const minDailyShare = 0.6;

  final Map<String, Expectation> _map;

  static String _key(ActivityType t, bool weekend) => '${t.id}|$weekend';

  Expectation? get(ActivityType t, bool weekend) => _map[_key(t, weekend)];

  List<Expectation> forDay(DateTime day) => ActivityType.values
      .map((t) => get(t, isWeekend(day)))
      .whereType<Expectation>()
      .toList();

  /// Learns from the [days] days before [today] (today excluded).
  factory Rhythm.learn(
    List<SensorEvent> events,
    DateTime today, {
    int days = 14,
  }) {
    final start = DateTime(today.year, today.month, today.day - days);
    final end = dayOf(today);
    final first = <String, int>{};
    for (final e in events) {
      if (e.time.isBefore(start) || !e.time.isBefore(end)) continue;
      final k = '${dayKey(e.time)}|${e.type.id}';
      final m = minuteOfDay(e.time);
      first[k] = min(first[k] ?? m, m);
    }

    final allDays = [
      for (var i = 0; i < days; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
    final map = <String, Expectation>{};
    for (final weekend in [false, true]) {
      final group = allDays.where((d) => isWeekend(d) == weekend).toList();
      if (group.isEmpty) continue;
      for (final t in ActivityType.values) {
        final samples = group
            .map((d) => first['${dayKey(d)}|${t.id}'])
            .whereType<int>()
            .toList();
        if (samples.length < 2 ||
            samples.length < group.length * minDailyShare) {
          continue;
        }
        final tol = max(1.5 * stdDev(samples), minToleranceMin.toDouble());
        map[_key(t, weekend)] = Expectation(
          type: t,
          weekend: weekend,
          medianMin: median(samples).round(),
          toleranceMin: tol.round(),
          samples: samples.length,
        );
      }
    }
    return Rhythm(map);
  }

  static double median(List<int> xs) {
    final s = [...xs]..sort();
    final n = s.length;
    return n.isOdd ? s[n ~/ 2].toDouble() : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
  }

  static double stdDev(List<int> xs) {
    final mean = xs.reduce((a, b) => a + b) / xs.length;
    final v =
        xs.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
        xs.length;
    return sqrt(v);
  }
}
