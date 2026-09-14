/// One part of a task, for tasks that are really several small steps.
///
/// Only Dailies and To-Dos have these. Ticking the last part finishes the
/// whole task.
class ChecklistItem {
  final String id;
  String title;
  bool isDone;

  ChecklistItem({required this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'isDone': isDone};
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}
