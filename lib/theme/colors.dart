import 'package:flutter/material.dart';

const Color lightPrimary = Color(0xffd6e8f4);
const Color lightSecondary = Color(0xFFdbe4f3);
const Color lightBlack = Color(0xFF000000);
const Color lightWhite = Color(0xFFFFFFFF);
const Color lightGrey = Colors.grey;
const Color lightRed = Color(0xFFec5766);
const Color lightGreen = Color(0xFF43aa8b);
const Color lightBlue = Color(0xFF28c2ff);
const Color lightButtonColor = Color(0xff51bde0);
const Color lightMainFontColor = Color(0xff565c95);
const Color lightArrowBgColor = Color(0xffe4e9f7);
const Color lightPurple = Color(0xff9200c5);

const Color darkPrimary = Color(0xFF1C2526);
const Color darkSecondary = Color(0xFF2E3B3E);
const Color darkBlack = Color(0xFFFFFFFF); // White text/icons in dark mode
const Color darkWhite = Color(0xFF121212); // Dark background
const Color darkGrey = Color(0xFF616161);
const Color darkRed = Color(0xFFe57373);
const Color darkGreen = Color(0xFF4CAF50);
const Color darkBlue = Color(0xFF42A5F5);
const Color darkButtonColor = Color(0xFF0288D1);
const Color darkMainFontColor = Color(0xFFB0BEC5);
const Color darkArrowBgColor = Color(0xFF37474F);
const Color darkPurple = Color(0xFFAB47BC);

class AppColors {
  static Color primary(bool isDark) => isDark ? darkPrimary : lightPrimary;
  static Color secondary(bool isDark) => isDark ? darkSecondary : lightSecondary;
  static Color black(bool isDark) => isDark ? darkBlack : lightBlack;
  static Color white(bool isDark) => isDark ? darkWhite : lightWhite;
  static Color grey(bool isDark) => isDark ? darkGrey : lightGrey;
  static Color red(bool isDark) => isDark ? darkRed : lightRed;
  static Color green(bool isDark) => isDark ? darkGreen : lightGreen;
  static Color blue(bool isDark) => isDark ? darkBlue : lightBlue;
  static Color buttonColor(bool isDark) => isDark ? darkButtonColor : lightButtonColor;
  static Color mainFontColor(bool isDark) => isDark ? darkMainFontColor : lightMainFontColor;
  static Color arrowBgColor(bool isDark) => isDark ? darkArrowBgColor : lightArrowBgColor;
  static Color purple(bool isDark) => isDark ? darkPurple : lightPurple;
}