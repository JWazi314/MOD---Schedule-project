import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'pages/mod_creation_page.dart';
import 'state/game_state.dart';
import 'theme.dart';

class ModApp extends StatelessWidget {
  const ModApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState()
        ..load()
        ..startLiveTicks(),
      child: MaterialApp(
        title: 'Mod',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const ModRoot(),
      ),
    );
  }
}

/// Holds the app on a loading state until the save is read, then sends first
/// time players through Mod creation before the quest board.
class ModRoot extends StatelessWidget {
  const ModRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    if (!gameState.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!gameState.hasMod) {
      return const ModCreationPage();
    }

    return const QuestHomePage();
  }
}
