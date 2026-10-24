/// Sensor activity types used by the system.
enum ActivityType {
  kettle('kettle', 'Çaydanlık', 'çay yapılıyor', 'yapılmadı'),
  door('door', 'Ön kapı', 'kapı açılıyor', 'açılmadı'),
  motionBedroom(
    'motion_bedroom',
    'Yatak odası hareketi',
    'yatak odasında hareket oluyor',
    'hareket olmadı',
  ),
  motionKitchen(
    'motion_kitchen',
    'Mutfak hareketi',
    'mutfakta hareket oluyor',
    'hareket olmadı',
  );

  const ActivityType(this.id, this.label, this.habit, this.missing);
  final String id;
  final String label;
  final String habit; // used in "Neden uyardı?" sentences
  final String missing;

  static ActivityType fromId(String id) => values.firstWhere((t) => t.id == id);
}

class SensorEvent {
  const SensorEvent(this.type, this.time);
  final ActivityType type;
  final DateTime time;

  Map<String, dynamic> toJson() => {
    'type': type.id,
    'time': time.toIso8601String(),
  };

  factory SensorEvent.fromJson(Map<String, dynamic> j) => SensorEvent(
    ActivityType.fromId(j['type'] as String),
    DateTime.parse(j['time'] as String),
  );
}

enum AlertState { normal, softCheck, familyAlert, secondContactAlert }

// --- small time helpers ---

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isWeekend(DateTime d) => d.weekday >= DateTime.saturday;

String two(int n) => n.toString().padLeft(2, '0');

String dayKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

String hm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

String minToHm(int m) {
  final c = m.clamp(0, 24 * 60 - 1);
  return '${two(c ~/ 60)}:${two(c % 60)}';
}

int minuteOfDay(DateTime t) => t.hour * 60 + t.minute;

const weekdayShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const weekdayLong = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

String dateText(DateTime d) =>
    '${two(d.day)}.${two(d.month)}.${d.year} ${weekdayLong[d.weekday - 1]}';
