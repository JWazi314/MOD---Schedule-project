class CustomReward {
  final String title;
  final int cost;
  final String description;

  const CustomReward({
    required this.title,
    required this.cost,
    this.description = 'A reward you chose for yourself.',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'cost': cost,
      'description': description,
    };
  }

  factory CustomReward.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String? ?? '').trim();
    final cost = (json['cost'] as num?)?.toInt() ?? 0;
    return CustomReward(
      title: title,
      cost: cost < 1 ? 1 : cost,
      description:
          (json['description'] as String?)?.trim().isNotEmpty == true
          ? (json['description'] as String).trim()
          : 'A reward you chose for yourself.',
    );
  }
}
