import 'package:flutter/material.dart';

const kBg = Color(0xFF080808);
const kBgCard = Color(0xFF111111);
const kBgElevated = Color(0xFF161616);
const kRed = Color(0xFFFF1A1A);
const kRedGlow = Color(0x40FF1A1A);
const kGreen = Color(0xFF00FF88);
const kGreenGlow = Color(0x3300FF88);
const kYellow = Color(0xFFFFCC00);
const kText = Color(0xFFE8E8E8);
const kTextDim = Color(0xFF666666);
const kTextMuted = Color(0xFF333333);
const kBorder = Color(0xFF1E1E1E);

const kApiBase = 'http://localhost:3000/api';
const kUploadsBase = 'http://localhost:3000/uploads';

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBg,
  colorScheme: const ColorScheme.dark(
    primary: kRed,
    secondary: kGreen,
    surface: kBgCard,
    onSurface: kText,
  ),
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: kBg,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: kText),
    titleTextStyle: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w700),
  ),
  dividerColor: kBorder,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kBgElevated,
    hintStyle: const TextStyle(color: kTextMuted),
    labelStyle: const TextStyle(color: kTextDim, fontSize: 11),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kRed, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kRed,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 14),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kBg,
    selectedItemColor: kRed,
    unselectedItemColor: kTextMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
);
