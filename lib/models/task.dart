class Task {
  static const dayLabels = ['M', 'T', 'W', 'Th', 'F', 'Sa', 'Su'];
  static const sections = [
    'General',
    'Health',
    'School',
    'Work',
    'Personal',
    'Habits',
  ];

  final String title;
  final int difficulty;
  final List<int> repeatDays;
  final int gold;
  final int silver;
  final int xp;
  final String section;
  final String note;

  bool isDone;
  DateTime? completedAt;
  int streak;

  Task({
    required this.title,
    required this.difficulty,
    required this.repeatDays,
    required this.gold,
    required this.silver,
    required this.xp,
    required this.section,
    this.note = '',
    this.isDone = false,
    this.completedAt,
    this.streak = 0,
  });

  bool get isTodo => repeatDays.isEmpty;

  String get difficultyLabel {
    switch (difficulty) {
      case 1:
        return 'Medium';
      case 2:
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  /// Weekday index used by the editor: 0 is Monday, matching [DateTime.weekday].
  bool scheduledOn(DateTime date) {
    return repeatDays.contains(date.weekday - 1);
  }

  bool showsOnTodayBoard([DateTime? now]) {
    if (isTodo) {
      return true;
    }
    return scheduledOn(now ?? DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'difficulty': difficulty,
      'repeatDays': repeatDays,
      'gold': gold,
      'silver': silver,
      'xp': xp,
      'section': section,
      'note': note,
      'isDone': isDone,
      'completedAt': completedAt?.toIso8601String(),
      'streak': streak,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final repeatDaysJson = json['repeatDays'];
    final completedAtJson = json['completedAt'];

    return Task(
      title: json['title'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 0,
      repeatDays: repeatDaysJson is List
          ? repeatDaysJson.whereType<num>().map((day) => day.toInt()).toList()
          : <int>[],
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      silver: (json['silver'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      section: json['section'] as String? ?? 'General',
      note: json['note'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
      completedAt: completedAtJson is String
          ? DateTime.tryParse(completedAtJson)
          : null,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
    );
  }
}
