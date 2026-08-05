class Task {
  final String title;
  final int difficulty;
  final List<int> repeatDays;
  final int gold;
  final int silver;
  final int xp;
  final String section;

  bool isDone;
  DateTime? completedAt;

  Task({
    required this.title,
    required this.difficulty,
    required this.repeatDays,
    required this.gold,
    required this.silver,
    required this.xp,
    required this.section,
    this.isDone = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'difficulty': difficulty,
      'repeatDays': repeatDays,
      'gold': gold,
      'silver': silver,
      'xp': xp,
      'section': section,
      'isDone': isDone,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final repeatDaysJson = json['repeatDays'];
    final completedAtJson = json['completedAt'];

    return Task(
      title: json['title'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 0,
      repeatDays: repeatDaysJson is List
          ? repeatDaysJson
                .whereType<num>()
                .map((day) => day.toInt())
                .toList()
          : <int>[],
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      silver: (json['silver'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      section: json['section'] as String? ?? 'General',
      isDone: json['isDone'] as bool? ?? false,
      completedAt: completedAtJson is String
          ? DateTime.tryParse(completedAtJson)
          : null,
    );
  }
}
