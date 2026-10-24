import 'dart:async';

import 'package:flutter/foundation.dart';

/// All time-dependent logic reads time from a Clock.
abstract class Clock {
  DateTime now();
}

/// Wall clock (used for real-time gestures like the 3 s guest rule).
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Manually driven clock for tests.
class FakeClock implements Clock {
  FakeClock(this.current);
  DateTime current;

  @override
  DateTime now() => current;

  void advance(Duration d) => current = current.add(d);
}

/// Simulated clock: speed 1x, 60x or 600x (600x: 1 s -> 10 min).
class SimClock extends ChangeNotifier implements Clock {
  SimClock(DateTime start) : _simAnchor = start, _realAnchor = DateTime.now();

  static const speeds = [1, 60, 600];

  DateTime _simAnchor;
  DateTime _realAnchor;
  int _speed = 1;
  Timer? _timer;

  int get speed => _speed;

  @override
  DateTime now() =>
      _simAnchor.add(DateTime.now().difference(_realAnchor) * _speed);

  void setSpeed(int s) {
    _simAnchor = now();
    _realAnchor = DateTime.now();
    _speed = s;
    notifyListeners();
  }

  void set(DateTime t) {
    _simAnchor = t;
    _realAnchor = DateTime.now();
    notifyListeners();
  }

  void start() {
    _timer ??= Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
