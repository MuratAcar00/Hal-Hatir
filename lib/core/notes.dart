/// Short care note written by a family member or caregiver.
class FamilyNote {
  const FamilyNote(this.text, this.time, this.author);

  final String text;
  final DateTime time;
  final String author;

  Map<String, dynamic> toJson() => {
    'text': text,
    'time': time.toIso8601String(),
    'author': author,
  };

  factory FamilyNote.fromJson(Map<String, dynamic> j) => FamilyNote(
    j['text'] as String,
    DateTime.parse(j['time'] as String),
    j['author'] as String,
  );
}

List<FamilyNote> seedNotes(DateTime now) => [
  FamilyNote(
    'Hafta sonu ziyaret planı: Pazar öğleden sonra uğranacak.',
    now.subtract(const Duration(days: 1, hours: 2)),
    'Aile Üyesi',
  ),
  FamilyNote(
    'Öğleden sonra kısa bir yürüyüş yapıldı, iştahı yerinde.',
    now.subtract(const Duration(hours: 20)),
    'Bakıcı',
  ),
];
