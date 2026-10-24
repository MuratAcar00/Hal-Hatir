import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alert_engine.dart';
import 'clock.dart';
import 'models.dart';
import 'notifier.dart';
import 'rhythm.dart';
import 'seed.dart';
import 'settings.dart';

enum Role { home, family }

/// App-wide state: simulated clock, events, rhythm and alert engine.
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.clock, this.events) {
    engine = AlertEngine(clock);
    rhythm = Rhythm.learn(events, clock.now());
    _rhythmDay = dayOf(clock.now());
  }

  static const _kEvents = 'events';
  static const _kEngine = 'engine';
  static const _kSimNow = 'simNow';
  static const _kSpeed = 'speed';
  static const _kSettings = 'settings';
  static const _kLastAck = 'lastAckAt';
  static const _kPrivacySeen = 'privacySeen';

  final SharedPreferences _prefs;
  final SimClock clock;
  final List<SensorEvent> events;
  late final AlertEngine engine;
  late Rhythm rhythm;
  late DateTime _rhythmDay;
  Role? role;
  MonitorSettings settings = const MonitorSettings();
  int _ticks = 0;
  final notifier = AlertNotifier();
  bool privacySeen = false;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kEvents);
    final simNow = prefs.getString(_kSimNow);
    final start = simNow != null
        ? DateTime.parse(simNow)
        : dayOf(DateTime.now()).add(const Duration(hours: 6, minutes: 30));
    final events = raw != null ? _decodeEvents(raw) : seedHistory(start);
    final clock = SimClock(start)..setSpeed(prefs.getInt(_kSpeed) ?? 1);
    final s = AppState._(prefs, clock, events);
    final eng = prefs.getString(_kEngine);
    if (eng != null) s.engine.loadJson(jsonDecode(eng) as Map<String, dynamic>);
    final st = prefs.getString(_kSettings);
    if (st != null) {
      s.settings = MonitorSettings.fromJson(
        jsonDecode(st) as Map<String, dynamic>,
      );
    }
    final ack = prefs.getString(_kLastAck);
    if (ack != null) s.lastAckAt = DateTime.parse(ack);
    s.privacySeen = prefs.getBool(_kPrivacySeen) ?? false;
    clock
      ..addListener(s._onTick)
      ..start();
    s._save();
    unawaited(s.notifier.init().then((_) => s._notify()));
    return s;
  }

  /// Skips events of sensor types that no longer exist.
  static List<SensorEvent> _decodeEvents(String raw) {
    final out = <SensorEvent>[];
    for (final e in jsonDecode(raw) as List) {
      try {
        out.add(SensorEvent.fromJson(e as Map<String, dynamic>));
      } catch (_) {}
    }
    return out;
  }

  DateTime get now => clock.now();
  AlertState get alertState => engine.state;

  List<SensorEvent> eventsOn(DateTime day) =>
      events.where((e) => sameDay(e.time, day) && !e.time.isAfter(now)).toList()
        ..sort((a, b) => a.time.compareTo(b.time));

  SensorEvent? get lastEvent {
    SensorEvent? last;
    for (final e in events) {
      if (e.time.isAfter(now)) continue;
      if (last == null || e.time.isAfter(last.time)) last = e;
    }
    return last;
  }

  void setRole(Role? r) {
    role = r;
    notifyListeners();
  }

  void setSpeed(int s) {
    clock.setSpeed(s);
    _prefs.setInt(_kSpeed, s);
    _prefs.setString(_kSimNow, now.toIso8601String());
  }

  void markPrivacySeen() {
    privacySeen = true;
    _prefs.setBool(_kPrivacySeen, true);
    notifyListeners();
  }

  void addEvent(ActivityType type) {
    if (deviceOffline) return; // hub offline: event never arrives
    events.add(SensorEvent(type, now));
    engine.onSensorEvent(events, rhythm, settings: settings);
    _notify();
    _save();
    notifyListeners();
  }

  bool get deviceOffline => engine.deviceOffline;

  /// "Elektrik/İnternet Kes" toggle.
  void toggleOffline() {
    engine.setOffline(!deviceOffline, events, rhythm, settings: settings);
    _save();
    notifyListeners();
  }

  /// Family: "Evde kimse yok" -> freeze alarms via vacation mode.
  void confirmInactivity() {
    engine.confirmInactivity();
    updateSettings(settings.copyWith(paused: true));
    _save();
  }

  /// Last "İyiyim" time (shown to the family).
  DateTime? lastAckAt;

  void acknowledge() {
    lastAckAt = now;
    _prefs.setString(_kLastAck, now.toIso8601String());
    engine.acknowledge(events, rhythm, settings: settings);
    _notify();
    _save();
    notifyListeners();
  }

  void updateSettings(MonitorSettings s) {
    settings = s;
    _prefs.setString(_kSettings, jsonEncode(s.toJson()));
    _onTick();
  }

  void markFalseAlarm(AlertRecord r) {
    r.falseAlarm = true;
    _save();
    notifyListeners();
  }

  /// Clears today's events and sets the clock to 06:30.
  void startToday() {
    final day = dayOf(now);
    events.removeWhere((e) => sameDay(e.time, day));
    engine.resetDay(day);
    clock.set(day.add(const Duration(hours: 6, minutes: 30)));
    _save();
  }

  void _notify() => notifier.update(engine.state, engine.explanation);

  void _refreshRhythm() {
    final today = dayOf(now);
    if (today != _rhythmDay) {
      rhythm = Rhythm.learn(events, today);
      _rhythmDay = today;
    }
  }

  void _onTick() {
    _refreshRhythm();
    final before = engine.state;
    engine.tick(events, rhythm, settings: settings);
    if (engine.state != before) {
      _notify();
      _save();
    } else if (++_ticks % 10 == 0) {
      _save();
    }
    notifyListeners();
  }

  void _save() {
    _prefs.setString(
      _kEvents,
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
    _prefs.setString(_kEngine, jsonEncode(engine.toJson()));
    _prefs.setString(_kSimNow, now.toIso8601String());
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }
}
