import 'dart:math';

import '../models/adventure.dart';
import '../models/shop_item.dart';
import 'progression.dart';

/// What a replay did, so the caller can drain Vigor and tell the player.
class AdventureOutcome {
  final int ticksRun;
  final int vigorSpent;
  final int goldFound;
  final int xpFound;
  final List<String> itemsFound;
  final List<AdventureEvent> events;

  /// The Mod stopped early because it had nothing left in the tank.
  final bool ranOutOfVigor;

  /// The Mod stopped picking things up because its pack is full.
  final bool packFilled;

  const AdventureOutcome({
    this.ticksRun = 0,
    this.vigorSpent = 0,
    this.goldFound = 0,
    this.xpFound = 0,
    this.itemsFound = const [],
    this.events = const [],
    this.ranOutOfVigor = false,
    this.packFilled = false,
  });

  static const AdventureOutcome none = AdventureOutcome();

  bool get didRun => ticksRun > 0;
}

/// Replays the time the Mod spent out of contact.
///
/// Written as a pure function over the adventure so the date and dice maths
/// can be tested without a clock or a widget tree, in the same style as
/// [DailyRollover]. Every event is derived from the run's seed and its tick
/// index, so the same trip always plays out the same way and closing the app
/// cannot reroll a bad result.
class AdventureEngine {
  AdventureEngine._();

  static const List<String> _travelLines = [
    '{name} follows a dry riverbed north and finds nothing but wind.',
    '{name} picks a careful path through a collapsed overpass.',
    '{name} rests a while under a billboard, watching the road.',
    '{name} maps a stretch of ruins and moves on.',
    '{name} hears something in the treeline and gives it a wide berth.',
    '{name} trades a story with a passing traveller.',
  ];

  static const List<String> _goldLines = [
    '{name} pries a handful of coins out of a rusted vending machine.',
    '{name} clears a nest out of an old safe and pockets the contents.',
    '{name} hauls scrap back to a trader and comes away richer.',
    '{name} finds a cache tucked behind a loose wall.',
    '{name} wins a coin toss it probably should not have taken.',
  ];

  static const List<String> _itemLines = [
    '{name} digs something out of the rubble: {item}.',
    '{name} bargains hard and walks away with {item}.',
    'Half buried under a floorboard, {name} turns up {item}.',
    '{name} spots {item} in a shop long since abandoned.',
  ];

  static const List<String> _winLines = [
    '{name} drives off a scavenger and takes its stash.',
    '{name} stares down a pack of dogs and keeps walking.',
    'Something came out of the dark at {name}. It regretted it.',
    '{name} wins a scrap with a raider and helps itself to the spoils.',
  ];

  static const List<String> _lossLines = [
    '{name} takes a beating from a pack of dogs and limps on.',
    'An ambush catches {name} flat footed. It gets away, barely.',
    '{name} picks the wrong fight and pays for it.',
    'Something bigger than expected sends {name} running.',
  ];

  static const String _campLine =
      '{name} is out of energy and makes camp for the night.';

  static const String _fullPackLine =
      "{name}'s pack is full. Time to head home.";

  static String _pick(List<String> lines, Random rng) {
    return lines[rng.nextInt(lines.length)];
  }

  static String _fill(String line, String name, [String? item]) {
    final withName = line.replaceAll('{name}', name);
    return item == null ? withName : withName.replaceAll('{item}', item);
  }

