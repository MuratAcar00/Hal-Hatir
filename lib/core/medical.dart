import 'dart:math';

/// Simulated medical / cognitive device readings. Kept apart from sensor
/// events: the alert engine and rhythm learning never see them.
enum MedicalKind { bloodPressure, glucose, memoryGame }

class MedicalReading {
  const MedicalReading(this.kind, this.time, {this.score});

  final MedicalKind kind;
  final DateTime time;
  final int? score; // memory game result

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'time': time.toIso8601String(),
    if (score != null) 'score': score,
  };

  factory MedicalReading.fromJson(Map<String, dynamic> j) => MedicalReading(
    MedicalKind.values.byName(j['kind'] as String),
    DateTime.parse(j['time'] as String),
    score: j['score'] as int?,
  );
}

/// Daily morning readings for the [days] days before [today].
List<MedicalReading> seedMedical(DateTime today, {int days = 14, int seed = 7}) {
  final rnd = Random(seed);
  final out = <MedicalReading>[];
  for (var i = days; i >= 1; i--) {
    final d = DateTime(today.year, today.month, today.day - i);
    DateTime at(int minutes) => d.add(Duration(minutes: minutes));
    out
      ..add(MedicalReading(MedicalKind.glucose, at(430 + rnd.nextInt(30))))
      ..add(MedicalReading(MedicalKind.bloodPressure, at(480 + rnd.nextInt(40))))
      ..add(
        MedicalReading(
          MedicalKind.memoryGame,
          at(620 + rnd.nextInt(60)),
          score: i == 1 ? 85 : 78 + rnd.nextInt(15),
        ),
      );
  }
  return out;
}
