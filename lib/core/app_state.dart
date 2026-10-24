import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alert_engine.dart';
import 'clock.dart';
import 'models.dart';
import 'rhythm.dart';
import 'seed.dart';

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

  final SharedPreferences _prefs;
  final SimClock clock;
  final List<SensorEvent> events;
  late final AlertEngine engine;
  late Rhythm rhythm;
  late DateTime _rhythmDay;
  Role? role;
  int _ticks = 0;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kEvents);
    final simNow = prefs.getString(_kSimNow);
    final start = simNow != null
        ? DateTime.parse(simNow)
        : dayOf(DateTime.now()).add(const Duration(hours: 6, minutes: 30));
    final events = raw != null
        ? (jsonDecode(raw) as List)
              .map((e) => SensorEvent.fromJson(e as Map<String, dynamic>))
              .toList()
        : seedHistory(start);
    final clock = SimClock(start)..setSpeed(prefs.getInt(_kSpeed) ?? 1);
    final s = AppState._(prefs, clock, events);
    final eng = prefs.getString(_kEngine);
    if (eng != null) s.engine.loadJson(jsonDecode(eng) as Map<String, dynamic>);
    clock
      ..addListener(s._onTick)
      ..start();
    s._save();
    return s;
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
  }

  void addEvent(ActivityType type) {
    events.add(SensorEvent(type, now));
    engine.onSensorEvent(events, rhythm);
    _save();
    notifyListeners();
  }

  void acknowledge() {
    engine.acknowledge(events, rhythm);
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

  /// Demo scenario: no morning events, jump just past the first deadline.
  void skipMorning() {
    startToday();
    final deadlines = rhythm.forDay(now).map((e) => e.deadlineOn(now)).toList()
      ..sort();
    if (deadlines.isNotEmpty) {
      clock.set(deadlines.first.add(const Duration(minutes: 1)));
    }
    setSpeed(60);
  }

  void _onTick() {
    final today = dayOf(now);
    if (today != _rhythmDay) {
      rhythm = Rhythm.learn(events, today);
      _rhythmDay = today;
    }
    final before = engine.state;
    engine.tick(events, rhythm);
    if (engine.state != before || ++_ticks % 10 == 0) _save();
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