  static AdventureOutcome run({
    required AdventureState adventure,
    required String modName,
    required int availableVigor,
    required int might,
    required int fortune,
    required List<ShopItem> undiscoveredItems,
    List<ShopItem> repeatableFinds = const [],
    required DateTime now,
  }) {
    if (!adventure.isOut) {
      return AdventureOutcome.none;
    }

    final elapsedMinutes = now.difference(adventure.lastTickAt).inMinutes;

    if (elapsedMinutes < Progression.adventureTickMinutes) {
      return AdventureOutcome.none;
    }

    var possibleTicks = elapsedMinutes ~/ Progression.adventureTickMinutes;
    if (possibleTicks > Progression.maxTicksPerReplay) {
      possibleTicks = Progression.maxTicksPerReplay;
    }

    final pool = List<ShopItem>.from(undiscoveredItems);
    final events = <AdventureEvent>[];

    var vigorLeft = availableVigor;
    var vigorSpent = 0;
    var ticksRun = 0;
    var goldFound = 0;
    var xpFound = 0;
    final itemsFound = <String>[];
    var carried = adventure.carried;
    var ranOutOfVigor = false;
    var packJustFilled = false;

    for (var step = 0; step < possibleTicks; step++) {
      if (vigorLeft < Progression.vigorPerTick) {
        ranOutOfVigor = true;
        break;
      }

      final tick = adventure.tickCount + step;
      final rng = Random(Object.hash(adventure.seed, tick));
      final at = adventure.lastTickAt.add(
        Duration(minutes: Progression.adventureTickMinutes * (step + 1)),
      );

      vigorLeft -= Progression.vigorPerTick;
      vigorSpent += Progression.vigorPerTick;
      ticksRun++;

      final packFull = carried >= Progression.maxCarry;
      final kindRoll = rng.nextDouble();

      // A full pack keeps the Mod walking and talking, but it stops picking
      // anything else up.
      if (packFull || kindRoll < 0.45) {
        events.add(
          AdventureEvent(
            tick: tick,
            at: at,
            kind: AdventureEventKind.travel,
            text: _fill(_pick(_travelLines, rng), modName),
          ),
        );
        continue;
      }

      if (kindRoll < 0.80) {
        final foundRepeatable =
            repeatableFinds.isNotEmpty &&
            rng.nextDouble() < Progression.skipTokenFindChance(fortune);

        if (foundRepeatable) {
          final item =
              repeatableFinds[rng.nextInt(repeatableFinds.length)];
          itemsFound.add(item.id);
          carried++;

          events.add(
            AdventureEvent(
              tick: tick,
              at: at,
              kind: AdventureEventKind.find,
              text: _fill(_pick(_itemLines, rng), modName, item.name),
              itemId: item.id,
            ),
          );
        } else if (pool.isNotEmpty &&
            rng.nextDouble() < Progression.discoveryChance(fortune)) {
          final item = pool.removeAt(rng.nextInt(pool.length));
          itemsFound.add(item.id);
          carried++;

          events.add(
            AdventureEvent(
              tick: tick,
              at: at,
              kind: AdventureEventKind.find,
              text: _fill(_pick(_itemLines, rng), modName, item.name),
              itemId: item.id,
            ),
          );
        } else {
          final gold = Progression.adventureGold(fortune, rng.nextDouble());
          goldFound += gold;
          carried++;

          events.add(
            AdventureEvent(
              tick: tick,
              at: at,
              kind: AdventureEventKind.find,
              text: _fill(_pick(_goldLines, rng), modName),
              gold: gold,
            ),
          );
        }
      } else {
        final won = rng.nextDouble() < Progression.encounterWinChance(might);

        if (won) {
          final gold = Progression.adventureGold(fortune, rng.nextDouble());
          final xp = Progression.adventureXp(rng.nextDouble());
          goldFound += gold;
          xpFound += xp;
          carried++;

          events.add(
            AdventureEvent(
              tick: tick,
              at: at,
              kind: AdventureEventKind.encounter,
              text: _fill(_pick(_winLines, rng), modName),
              gold: gold,
              xp: xp,
            ),
          );
        } else {
          final loss = Progression.encounterLossVigor;
          final actualLoss = loss > vigorLeft ? vigorLeft : loss;

          vigorLeft -= actualLoss;
          vigorSpent += actualLoss;

          events.add(
            AdventureEvent(
              tick: tick,
              at: at,
              kind: AdventureEventKind.encounter,
              text: _fill(_pick(_lossLines, rng), modName),
              vigorLost: actualLoss,
            ),
          );
        }
      }

      if (carried >= Progression.maxCarry && !packJustFilled) {
        packJustFilled = true;

        events.add(
          AdventureEvent(
            tick: tick,
            at: at,
            kind: AdventureEventKind.camp,
            text: _fill(_fullPackLine, modName),
          ),
        );
      }
    }

    if (ticksRun == 0) {
      return AdventureOutcome.none;
    }

    if (ranOutOfVigor) {
      events.add(
        AdventureEvent(
          tick: adventure.tickCount + ticksRun,
          at: now,
          kind: AdventureEventKind.camp,
          text: _fill(_campLine, modName),
        ),
      );
    }

    adventure.tickCount += ticksRun;
    adventure.carried = carried;
    adventure.pendingGold += goldFound;
    adventure.pendingXp += xpFound;
    adventure.pendingItemIds.addAll(itemsFound);
    adventure.appendToLog(events);

    // Running every tick the elapsed time allowed leaves a remainder that
    // should carry forward. Stopping early means the rest of that time was
    // spent camped, so it is simply gone.
    adventure.lastTickAt = ranOutOfVigor
        ? now
        : adventure.lastTickAt.add(
            Duration(minutes: Progression.adventureTickMinutes * ticksRun),
          );

    return AdventureOutcome(
      ticksRun: ticksRun,
      vigorSpent: vigorSpent,
      goldFound: goldFound,
      xpFound: xpFound,
      itemsFound: itemsFound,
      events: events,
      ranOutOfVigor: ranOutOfVigor,
      packFilled: packJustFilled,
    );
  }
}
