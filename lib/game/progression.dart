/// Every tuning constant for the Mod's progression lives here so the game can
/// be rebalanced without touching UI or state code.
class Progression {
  Progression._();

  static const int maxLevel = 100;
  static const int statPointsPerLevel = 1;
  static const int maxVigor = 100;

  /// Half the Mod's level is added to every stat, so levelling always feels
  /// like something even before points are spent.
  static const int maxLevelBonus = 50;

  /// XP needed to move from [level] to the next one.
  static int xpToNextLevel(int level) {
    final steps = (level - 1).clamp(0, maxLevel);
    return 100 + 50 * steps + 5 * steps * steps;
  }

  static int levelBonus(int level) {
    return (level ~/ 2).clamp(0, maxLevelBonus);
  }

  /// Focus increases XP earned from tasks by 2.5% per point.
  static double xpMultiplier(int focus) => 1 + focus / 40;

  /// Fortune increases gold earned from tasks by 2% per point.
  static double goldMultiplier(int fortune) => 1 + fortune / 50;

  /// Might drives how hard the Mod hits monsters. A task deals roughly one
  /// point of damage, so monster health doubles as a task counter.
  static double monsterDamage(int might) => 1 + might * 0.005;

  /// Fortune improves the odds that an adventure turns up a shop item.
  static double discoveryChance(int fortune) {
    return (0.10 + fortune * 0.01).clamp(0.0, 0.75);
  }

  /// Odds a find-tick is a Skip Token instead of gold or a shop unlock.
  /// Kept low so a token stays a lucky haul, not a farm.
  static double Function(int fortune) skipTokenFindChance = defaultSkipTokenFindChance;

  static double defaultSkipTokenFindChance(int fortune) {
    return (0.02 + fortune * 0.002).clamp(0.0, 0.08);
  }

  static void resetSkipTokenFindChance() {
    skipTokenFindChance = defaultSkipTokenFindChance;
  }

  /// Vigor determines how quickly the Mod shakes off a setback.
  static int vigorRecoveredPerDay(int vigor) => 20 + vigor * 2;

  // ---------------------------------------------------------------------
  // Adventures
  // ---------------------------------------------------------------------

  /// How much real time one adventure event covers.
  static const int adventureTickMinutes = 30;

  /// Vigor burned per event. At full Vigor that is about a day out before the
  /// Mod needs topping up by finishing something.
  static const int vigorPerTick = 2;

  /// Finds the Mod can carry before its pack is full and it stops picking
  /// things up, which is what makes recalling a decision.
  static const int maxCarry = 10;

  static const int maxLogEntries = 60;

  /// A safety net on a single replay, well above what Vigor can pay for.
  static const int maxTicksPerReplay = 80;

  /// Vigor lost when an encounter goes badly.
  static const int encounterLossVigor = 6;

  /// Might expressed as the odds an encounter goes the Mod's way. Same curve
  /// as [monsterDamage], read as a hit rate instead of damage.
  static double encounterWinChance(int might) {
    return (0.45 + (monsterDamage(might) - 1) * 2).clamp(0.45, 0.95);
  }

  /// Gold from a single find, before Fortune is applied. [roll] is 0 to 1.
  static int adventureGold(int fortune, double roll) {
    return applyGoldMultiplier(4 + (roll * 9).floor(), fortune);
  }

  /// Experience from a single find or won encounter. [roll] is 0 to 1.
  static int adventureXp(double roll) => 5 + (roll * 10).floor();

  static int applyXpMultiplier(int baseXp, int focus) {
    return (baseXp * xpMultiplier(focus)).round();
  }

  static int applyGoldMultiplier(int baseGold, int fortune) {
    return (baseGold * goldMultiplier(fortune)).round();
  }
}
