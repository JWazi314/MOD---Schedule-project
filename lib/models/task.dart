import 'checklist_item.dart';

/// A single task. Which fields matter depends on the type of the section it
/// sits in, which is why nothing here is type specific beyond a name.
///
/// Rewards are no longer stored per task. They are derived from [difficulty]
/// and [neglect] so the tuning lives in one place.
class Task {
  String id;
  String title;
  String description;
  int difficulty;
  String sectionId;

  /// Empty means the task sits loose in its column, not inside a group.
  String groupId;

  /// Order inside its column (and group). Lower comes first.
  int sortOrder;

  /// How long this has gone untouched, from 0 (fresh) to 1 (badly neglected).
  ///
  /// Deliberately invisible: it deepens the card's colour and nudges the
  /// reward slightly, but is never shown as a number or explained.
  double neglect;

  /// Weekdays a Daily is due, as 0 for Monday through 6 for Sunday.
  /// Empty means every day. Ignored by Habits and To-Dos.
  List<int> repeatDays;

  /// Consecutive days a Daily has been kept. Reset by a miss.
  int streak;

  /// Dailies and To-Dos only. Habits are never "done".
  bool isDone;
  DateTime? completedAt;

  /// A Daily marked skipped for today. Streak holds; no reward is paid.
  bool isSkipped;

  /// Optional breakdown into smaller steps, for Dailies and To-Dos. Ticking
  /// the last one finishes the task.
  List<ChecklistItem> checklist;

  /// To-Dos only, and optional.
  DateTime? dueDate;

  /// Habits only. A habit can be good, bad, or both.
  bool isPositive;
  bool isNegative;
  int upCount;
  int downCount;

  /// Full payout rolled when the first part is ticked, so later parts and
  /// the finish share one pot instead of rolling again.
  int reservedGold;
  int reservedSilver;
  int reservedXp;
  int paidGold;
  int paidSilver;
  int paidXp;

  Task({
    this.id = '',
    required this.title,
    this.description = '',
    required this.difficulty,
    required this.sectionId,
    this.groupId = '',
    this.sortOrder = 0,
    this.neglect = 0,
    List<int>? repeatDays,
    this.streak = 0,
    this.isDone = false,
    this.completedAt,
    this.isSkipped = false,
    List<ChecklistItem>? checklist,
    this.dueDate,
    this.isPositive = true,
    this.isNegative = false,
    this.upCount = 0,
    this.downCount = 0,
    this.reservedGold = 0,
    this.reservedSilver = 0,
    this.reservedXp = 0,
    this.paidGold = 0,
    this.paidSilver = 0,
    this.paidXp = 0,
  }) : repeatDays = repeatDays ?? <int>[],
       checklist = checklist ?? <ChecklistItem>[];

  /// Dailies with no chosen days are due every day, matching Habitica.
  bool isDueOn(DateTime date) {
    if (repeatDays.isEmpty) {
      return true;
    }
    return repeatDays.contains(date.weekday - 1);
  }

  bool get hasChecklist => checklist.isNotEmpty;

  bool get hasReserve {
    return reservedGold > 0 || reservedSilver > 0 || reservedXp > 0;
  }

  int get completedParts {
    return checklist.where((item) => item.isDone).length;
  }

  bool get allPartsDone {
    return checklist.isNotEmpty && checklist.every((item) => item.isDone);
  }

  void tickEveryPart() {
    for (final item in checklist) {
      item.isDone = true;
    }
  }

  void clearChecklist() {
    for (final item in checklist) {
      item.isDone = false;
    }
  }

  void clearReserve() {
    reservedGold = 0;
    reservedSilver = 0;
    reservedXp = 0;
    paidGold = 0;
    paidSilver = 0;
    paidXp = 0;
  }

  bool get isOverdue {
    final due = dueDate;
    if (due == null || isDone) {
      return false;
    }
    final today = DateTime.now();
    final dueDay = DateTime(due.year, due.month, due.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return dueDay.isBefore(todayDay);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'sectionId': sectionId,
      'groupId': groupId,
      'sortOrder': sortOrder,
      'neglect': neglect,
      'repeatDays': repeatDays,
      'streak': streak,
      'isDone': isDone,
      'completedAt': completedAt?.toIso8601String(),
      'isSkipped': isSkipped,
      'checklist': checklist.map((item) => item.toJson()).toList(),
      'dueDate': dueDate?.toIso8601String(),
      'isPositive': isPositive,
      'isNegative': isNegative,
      'upCount': upCount,
      'downCount': downCount,
      'reservedGold': reservedGold,
      'reservedSilver': reservedSilver,
      'reservedXp': reservedXp,
      'paidGold': paidGold,
      'paidSilver': paidSilver,
      'paidXp': paidXp,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final repeatDaysJson = json['repeatDays'];
    final completedAtJson = json['completedAt'];
    final checklistJson = json['checklist'];
    final dueDateJson = json['dueDate'];

    return Task(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 0,
      // Tasks saved before sections existed land in Main Tasks.
      sectionId: json['sectionId'] as String? ?? 'main',
      groupId: json['groupId'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      neglect: (json['neglect'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0,
      repeatDays: repeatDaysJson is List
          ? repeatDaysJson.whereType<num>().map((day) => day.toInt()).toList()
          : <int>[],
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      isDone: json['isDone'] as bool? ?? false,
      completedAt: completedAtJson is String
          ? DateTime.tryParse(completedAtJson)
          : null,
      isSkipped: json['isSkipped'] as bool? ?? false,
      checklist: checklistJson is List
          ? checklistJson
                .whereType<Map>()
                .map(
                  (item) =>
                      ChecklistItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <ChecklistItem>[],
      dueDate: dueDateJson is String ? DateTime.tryParse(dueDateJson) : null,
      isPositive: json['isPositive'] as bool? ?? true,
      isNegative: json['isNegative'] as bool? ?? false,
      upCount: (json['upCount'] as num?)?.toInt() ?? 0,
      downCount: (json['downCount'] as num?)?.toInt() ?? 0,
      reservedGold: (json['reservedGold'] as num?)?.toInt() ?? 0,
      reservedSilver: (json['reservedSilver'] as num?)?.toInt() ?? 0,
      reservedXp: (json['reservedXp'] as num?)?.toInt() ?? 0,
      paidGold: (json['paidGold'] as num?)?.toInt() ?? 0,
      paidSilver: (json['paidSilver'] as num?)?.toInt() ?? 0,
      paidXp: (json['paidXp'] as num?)?.toInt() ?? 0,
    );
  }
}
