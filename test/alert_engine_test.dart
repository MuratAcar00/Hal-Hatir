import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/core/alert_engine.dart';
import 'package:sessiz_komsu/core/clock.dart';
import 'package:sessiz_komsu/core/models.dart';
import 'package:sessiz_komsu/core/rhythm.dart';
import 'package:sessiz_komsu/core/settings.dart';

final monday = DateTime(2026, 10, 26);

/// Kettle every weekday at 07:30 -> window 06:45-08:15.
List<SensorEvent> history() => [
  for (var n = 1; n <= 14; n++)
    if (!isWeekend(DateTime(2026, 10, 26 - n)))
      SensorEvent(
        ActivityType.kettle,
        DateTime(2026, 10, 26 - n).add(const Duration(hours: 7, minutes: 30)),
      ),
  // Sunday evening activity, so Monday is not a 48 h silence.
  SensorEvent(ActivityType.motionBedroom, DateTime(2026, 10, 25, 21)),
];

void main() {
  late FakeClock clock;
  late AlertEngine engine;
  late List<SensorEvent> events;
  late Rhythm rhythm;

  setUp(() {
    clock = FakeClock(monday.add(const Duration(hours: 6)));
    engine = AlertEngine(clock);
    events = history();
    rhythm = Rhythm.learn(events, monday);
  });

  void at(int h, int m) {
    clock.current = monday.add(Duration(hours: h, minutes: m));
    engine.tick(events, rhythm);
  }

  test('stays normal inside the window', () {
    at(8, 14);
    expect(engine.state, AlertState.normal);
  });

  test('full chain: soft_check -> family_alert -> second_contact_alert', () {
    at(8, 15);
    expect(engine.state, AlertState.softCheck);
    expect(
      engine.explanation,
      'Genelde 06:45-08:15 arası çay yapılıyor, bugün saat 08:15 itibarıyla yapılmadı.',
    );
    at(8, 29);
    expect(engine.state, AlertState.softCheck);
    at(8, 30);
    expect(engine.state, AlertState.familyAlert);
    at(8, 59);
    expect(engine.state, AlertState.familyAlert);
    at(9, 0);
    expect(engine.state, AlertState.secondContactAlert);
  });

  test('big clock jump catches up using exact timeouts', () {
    at(8, 20);
    clock.advance(const Duration(hours: 2));
    engine.tick(events, rhythm);
    expect(engine.state, AlertState.secondContactAlert);
    expect(engine.stateSince, monday.add(const Duration(hours: 9, minutes: 5)));
  });

  test('"İyiyim" returns to normal and does not re-fire', () {
    at(8, 40);
    at(8, 56);
    expect(engine.state, AlertState.familyAlert);
    engine.acknowledge(events, rhythm);
    expect(engine.state, AlertState.normal);
    at(9, 30);
    expect(engine.state, AlertState.normal);
  });

  test('new sensor event returns to normal', () {
    at(8, 20);
    expect(engine.state, AlertState.softCheck);
    events.add(SensorEvent(ActivityType.motionBedroom, clock.now()));
    engine.onSensorEvent(events, rhythm);
    expect(engine.state, AlertState.normal);
  });

  test('no alert when activity happened', () {
    events.add(
      SensorEvent(ActivityType.kettle, monday.add(const Duration(hours: 7))),
    );
    at(9, 0);
    expect(engine.state, AlertState.normal);
  });

  test('long silence triggers soft_check', () {
    // Weekend has no learned expectations in this history.
    final saturday = DateTime(2026, 10, 31);
    events.add(
      SensorEvent(ActivityType.motionBedroom, DateTime(2026, 10, 30, 22)),
    );
    clock.current = saturday.add(const Duration(hours: 9, minutes: 59));
    engine.tick(events, rhythm);
    expect(engine.state, AlertState.normal);
    clock.current = saturday.add(const Duration(hours: 10));
    engine.tick(events, rhythm);
    expect(engine.state, AlertState.softCheck);
    expect(engine.explanation, contains('hiç hareket yok'));
  });

  group('settings', () {
    test('no new alert outside monitoring hours', () {
      const st = MonitorSettings(startHour: 9, endHour: 23);
      clock.current = monday.add(const Duration(hours: 8, minutes: 30));
      engine.tick(events, rhythm, settings: st);
      expect(engine.state, AlertState.normal);
      clock.current = monday.add(const Duration(hours: 9));
      engine.tick(events, rhythm, settings: st);
      expect(engine.state, AlertState.softCheck);
    });

    test('wrap-around hours (23:00-06:00 quiet)', () {
      const st = MonitorSettings(startHour: 6, endHour: 23);
      expect(st.isMonitoring(monday.add(const Duration(hours: 23))), isFalse);
      expect(st.isMonitoring(monday.add(const Duration(hours: 5))), isFalse);
      expect(st.isMonitoring(monday.add(const Duration(hours: 6))), isTrue);
      const night = MonitorSettings(startHour: 22, endHour: 8);
      expect(night.isMonitoring(monday.add(const Duration(hours: 2))), isTrue);
      expect(
        night.isMonitoring(monday.add(const Duration(hours: 12))),
        isFalse,
      );
    });

    test('pause mode stops and clears alerts', () {
      at(8, 40);
      expect(engine.state, AlertState.softCheck);
      clock.current = monday.add(const Duration(hours: 9));
      engine.tick(
        events,
        rhythm,
        settings: const MonitorSettings(paused: true),
      );
      expect(engine.state, AlertState.normal);
    });

    test('history records level, explanation and resolution', () {
      at(8, 20);
      at(8, 40);
      engine.acknowledge(events, rhythm);
      expect(engine.history, hasLength(1));
      final h = engine.history.single;
      expect(h.maxLevel, AlertState.familyAlert);
      expect(h.explanation, contains('06:45-08:15'));
      expect(h.resolvedAt, monday.add(const Duration(hours: 8, minutes: 40)));
      final copy = AlertEngine(clock)..loadJson(engine.toJson());
      expect(copy.history.single.maxLevel, AlertState.familyAlert);
    });

    test('escalation freezes outside monitoring hours', () {
      const st = MonitorSettings(startHour: 6, endHour: 23);
      void tickAt(DateTime t) {
        clock.current = t;
        engine.tick(events, rhythm, settings: st);
      }

      tickAt(monday.add(const Duration(hours: 22, minutes: 50)));
      expect(engine.state, AlertState.softCheck);
      tickAt(monday.add(const Duration(hours: 23, minutes: 30)));
      expect(engine.state, AlertState.softCheck);
      final tuesday = monday.add(const Duration(days: 1));
      tickAt(tuesday.add(const Duration(hours: 3)));
      expect(engine.state, AlertState.softCheck);
      tickAt(tuesday.add(const Duration(hours: 6, minutes: 14)));
      expect(engine.state, AlertState.softCheck);
      tickAt(tuesday.add(const Duration(hours: 6, minutes: 15)));
      expect(engine.state, AlertState.familyAlert);
    });
  });

  group('phase 3', () {
    test('kitchen + bedroom within 3 s -> guest day, alerts suppressed', () {
      final real = FakeClock(DateTime(2026, 1, 1, 12));
      engine = AlertEngine(clock, realClock: real);
      clock.current = monday.add(const Duration(hours: 7));
      events.add(SensorEvent(ActivityType.motionKitchen, clock.now()));
      engine.onSensorEvent(events, rhythm);
      real.advance(const Duration(seconds: 2));
      events.add(SensorEvent(ActivityType.motionBedroom, clock.now()));
      engine.onSensorEvent(events, rhythm);
      expect(engine.isGuestDay, isTrue);
      at(9, 0); // kettle missed, but guest day
      expect(engine.state, AlertState.normal);
      clock.current = monday.add(const Duration(days: 1, hours: 1));
      expect(engine.isGuestDay, isFalse); // resets next day
    });

    test('motions more than 3 s apart are not a guest day', () {
      final real = FakeClock(DateTime(2026, 1, 1, 12));
      engine = AlertEngine(clock, realClock: real);
      events.add(SensorEvent(ActivityType.motionKitchen, clock.now()));
      engine.onSensorEvent(events, rhythm);
      real.advance(const Duration(seconds: 4));
      events.add(SensorEvent(ActivityType.motionBedroom, clock.now()));
      engine.onSensorEvent(events, rhythm);
      expect(engine.isGuestDay, isFalse);
    });

    test('48 h without data -> ask family once, then freeze', () {
      // Last event: Sunday 21:00.
      clock.current = DateTime(2026, 10, 27, 21, 1);
      engine.tick(events, rhythm);
      expect(engine.inactivity, Inactivity.asking);
      expect(engine.state, AlertState.normal);
      clock.advance(const Duration(hours: 5));
      engine.tick(events, rhythm);
      expect(engine.state, AlertState.normal);
      engine.confirmInactivity();
      expect(engine.inactivity, Inactivity.frozen);
      const paused = MonitorSettings(paused: true);
      clock.advance(const Duration(days: 3));
      engine.tick(events, rhythm, settings: paused);
      expect(engine.state, AlertState.normal);
      expect(engine.inactivity, Inactivity.frozen);
      // Family turns the freeze off.
      engine.tick(events, rhythm);
      expect(engine.inactivity, Inactivity.none);
    });

    test('new sensor event ends the inactivity question', () {
      clock.current = DateTime(2026, 10, 27, 21, 1);
      engine.tick(events, rhythm);
      expect(engine.inactivity, Inactivity.asking);
      events.add(SensorEvent(ActivityType.door, clock.now()));
      engine.onSensorEvent(events, rhythm);
      expect(engine.inactivity, Inactivity.none);
    });

    test('offline hub does not trigger or escalate', () {
      at(8, 0);
      engine.setOffline(true, events, rhythm);
      at(9, 30);
      expect(engine.state, AlertState.normal);
      engine.setOffline(false, events, rhythm);
      at(9, 31);
      expect(engine.state, AlertState.normal);
    });

    test('offline freezes a running stage', () {
      at(8, 20);
      expect(engine.state, AlertState.softCheck);
      engine.setOffline(true, events, rhythm);
      at(10, 0);
      expect(engine.state, AlertState.softCheck);
    });
  });
}
