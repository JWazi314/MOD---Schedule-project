import 'package:flutter/material.dart';

import '../theme.dart';
import 'adventure_page.dart';
import 'mod_page.dart';
import 'statistics_page.dart';

/// The three Mod surfaces live behind one app-bar button. This switcher
/// keeps them on one page so a phone does not need three icons for one
/// character.
enum ModHubTab { character, adventure, stats }

extension ModHubTabInfo on ModHubTab {
  String get label {
    switch (this) {
      case ModHubTab.character:
        return 'Mod';
      case ModHubTab.adventure:
        return 'Adventure';
      case ModHubTab.stats:
        return 'Stats';
    }
  }

  IconData get icon {
    switch (this) {
      case ModHubTab.character:
        return Icons.person_4;
      case ModHubTab.adventure:
        return Icons.explore;
      case ModHubTab.stats:
        return Icons.bar_chart;
    }
  }
}

/// Character sheet, dispatch, and numbers, swapped in place.
class ModHubPage extends StatefulWidget {
  final ModHubTab initialTab;
  final ValueChanged<ModHubTab>? onTabChanged;

  const ModHubPage({
    super.key,
    this.initialTab = ModHubTab.character,
    this.onTabChanged,
  });

  @override
  State<ModHubPage> createState() => _ModHubPageState();
}

class _ModHubPageState extends State<ModHubPage> {
  late ModHubTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void didUpdateWidget(ModHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tab = widget.initialTab;
    }
  }

  void _select(ModHubTab tab) {
    if (_tab == tab) {
      return;
    }
    setState(() {
      _tab = tab;
    });
    widget.onTabChanged?.call(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Row(
                children: [
                  for (final tab in ModHubTab.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _HubChip(
                          key: ValueKey('mod-hub-${tab.name}'),
                          tab: tab,
                          selected: _tab == tab,
                          onTap: () => _select(tab),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: switch (_tab) {
            ModHubTab.character => ModPage(onOpenAdventure: () {
              _select(ModHubTab.adventure);
            }),
            ModHubTab.adventure => const AdventurePage(),
            ModHubTab.stats => const StatisticsPage(),
          },
        ),
      ],
    );
  }
}

class _HubChip extends StatelessWidget {
  final ModHubTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _HubChip({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.amber : Colors.white70;

    return Material(
      color: selected ? AppTheme.surface : AppTheme.surfaceDark,
      borderRadius: AppTheme.borderRadius,
      child: InkWell(
        borderRadius: AppTheme.borderRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadius,
            border: Border.all(
              color: selected ? Colors.amber : AppTheme.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tab.icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tab.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
