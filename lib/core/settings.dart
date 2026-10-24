import 'models.dart';

/// Family-side monitoring settings.
class MonitorSettings {
  const MonitorSettings({
    this.startHour = 6,
    this.endHour = 23,
    this.paused = false,
    this.secondContactName = '',
  });

  /// No limits: monitor all day (start == end).
  static const allDay = MonitorSettings(startHour: 0, endHour: 0);

  final int startHour;
  final int endHour;
  final bool paused; // visitor / vacation mode
  final String secondContactName;

  bool isMonitoring(DateTime t) {
    if (startHour == endHour) return true;
    final h = t.hour;
    return startHour < endHour
        ? h >= startHour && h < endHour
        : h >= startHour || h < endHour;
  }

  /// Start of the current monitoring period (all day: midnight).
  DateTime periodStart(DateTime now) {
    final today = dayOf(now);
    if (startHour == endHour) return today;
    final c = today.add(Duration(hours: startHour));
    return now.isBefore(c) ? c.subtract(const Duration(days: 1)) : c;
  }

  MonitorSettings copyWith({
    int? startHour,
    int? endHour,
    bool? paused,
    String? secondContactName,
  }) => MonitorSettings(
    startHour: startHour ?? this.startHour,
    endHour: endHour ?? this.endHour,
    paused: paused ?? this.paused,
    secondContactName: secondContactName ?? this.secondContactName,
  );

  Map<String, dynamic> toJson() => {
    'startHour': startHour,
    'endHour': endHour,
    'paused': paused,
    'secondContactName': secondContactName,
  };

  factory MonitorSettings.fromJson(Map<String, dynamic> j) => MonitorSettings(
    startHour: j['startHour'] as int,
    endHour: j['endHour'] as int,
    paused: j['paused'] as bool,
    secondContactName: j['secondContactName'] as String,
  );
}

/// One alert episode, for the family's history list.
class AlertRecord {
  AlertRecord({
    required this.start,
    required this.explanation,
    this.maxLevel = AlertState.softCheck,
    this.resolvedAt,
    this.falseAlarm = false,
  });

  final DateTime start;
  final String explanation;
  AlertState maxLevel;
  DateTime? resolvedAt;
  bool falseAlarm;

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'explanation': explanation,
    'maxLevel': maxLevel.name,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'falseAlarm': falseAlarm,
  };

  factory AlertRecord.fromJson(Map<String, dynamic> j) => AlertRecord(
    start: DateTime.parse(j['start'] as String),
    explanation: j['explanation'] as String,
    maxLevel: AlertState.values.byName(j['maxLevel'] as String),
    resolvedAt: j['resolvedAt'] == null
        ? null
        : DateTime.parse(j['resolvedAt'] as String),
    falseAlarm: j['falseAlarm'] as bool,
  );
}
