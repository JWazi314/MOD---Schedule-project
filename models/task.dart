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
    return Task(
      title: json['title'] as String,
      difficulty: json['difficulty'] as int,
      repeatDays: List<int>.from(json['repeatDays'] as List),
      gold: json['gold'] as int,
      silver: json['silver'] as int,
      xp: json['xp'] as int,
      section: json['section'] as String,
      isDone: json['isDone'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }
}