import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = AppConstants.kPrimaryPurple;
  Color _secondaryColor = AppConstants.kPrimaryCyan;
  String _font = AppConstants.kAvailableFonts[0];

  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  String get font => _font;

  ThemeProvider() {
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _font = prefs.getString('selectedFont') ?? AppConstants.kAvailableFonts[0];
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final index = AppConstants.kPrimaryColors.indexOf(color);
    if (index != -1) {
      await prefs.setInt('primaryColor', index);
      _primaryColor = color;
      notifyListeners();
    }
  }

  Future<void> setSecondaryColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final index = AppConstants.kSecondaryColors.indexOf(color);
    if (index != -1) {
      await prefs.setInt('secondaryColor', index);
      _secondaryColor = color;
      notifyListeners();
    }
  }

  Future<void> setFont(String font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFont', font);
    _font = font;
    notifyListeners();
  }

  ThemeData getTheme() {
    return ThemeConstants.getDarkTheme(
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
    );
  }
}
