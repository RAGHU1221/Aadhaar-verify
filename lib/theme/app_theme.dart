// Bright, modern "supermarket app" style Material 3 theme - replaces the
// desktop build's skeuomorphic wood/leather/ledger look with a clean
// consumer-app aesthetic: white cards, rounded corners, bold category
// colours, generous spacing.

import 'package:flutter/material.dart';

const Color kPrimaryGreen = Color(0xFF1FB673); // "fresh produce" green
const Color kAccentOrange = Color(0xFFFF7A29);
const Color kBackground = Color(0xFFF5F7FA);
const Color kCardWhite = Color(0xFFFFFFFF);
const Color kTextDark = Color(0xFF1B2430);
const Color kTextMuted = Color(0xFF6B7686);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryGreen,
      brightness: Brightness.light,
      primary: kPrimaryGreen,
      secondary: kAccentOrange,
      surface: kCardWhite,
    ),
    scaffoldBackgroundColor: kBackground,
    fontFamily: 'NotoSansTamil',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'NotoSansTamil',
      ),
    ),
    cardTheme: CardThemeData(
      color: kCardWhite,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansTamil'),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryGreen,
        side: const BorderSide(color: kPrimaryGreen, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansTamil'),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'NotoSansTamil',
      bodyColor: kTextDark,
      displayColor: kTextDark,
    ),
  );
}

/// A small rounded "chip" showing a bilingual status label on a coloured
/// background - used for overall verification status, expiry status, and
/// cross-check MATCH/PARTIAL/MISMATCH badges.
class StatusChip extends StatelessWidget {
  final String labelEn;
  final String labelTa;
  final Color color;

  const StatusChip({super.key, required this.labelEn, required this.labelTa, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(labelEn,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(labelTa,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'NotoSansTamil')),
        ],
      ),
    );
  }
}
