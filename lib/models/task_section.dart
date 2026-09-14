import 'task_type.dart';

/// A named pocket inside a column, so Home dailies can sit apart from School.
class TaskGroup {
  final String id;
  String name;

  TaskGroup({required this.id, required this.name});

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  factory TaskGroup.fromJson(Map<String, dynamic> json) {
    return TaskGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Group',
    );
  }
}

/// A column on the quest board. Its [type] decides how every task inside it
/// behaves. Optional [groups] split that column into smaller lists.
class TaskSection {
  final String id;
  String name;
  TaskType type;
  List<TaskGroup> groups;

  TaskSection({
    required this.id,
    required this.name,
    this.type = TaskType.daily,
    List<TaskGroup>? groups,
  }) : groups = groups ?? <TaskGroup>[];

  TaskGroup? groupById(String id) {
    for (final group in groups) {
      if (group.id == id) {
        return group;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.id,
      'groups': groups.map((group) => group.toJson()).toList(),
    };
  }

  factory TaskSection.fromJson(Map<String, dynamic> json) {
    final groupsJson = json['groups'];

    return TaskSection(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Task Section',
      // Sections saved before task types existed behaved like Dailies.
      type: taskTypeFromId(json['type'] as String?),
      groups: groupsJson is List
          ? groupsJson
                .whereType<Map>()
                .map(
                  (item) => TaskGroup.fromJson(Map<String, dynamic>.from(item)),
                )
                .where((group) => group.id.isNotEmpty)
                .toList()
          : <TaskGroup>[],
    );
  }
}

/// The board a new player starts with, one column per type.
List<TaskSection> defaultSections() {
  return [
    TaskSection(id: 'habits', name: 'Habits', type: TaskType.habit),
    TaskSection(id: 'dailies', name: 'Dailies', type: TaskType.daily),
    TaskSection(id: 'todos', name: 'To-Dos', type: TaskType.todo),
  ];
}
