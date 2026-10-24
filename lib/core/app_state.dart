import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alert_engine.dart';
import 'clock.dart';
import 'medical.dart';
import 'models.dart';
import 'notifier.dart';
import 'rhythm.dart';
import 'seed.dart';
import 'settings.dart';

enum Role { home, family }

/// App-wide state: simulated clock, events, rhythm and alert engine.
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.clock, this.events, this.medical) {
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
  static const _kMedical = 'medical';

  final SharedPreferences _prefs;
  final SimClock clock;
  final List<SensorEvent> events;
  final List<MedicalReading> medical;
  late final AlertEngine engine;
  late Rhythm rhythm;
  late DateTime _rhythmDay;
  Role? role;
  MonitorSettings settings = const MonitorSettings();
  int _ticks = 0;
  final notifier = AlertNotifier();
  bool privacySeen = false;

  // Guided demo: step label (null when not running) and its timers.
  String? demoLabel;
  int _demoStep = 0;
  final List<Timer> _demoTimers = [];

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
    final medRaw = prefs.getString(_kMedical);
    final medical = medRaw != null
        ? (jsonDecode(medRaw) as List)
              .map((e) => MedicalReading.fromJson(e as Map<String, dynamic>))
              .toList()
        : seedMedical(start);
    final s = AppState._(prefs, clock, events, medical);
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

  /// Simulated medical device reading (hub must be online).
  void addMedical(MedicalKind kind, {int? score}) {
    if (deviceOffline) return;
    medical.add(MedicalReading(kind, now, score: score));
    _save();
    notifyListeners();
  }

  MedicalReading? lastMedical(MedicalKind kind) {
    MedicalReading? last;
    for (final r in medical) {
      if (r.kind != kind || r.time.isAfter(now)) continue;
      if (last == null || r.time.isAfter(last.time)) last = r;
    }
    return last;
  }

  /// No blood pressure or glucose reading for 48 simulated hours.
  bool get medicalDataStale {
    final bp = lastMedical(MedicalKind.bloodPressure)?.time;
    final gl = lastMedical(MedicalKind.glucose)?.time;
    final times = [bp, gl].whereType<DateTime>();
    if (times.isEmpty) return false;
    final last = times.reduce((a, b) => a.isAfter(b) ? a : b);
    return !now.isBefore(last.add(const Duration(hours: 48)));
  }

  /// Yellow family banner: stale data, no other alert, monitoring not paused.
  bool get medicalWarning =>
      alertState == AlertState.normal && !settings.paused && medicalDataStale;

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

  /// Scenario: kitchen + bedroom motion at once (guest/cleaner).
  void guestScenario() {
    if (deviceOffline) toggleOffline();
    addEvent(ActivityType.motionKitchen);
    addEvent(ActivityType.motionBedroom);
  }

  /// Scenario: jump the clock 48 hours with no sensor data.
  void silence48Scenario() {
    if (deviceOffline) toggleOffline();
    setSpeed(1);
    clock.set(now.add(const Duration(hours: 48, minutes: 1)));
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

  /// Demo scenario: no morning events, jump [offset] past the first deadline.
  void skipMorning({Duration offset = const Duration(minutes: 1)}) {
    startToday();
    _refreshRhythm();
    final deadlines = rhythm.forDay(now).map((e) => e.deadlineOn(now)).toList()
      ..sort();
    if (deadlines.isNotEmpty) clock.set(deadlines.first.add(offset));
    setSpeed(60);
  }

  bool get demoRunning => demoLabel != null;

  /// Guided demo (~55 s): normal morning, next day the routine is missed,
  /// then soft check -> family alert -> second contact at 60x.
  void playDemo() {
    stopDemo();
    if (deviceOffline) toggleOffline();
    _demoStep = 1;
    demoLabel = '1/5: Normal sabah: çaydanlık, yatak odası, mutfak';
    startToday();
    setSpeed(1);
    void at(int ms, void Function() f) =>
        _demoTimers.add(Timer(Duration(milliseconds: ms), f));
    DateTime todayAt(int h, int m) =>
        dayOf(now).add(Duration(hours: h, minutes: m));
    at(1500, () {
      clock.set(todayAt(7, 15));
      addEvent(ActivityType.kettle);
    });
    at(2500, () {
      clock.set(todayAt(7, 30));
      addEvent(ActivityType.motionBedroom);
    });
    at(6000, () {
      clock.set(todayAt(9, 0));
      addEvent(ActivityType.motionKitchen);
    });
    at(8000, () {
      final next = dayOf(now).add(const Duration(days: 1, hours: 6));
      clock.set(next);
      skipMorning(offset: const Duration(minutes: -2));
      final exps = rhythm.forDay(now)
        ..sort((a, b) => a.endMin.compareTo(b.endMin));
      final first = exps.firstOrNull;
      _demoStep = 2;
      demoLabel =
          '2/5: Ertesi gün: beklenen ${first?.type.label.toLowerCase() ?? 'hareket'} olmadı';
      notifyListeners();
    });
  }

  void stopDemo() {
    for (final t in _demoTimers) {
      t.cancel();
    }
    _demoTimers.clear();
    _demoStep = 0;
    demoLabel = null;
    notifyListeners();
  }

  void _updateDemo() {
    if (_demoStep < 2) return;
    switch (engine.state) {
      case AlertState.softCheck:
        _demoStep = 3;
        demoLabel = "3/5: Yaşlıya 'İyi misiniz?' soruldu";
      case AlertState.familyAlert:
        _demoStep = 4;
        demoLabel = '4/5: 15 dk cevap yok, aileye uyarı gitti';
      case AlertState.secondContactAlert:
        if (_demoStep != 5) {
          _demoStep = 5;
          demoLabel = '5/5: 30 dk daha cevap yok, ikinci kişiye uyarı';
          _demoTimers.add(
            Timer(const Duration(seconds: 6), () {
              setSpeed(1);
              stopDemo();
            }),
          );
        }
      case AlertState.normal:
        if (_demoStep >= 3) stopDemo(); // "İyiyim" ends the demo
    }
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
    _updateDemo();
    notifyListeners();
  }

  void _save() {
    _prefs.setString(
      _kEvents,
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
    _prefs.setString(_kEngine, jsonEncode(engine.toJson()));
    _prefs.setString(
      _kMedical,
      jsonEncode(medical.map((e) => e.toJson()).toList()),
    );
    _prefs.setString(_kSimNow, now.toIso8601String());
  }

  @override
  void dispose() {
    for (final t in _demoTimers) {
      t.cancel();
    }
    clock.dispose();
    super.dispose();
  }
}
