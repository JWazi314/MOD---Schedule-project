import 'package:flutter/material.dart';
import 'pages/home_page.dart';

class ModApp extends StatelessWidget {
  const ModApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mod',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      home: const QuestHomePage(),
    );
  }
}