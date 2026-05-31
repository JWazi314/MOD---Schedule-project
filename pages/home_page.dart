import 'package:flutter/material.dart';
import '../widgets/player_card.dart';
import '../widgets/quest_card.dart';
import 'shop_page.dart';

class QuestHomePage extends StatefulWidget {
  const QuestHomePage({super.key});

  @override
  State<QuestHomePage> createState() => QuestHomePageState();
}

class QuestHomePageState extends State<QuestHomePage> {
  int silver = 0;
  int gold = 0;
  int xp = 0;

  String currentPage = 'quests';

  bool workoutDone = false;
  bool studyDone = false;
  bool noFastFoodDone = false;

  void completeQuest(String questName, int goldReward, int silverReward, int xpReward) {
    setState(() {
      gold += goldReward;
      silver += silverReward;
      xp += xpReward;

      if (questName == 'Workout') {
        workoutDone = true;
      } else if (questName == 'Study') {
        studyDone = true;
      } else if (questName == 'No Fast Food') {
        noFastFoodDone = true;
      }
    });
  }

  void resetDay() {
    setState(() {
      workoutDone = false;
      studyDone = false;
      noFastFoodDone = false;
    });
  }

  void buyItem(int cost, String title) {
    setState(() {
      gold -= cost;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bought $title for $cost gold!')),
    );
  }

  Widget getCurrentPage() {
    if (currentPage == 'shop') {
      return ShopPage(silver: silver, gold: gold, onBuy: buyItem);
    } else if (currentPage == 'settings') {
      return buildSettingsPage();
    } else {
      return buildQuestBoard();
    }
  }

  Widget buildQuestBoard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlayerCard(gold: gold, silver: silver, xp: xp),

              const SizedBox(height: 24),

              Row(
                children: const [
                  Icon(Icons.star, color: Colors.yellow),
                  SizedBox(width: 8),
                  Text(
                    'Main Quests',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              QuestCard(
                title: 'Workout',
                silverReward: 10,
                goldReward: 20,
                xpReward: 25,
                isDone: workoutDone,
                icon: Icons.fitness_center,
                onComplete: () => completeQuest('Workout', 20, 10, 25),
              ),

              QuestCard(
                title: 'Study',
                silverReward: 10,
                goldReward: 15,
                xpReward: 20,
                isDone: studyDone,
                icon: Icons.menu_book,
                onComplete: () => completeQuest('Study', 15, 10, 20),
              ),

              QuestCard(
                title: 'No Fast Food',
                silverReward: 10,
                goldReward: 10,
                xpReward: 15,
                isDone: noFastFoodDone,
                icon: Icons.restaurant,
                onComplete: () => completeQuest('No Fast Food', 10, 10, 15),
              ),

              const Spacer(),

              Card(
                color: const Color(0xFF201331),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Reward idea: Cheat meal costs 100 gold.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSettingsPage() {
    return const Center(
      child: Text('Settings page goes here', style: TextStyle(fontSize: 24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                side: const BorderSide(color: Color.fromARGB(255, 36, 255, 7), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  currentPage = 'quests';
                });
              },
              child: const Text(
                'Mod',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.store, color: Colors.white),
              label: const Text('shop', style: TextStyle(color: Colors.white, fontSize: 20)),
              onPressed: () {
                setState(() {
                  currentPage = 'shop';
                });
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFF120A1F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Day',
            onPressed: resetDay,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              setState(() {
                currentPage = 'settings';
              });
            },
          ),
        ],
      ),
      body: getCurrentPage(),
    );
  }
}
