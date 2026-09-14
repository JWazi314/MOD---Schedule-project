import '../game/progression.dart';

enum ModStat { might, focus, fortune, vigor }

extension ModStatLabel on ModStat {
  String get label {
    switch (this) {
      case ModStat.might:
        return 'Might';
      case ModStat.focus:
        return 'Focus';
      case ModStat.fortune:
        return 'Fortune';
      case ModStat.vigor:
        return 'Vigor';
    }
  }

  String get description {
    switch (this) {
      case ModStat.might:
        return 'Damage dealt to monsters.';
      case ModStat.focus:
        return 'Experience earned from tasks.';
      case ModStat.fortune:
        return 'Gold earned and items discovered.';
      case ModStat.vigor:
        return 'How quickly the Mod recovers from a setback.';
    }
  }
}

/// Result of handing the Mod some experience.
class LevelUpResult {
  final int levelsGained;
  final int statPointsGained;

  const LevelUpResult({
    required this.levelsGained,
    required this.statPointsGained,
  });

  bool get leveledUp => levelsGained > 0;
}

class ModCharacter {
  String name;
  String appearanceId;

  int level;

  /// Experience banked toward the next level. Overflow carries on level up.
  int xp;

  int unspentStatPoints;

  int mightPoints;
  int focusPoints;
  int fortunePoints;
  int vigorPoints;

  /// A 0-100 resource. Neglect drains it, and a drained Mod has to rest, but
  /// levels, gold, and items are never lost.
  int currentVigor;

  final DateTime createdAt;

  ModCharacter({
    required this.name,
    required this.appearanceId,
    this.level = 1,
    this.xp = 0,
    this.unspentStatPoints = 0,
    this.mightPoints = 0,
    this.focusPoints = 0,
    this.fortunePoints = 0,
    this.vigorPoints = 0,
    this.currentVigor = Progression.maxVigor,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get levelBonus => Progression.levelBonus(level);

  int get might => mightPoints + levelBonus;
  int get focus => focusPoints + levelBonus;
  int get fortune => fortunePoints + levelBonus;
  int get vigor => vigorPoints + levelBonus;

  int statPoints(ModStat stat) {
    switch (stat) {
      case ModStat.might:
        return mightPoints;
      case ModStat.focus:
        return focusPoints;
      case ModStat.fortune:
        return fortunePoints;
      case ModStat.vigor:
        return vigorPoints;
    }
  }

  int effectiveStat(ModStat stat) => statPoints(stat) + levelBonus;

  int get xpToNextLevel => Progression.xpToNextLevel(level);

  double get levelProgress {
    final needed = xpToNextLevel;
    if (needed <= 0) {
      return 1;
    }
    return (xp / needed).clamp(0.0, 1.0);
  }

  bool get isResting => currentVigor <= 0;

  /// Adds experience, rolling over as many levels as the amount covers.
  LevelUpResult gainXp(int amount) {
    if (amount <= 0 || level >= Progression.maxLevel) {
      return const LevelUpResult(levelsGained: 0, statPointsGained: 0);
    }

    xp += amount;
    int levelsGained = 0;

    while (level < Progression.maxLevel && xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;
      levelsGained++;
    }

    if (level >= Progression.maxLevel) {
      xp = 0;
    }

    final pointsGained = levelsGained * Progression.statPointsPerLevel;
    unspentStatPoints += pointsGained;

    return LevelUpResult(
      levelsGained: levelsGained,
      statPointsGained: pointsGained,
    );
  }

  bool spendStatPoint(ModStat stat) {
    if (unspentStatPoints <= 0) {
      return false;
    }

    switch (stat) {
      case ModStat.might:
        mightPoints++;
        break;
      case ModStat.focus:
        focusPoints++;
        break;
      case ModStat.fortune:
        fortunePoints++;
        break;
      case ModStat.vigor:
        vigorPoints++;
        break;
    }

    unspentStatPoints--;
    return true;
  }

  void drainVigor(int amount) {
    currentVigor = (currentVigor - amount).clamp(0, Progression.maxVigor);
  }

  void restoreVigor(int amount) {
    currentVigor = (currentVigor + amount).clamp(0, Progression.maxVigor);
  }

  /// Resets progression while keeping who the Mod is.
  void resetProgress() {
    level = 1;
    xp = 0;
    unspentStatPoints = 0;
    mightPoints = 0;
    focusPoints = 0;
    fortunePoints = 0;
    vigorPoints = 0;
    currentVigor = Progression.maxVigor;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'appearanceId': appearanceId,
      'level': level,
      'xp': xp,
      'unspentStatPoints': unspentStatPoints,
      'mightPoints': mightPoints,
      'focusPoints': focusPoints,
      'fortunePoints': fortunePoints,
      'vigorPoints': vigorPoints,
      'currentVigor': currentVigor,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ModCharacter.fromJson(Map<String, dynamic> json) {
    final createdAtJson = json['createdAt'];

    return ModCharacter(
      name: json['name'] as String? ?? 'Mod',
      appearanceId: json['appearanceId'] as String? ?? 'wanderer',
      level: (json['level'] as num?)?.toInt().clamp(1, Progression.maxLevel) ??
          1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      unspentStatPoints: (json['unspentStatPoints'] as num?)?.toInt() ?? 0,
      mightPoints: (json['mightPoints'] as num?)?.toInt() ?? 0,
      focusPoints: (json['focusPoints'] as num?)?.toInt() ?? 0,
      fortunePoints: (json['fortunePoints'] as num?)?.toInt() ?? 0,
      vigorPoints: (json['vigorPoints'] as num?)?.toInt() ?? 0,
      currentVigor: (json['currentVigor'] as num?)?.toInt() ??
          Progression.maxVigor,
      createdAt: createdAtJson is String
          ? DateTime.tryParse(createdAtJson)
          : null,
    );
  }
}
