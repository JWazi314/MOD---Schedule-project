import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF163A5F);
  static const Color surface = Color(0xFF1E4A73);
  static const Color surfaceDark = Color(0xFF102C4A);
  static const Color panel = Color(0xFF1A4468);
  static const Color border = Color(0xFF3A6A94);
  static const Color accentBlue = Color(0xFF3D8FD4);
  static const Color track = Color(0xFF2A5A80);

  static const double radius = 3;

  static BorderRadius get borderRadius => BorderRadius.circular(radius);

  static RoundedRectangleBorder cardShape({
    Color? sideColor,
    double width = 1.5,
  }) {
    return RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(color: sideColor ?? border, width: width),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      colorScheme: const ColorScheme.dark(
        primary: Colors.green,
        secondary: Colors.amber,
        surface: surface,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: border, width: 2)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(borderRadius: borderRadius),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearTrackColor: track,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
