import '../game/progression.dart';

enum AdventureEventKind { travel, find, encounter, camp }

/// One thing that happened to the Mod while it was out.
///
/// Rewards ride along on the event rather than being applied straight away,
/// so the log and the pending haul can never disagree.
class AdventureEvent {
  final int tick;
  final DateTime at;
  final AdventureEventKind kind;
  final String text;
  final int gold;
  final int xp;
  final int vigorLost;

  /// Set when this event turned up a locked shop item.
  final String? itemId;

  const AdventureEvent({
    required this.tick,
    required this.at,
    required this.kind,
    required this.text,
    this.gold = 0,
    this.xp = 0,
    this.vigorLost = 0,
    this.itemId,
  });

  bool get paidOut => gold > 0 || xp > 0 || itemId != null;

  Map<String, dynamic> toJson() {
    return {
      'tick': tick,
      'at': at.toIso8601String(),
      'kind': kind.name,
      'text': text,
      'gold': gold,
      'xp': xp,
      'vigorLost': vigorLost,
      'itemId': itemId,
    };
  }

  factory AdventureEvent.fromJson(Map<String, dynamic> json) {
    final atJson = json['at'];

    return AdventureEvent(
      tick: (json['tick'] as num?)?.toInt() ?? 0,
      at: (atJson is String ? DateTime.tryParse(atJson) : null) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      kind: AdventureEventKind.values.firstWhere(
        (candidate) => candidate.name == json['kind'],
        orElse: () => AdventureEventKind.travel,
      ),
      text: json['text'] as String? ?? '',
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      vigorLost: (json['vigorLost'] as num?)?.toInt() ?? 0,
      itemId: json['itemId'] as String?,
    );
  }
}

/// Where the Mod is and what it is carrying.
///
/// The run is described rather than recorded: [seed] plus [tickCount] is
/// enough to regenerate exactly what happened, so time spent with the app shut
/// replays identically and cannot be rerolled by refreshing.
class AdventureState {
  bool isOut;
  int seed;
  DateTime startedAt;
  DateTime lastTickAt;
  int tickCount;

  /// Loot rides in the Mod's pack until it is recalled.
  int pendingGold;
  int pendingXp;
  List<String> pendingItemIds;

  /// How many finds are in the pack, against [Progression.maxCarry].
  int carried;

  List<AdventureEvent> log;

  AdventureState({
    this.isOut = false,
    this.seed = 0,
    DateTime? startedAt,
    DateTime? lastTickAt,
    this.tickCount = 0,
    this.pendingGold = 0,
    this.pendingXp = 0,
    List<String>? pendingItemIds,
    this.carried = 0,
    List<AdventureEvent>? log,
  })  : startedAt = startedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        lastTickAt = lastTickAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        pendingItemIds = pendingItemIds ?? <String>[],
        log = log ?? <AdventureEvent>[];

  /// Starts a fresh run, keeping nothing from the last one but the log.
  void dispatch({required int seed, required DateTime now}) {
    isOut = true;
    this.seed = seed;
    startedAt = now;
    lastTickAt = now;
    tickCount = 0;
    pendingGold = 0;
    pendingXp = 0;
    pendingItemIds = <String>[];
    carried = 0;
    log = <AdventureEvent>[];
  }

  /// Empties the pack. The log survives so the trip can still be read back.
  void clearHaul() {
    isOut = false;
    pendingGold = 0;
    pendingXp = 0;
    pendingItemIds = <String>[];
    carried = 0;
  }

  bool get hasHaul =>
      pendingGold > 0 || pendingXp > 0 || pendingItemIds.isNotEmpty;

  bool get isPackFull => carried >= Progression.maxCarry;

  Duration timeOut(DateTime now) {
    final elapsed = now.difference(startedAt);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  void appendToLog(List<AdventureEvent> events) {
    log.addAll(events);

    if (log.length > Progression.maxLogEntries) {
      log = log.sublist(log.length - Progression.maxLogEntries);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'isOut': isOut,
      'seed': seed,
      'startedAt': startedAt.toIso8601String(),
      'lastTickAt': lastTickAt.toIso8601String(),
      'tickCount': tickCount,
      'pendingGold': pendingGold,
      'pendingXp': pendingXp,
      'pendingItemIds': pendingItemIds,
      'carried': carried,
      'log': log.map((event) => event.toJson()).toList(),
    };
  }

  factory AdventureState.fromJson(Map<String, dynamic> json) {
    final startedAtJson = json['startedAt'];
    final lastTickAtJson = json['lastTickAt'];
    final logJson = json['log'];
    final itemsJson = json['pendingItemIds'];

    return AdventureState(
      isOut: json['isOut'] as bool? ?? false,
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      startedAt: startedAtJson is String
          ? DateTime.tryParse(startedAtJson)
          : null,
      lastTickAt: lastTickAtJson is String
          ? DateTime.tryParse(lastTickAtJson)
          : null,
      tickCount: (json['tickCount'] as num?)?.toInt() ?? 0,
      pendingGold: (json['pendingGold'] as num?)?.toInt() ?? 0,
      pendingXp: (json['pendingXp'] as num?)?.toInt() ?? 0,
      pendingItemIds: itemsJson is List
          ? itemsJson.whereType<String>().toList()
          : <String>[],
      carried: (json['carried'] as num?)?.toInt() ?? 0,
      log: logJson is List
          ? logJson
              .whereType<Map>()
              .map(
                (event) =>
                    AdventureEvent.fromJson(Map<String, dynamic>.from(event)),
              )
              .toList()
          : <AdventureEvent>[],
    );
  }
}
