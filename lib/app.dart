import 'package:flutter/material.dart';
import 'pages/home_page.dart';

class ModApp extends StatelessWidget {
  const ModApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2F6B4F);
    final scheme = ColorScheme.fromSeed(seedColor: seed);

    return MaterialApp(
      title: 'Mod',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF7F4EF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF24352C),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFE4DDD2)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2F6B4F).withValues(alpha: 0.16),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: seed,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const QuestHomePage(),
    );
  }
}
