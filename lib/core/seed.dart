import 'dart:math';

import 'models.dart';

/// 14 days of fake history before [today]. Weekends run ~30 min later.
List<SensorEvent> seedHistory(DateTime today, {int days = 14, int seed = 42}) {
  final rnd = Random(seed);
  double gauss() =>
      sqrt(-2 * log(1 - rnd.nextDouble())) * cos(2 * pi * rnd.nextDouble());
  // Door days: 3-4 per week.
  final doorDays = <int>{};
  for (var w = 0; w * 7 < days; w++) {
    final week = List.generate(7, (i) => w * 7 + i)..shuffle(rnd);
    doorDays.addAll(week.take(3 + rnd.nextInt(2)));
  }
  final events = <SensorEvent>[];
  for (var i = 0; i < days; i++) {
    final d = DateTime(today.year, today.month, today.day - days + i);
    final shift = isWeekend(d) ? 30 : 0;
    DateTime at(num minutes) =>
        d.add(Duration(minutes: minutes.round().clamp(0, 24 * 60 - 1)));
    events
      ..add(SensorEvent(ActivityType.kettle, at(420 + shift + rnd.nextInt(60))))
      ..add(
        SensorEvent(ActivityType.motionBedroom, at(450 + shift + gauss() * 12)),
      )
      ..add(
        SensorEvent(ActivityType.motionKitchen, at(540 + shift + gauss() * 18)),
      )
      // Some later activity so the day is not silent.
      ..add(SensorEvent(ActivityType.motionKitchen, at(780 + gauss() * 30)))
      ..add(SensorEvent(ActivityType.motionBedroom, at(1290 + gauss() * 20)));
    if (doorDays.contains(i)) {
      events.add(SensorEvent(ActivityType.door, at(600 + rnd.nextInt(120))));
    }
  }
  events.sort((a, b) => a.time.compareTo(b.time));
  return events;
}
