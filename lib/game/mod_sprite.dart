import 'package:flutter/material.dart';

/// A 16×16 pixel Mod. Real art can replace these maps later; the IDs stay
/// the same as [ModAppearance].
class ModSprite {
  ModSprite._();

  static const int size = 16;

  /// `.` empty, `K` outline, `S` skin, `A` accent, `D` dark accent,
  /// `B` boots, `W` pale (eyes / metal).
  static List<String> rowsFor(String appearanceId) {
    switch (appearanceId) {
      case 'knight':
        return const [
          '......KKKK......',
          '.....KWWWWK.....',
          '....KWWWWWWK....',
          '....KWSWWWSK....',
          '....KWWWWWWK....',
          '.....KKKKKK.....',
          '..KKKKAAAAKKKK..',
          '.KAAAAAAAAAAAAK.',
          '.KDAAAAAAAAAADK.',
          '.KAAKAAAAAAKAAK.',
          '..KK..KWWK..KK..',
          '......KWWK......',
          '.....KBBBBK.....',
          '.....KB..BK.....',
          '....KKK..KKK....',
          '................',
        ];
      case 'scholar':
        return const [
          '.......KK.......',
          '......KAAK......',
          '.....KAAAAK.....',
          '....KAAAAAAK....',
          '...KKKSSSSKKK...',
          '....KSWWWWSK....',
          '.....KSSSSK.....',
          '....KKAAAAKK....',
          '...KAAAAAAAAK...',
          '...KAAKWWKAAK...',
          '....KK.WW.KK....',
          '......KAAK......',
          '.....KAAAAK.....',
          '......KBBK......',
          '.....KK..KK.....',
          '................',
        ];
      case 'scout':
        return const [
          '....KKKKKKKK....',
          '...KDDDAAAAAK...',
          '..KDAASSSSAAK...',
          '..KAASWWWS.AK...',
          '..KAASSSSSAAK...',
          '...KKKKKKKKK....',
          '...KKAAAAAAKK...',
          '..KDAAAAAAAADK..',
          '..KAAAAAAAAAAK..',
          '...KAAK..KAAK...',
          '....KK....KK....',
          '......KBBK......',
          '.....KB.BK......',
          '.....KK.KK......',
          '....KK...KK.....',
          '................',
        ];
      case 'brawler':
        return const [
          '.....KKKKKK.....',
          '....KSSSSSSK....',
          '....KSWWWWSK....',
          '....KSSSSSSK....',
          '.....KKKKKK.....',
          '.KKKKAAAAAAKKKK.',
          'KAAAAAAAAAAAAAAK',
          'KDAAAAAAAAAAAADK',
          'KKKKAAAAAAAAKKKK',
          '..KAAKAAAAKAAK..',
          '..KK..KAAK..KK..',
          '......KAAK......',
          '.....KBBBBK.....',
          '....KBB..BBK....',
          '....KK....KK....',
          '................',
        ];
      case 'tinkerer':
        return const [
          '....KK....KK....',
          '.....KWWWWK.....',
          '....KWWAAWWK....',
          '.....KSSSSK.....',
          '.....KSWWSK.....',
          '......KSSK......',
          '....KKAAAAKK....',
          '...KAAAAAAAAK...',
          '...KAAKDDDAAK...',
          '...KAAKDWDAAK...',
          '....KK.KDKKK....',
          '......KAAK......',
          '......KBBK......',
          '.....KB.BBK.....',
          '.....KK..KK.....',
          '................',
        ];
      case 'wanderer':
      default:
        return const [
          '......KKKK......',
          '.....KAAAAK.....',
          '....KAAAAAAK....',
          '.....KSSSSK.....',
          '.....KSWWSK.....',
          '......KSSK......',
          '....KKAAAAKK....',
          '...KDAAAAAADK...',
          '...KAAAAAAAAK...',
          '...KAAK.KAAAK...',
          '....KK...KDK....',
          '......KAAK......',
          '......KBBK......',
          '......KB.BK.....',
          '.....KKK.KK.....',
          '................',
        ];
    }
  }

  static Color? colorFor(String token, Color accent) {
    switch (token) {
      case 'K':
        return const Color(0xFF141825);
      case 'S':
        return const Color(0xFFE6C19A);
      case 'A':
        return accent;
      case 'D':
        return Color.lerp(accent, const Color(0xFF141825), 0.45)!;
      case 'B':
        return const Color(0xFF3A2618);
      case 'W':
        return const Color(0xFFF4F0E4);
      default:
        return null;
    }
  }
}
