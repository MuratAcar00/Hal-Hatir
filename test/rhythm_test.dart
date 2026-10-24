import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/core/models.dart';
import 'package:sessiz_komsu/core/rhythm.dart';
import 'package:sessiz_komsu/core/seed.dart';

// 2026-10-26 is a Monday.
final monday = DateTime(2026, 10, 26);

DateTime daysBefore(DateTime d, int n, int minute) =>
    DateTime(d.year, d.month, d.day - n).add(Duration(minutes: minute));

void main() {
  test('learns median of first event per day', () {
    final events = [
      // Weekdays before Monday 26th: 19..23 Oct (n = 7..3).
      for (final (n, m) in [(7, 420), (6, 430), (5, 440), (4, 450), (3, 460)])
        SensorEvent(ActivityType.kettle, daysBefore(monday, n, m)),
      // Later event the same day must not affect "first event".
      SensorEvent(ActivityType.kettle, daysBefore(monday, 5, 900)),
    ];
    final r = Rhythm.learn(events, monday, days: 7);
    final exp = r.get(ActivityType.kettle, false)!;
    expect(exp.medianMin, 440);
    expect(exp.samples, 5);
  });

  test('tolerance is at least 45 minutes', () {
    final events = [
      for (var n = 3; n <= 7; n++)
        SensorEvent(ActivityType.kettle, daysBefore(monday, n, 450)),
    ];
    final exp = Rhythm.learn(
      events,
      monday,
      days: 7,
    ).get(ActivityType.kettle, false)!;
    expect(exp.toleranceMin, 45);
    expect(exp.windowText, '06:45-08:15');
  });

  test('tolerance grows to 1.5 std dev for spread data', () {
    // 360, 420, 480, 540, 600 -> std ~84.85 -> tol 127.
    final events = [
      for (final (i, m) in [360, 420, 480, 540, 600].indexed)
        SensorEvent(ActivityType.kettle, daysBefore(monday, 7 - i, m)),
    ];
    final exp = Rhythm.learn(
      events,
      monday,
      days: 7,
    ).get(ActivityType.kettle, false)!;
    expect(exp.medianMin, 480);
    expect(exp.toleranceMin, 127);
  });

  test('weekdays and weekends are learned separately', () {
    final events = <SensorEvent>[];
    for (var n = 1; n <= 14; n++) {
      final d = DateTime(monday.year, monday.month, monday.day - n);
      events.add(
        SensorEvent(
          ActivityType.motionKitchen,
          d.add(Duration(minutes: isWeekend(d) ? 600 : 480)),
        ),
      );
    }
    final r = Rhythm.learn(events, monday);
    expect(r.get(ActivityType.motionKitchen, false)!.medianMin, 480);
    expect(r.get(ActivityType.motionKitchen, true)!.medianMin, 600);
    expect(r.forDay(DateTime(2026, 10, 31)).single.weekend, isTrue); // Saturday
  });

  test('rare activity (door 3-4x/week) is not a daily expectation', () {
    final r = Rhythm.learn(seedHistory(monday), monday);
    expect(r.get(ActivityType.door, false), isNull);
    final kettle = r.get(ActivityType.kettle, false)!;
    expect(kettle.medianMin, inInclusiveRange(420, 480));
    expect(
      r.get(ActivityType.motionKitchen, true)!.medianMin,
      greaterThan(r.get(ActivityType.motionKitchen, false)!.medianMin),
    );
  });
}
