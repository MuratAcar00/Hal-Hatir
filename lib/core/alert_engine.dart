import 'clock.dart';
import 'models.dart';
import 'rhythm.dart';
import 'settings.dart';

class _Trigger {
  const _Trigger(this.key, this.explanation);
  final String key;
  final String explanation;
}

/// normal -> soft_check -> family_alert -> second_contact_alert.
/// "İyiyim" or any new sensor event returns to normal.
class AlertEngine {
  AlertEngine(this.clock);

  final Clock clock;

  static const softCheckTimeout = Duration(minutes: 15);
  static const familyTimeout = Duration(minutes: 30);
  static const silenceLimit = Duration(hours: 10);

  AlertState state = AlertState.normal;
  DateTime? stateSince;
  String? explanation;
  DateTime? lastReset;
  // Deviations already answered, so they don't fire again the same day.
  final Set<String> handled = {};
  final List<AlertRecord> history = [];

  AlertRecord? get current =>
      state == AlertState.normal || history.isEmpty ? null : history.last;

  /// Evaluates triggers and escalation at clock.now().
  /// Outside monitoring hours no new alert starts; pause mode stops alerts.
  void tick(
    List<SensorEvent> events,
    Rhythm rhythm, {
    MonitorSettings settings = MonitorSettings.allDay,
  }) {
    final now = clock.now();
    if (settings.paused) {
      if (state != AlertState.normal) _reset(events, rhythm, settings);
      return;
    }
    if (state == AlertState.normal) {
      if (!settings.isMonitoring(now)) return;
      final due = _dueTriggers(now, events, rhythm, settings);
      if (due.isEmpty) return;
      explanation = due.first.explanation;
      history.add(AlertRecord(start: now, explanation: explanation!));
      _go(AlertState.softCheck, now);
    }
    if (state == AlertState.softCheck &&
        !now.isBefore(stateSince!.add(softCheckTimeout))) {
      _go(AlertState.familyAlert, stateSince!.add(softCheckTimeout));
    }
    if (state == AlertState.familyAlert &&
        !now.isBefore(stateSince!.add(familyTimeout))) {
      _go(AlertState.secondContactAlert, stateSince!.add(familyTimeout));
    }
  }

  /// "İyiyim" pressed.
  void acknowledge(
    List<SensorEvent> events,
    Rhythm rhythm, {
    MonitorSettings settings = MonitorSettings.allDay,
  }) => _reset(events, rhythm, settings);

  /// A new sensor event arrived ([events] already contains it).
  void onSensorEvent(
    List<SensorEvent> events,
    Rhythm rhythm, {
    MonitorSettings settings = MonitorSettings.allDay,
  }) {
    if (state != AlertState.normal) _reset(events, rhythm, settings);
  }

  /// Fresh day: forget today's handled deviations.
  void resetDay(DateTime day) {
    current?.resolvedAt = clock.now();
    handled.removeWhere((k) => k.startsWith(dayKey(day)));
    state = AlertState.normal;
    stateSince = null;
    explanation = null;
    lastReset = null;
  }

  void _reset(
    List<SensorEvent> events,
    Rhythm rhythm,
    MonitorSettings settings,
  ) {
    final now = clock.now();
    current?.resolvedAt = now;
    handled.addAll(
      _dueTriggers(now, events, rhythm, settings).map((t) => t.key),
    );
    state = AlertState.normal;
    stateSince = null;
    explanation = null;
    lastReset = now;
  }

  void _go(AlertState s, DateTime at) {
    state = s;
    stateSince = at;
    history.last.maxLevel = s;
  }

  List<_Trigger> _dueTriggers(
    DateTime now,
    List<SensorEvent> events,
    Rhythm rhythm,
    MonitorSettings settings,
  ) {
    final today = dayOf(now);
    final past = events.where((e) => !e.time.isAfter(now)).toList();
    final out = <_Trigger>[];

    // Routine deviation: expected first event missing after window end.
    for (final exp in rhythm.forDay(today)) {
      final key = '${dayKey(today)}|${exp.type.id}';
      if (handled.contains(key)) continue;
      final deadline = exp.deadlineOn(today);
      if (now.isBefore(deadline)) continue;
      if (past.any((e) => e.type == exp.type && sameDay(e.time, today))) {
        continue;
      }
      out.add(
        _Trigger(
          key,
          'Genelde ${exp.windowText} arası ${exp.type.habit}, '
          'bugün saat ${hm(deadline)} itibarıyla ${exp.type.missing}.',
        ),
      );
    }

    // Long silence: no event at all for silenceLimit.
    var start = settings.periodStart(now);
    for (final e in past) {
      if (e.time.isAfter(start)) start = e.time;
    }
    if (lastReset != null && lastReset!.isAfter(start)) start = lastReset!;
    final key = '${dayKey(today)}|silence|${start.toIso8601String()}';
    if (!handled.contains(key) && now.difference(start) >= silenceLimit) {
      out.add(
        _Trigger(
          key,
          'Genelde gün içinde ${silenceLimit.inHours} saatten uzun sessizlik '
          'olmuyor, saat ${hm(start)} sonrasında hiç hareket yok.',
        ),
      );
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'stateSince': stateSince?.toIso8601String(),
    'explanation': explanation,
    'lastReset': lastReset?.toIso8601String(),
    'handled': handled.toList(),
    'history': history.map((h) => h.toJson()).toList(),
  };

  void loadJson(Map<String, dynamic> j) {
    state = AlertState.values.byName(j['state'] as String);
    stateSince = _date(j['stateSince']);
    explanation = j['explanation'] as String?;
    lastReset = _date(j['lastReset']);
    handled
      ..clear()
      ..addAll((j['handled'] as List).cast<String>());
    history
      ..clear()
      ..addAll(
        ((j['history'] as List?) ?? const []).map(
          (h) => AlertRecord.fromJson(h as Map<String, dynamic>),
        ),
      );
  }

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
}
