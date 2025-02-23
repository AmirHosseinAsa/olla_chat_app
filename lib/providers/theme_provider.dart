import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../utils/util.dart';

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = AppConstants.kPrimaryPurple;
  Color _secondaryColor = AppConstants.kPrimaryCyan;
  String _font = 'Roboto';
  ThemeData? _cachedTheme;

  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  String get font => _font;

  ThemeProvider() {
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bool shouldNotify = false;
    
    final savedFont = prefs.getString('selectedFont');
    if (savedFont != null && savedFont != _font) {
      _font = savedFont;
      Util.appFont = _font;
      _cachedTheme = null;
      shouldNotify = true;
    }

    final primaryColorIndex = prefs.getInt('primaryColor');
    if (primaryColorIndex != null && 
        primaryColorIndex < AppConstants.kPrimaryColors.length &&
        _primaryColor != AppConstants.kPrimaryColors[primaryColorIndex]) {
      _primaryColor = AppConstants.kPrimaryColors[primaryColorIndex];
      _cachedTheme = null;
      shouldNotify = true;
    }

    final secondaryColorIndex = prefs.getInt('secondaryColor');
    if (secondaryColorIndex != null && 
        secondaryColorIndex < AppConstants.kSecondaryColors.length &&
        _secondaryColor != AppConstants.kSecondaryColors[secondaryColorIndex]) {
      _secondaryColor = AppConstants.kSecondaryColors[secondaryColorIndex];
      _cachedTheme = null;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> setPrimaryColor(Color color) async {
    if (_primaryColor == color) return;
    
    final prefs = await SharedPreferences.getInstance();
    final index = AppConstants.kPrimaryColors.indexOf(color);
    if (index != -1) {
      await prefs.setInt('primaryColor', index);
      _primaryColor = color;
      _cachedTheme = null;
      notifyListeners();
    }
  }

  Future<void> setSecondaryColor(Color color) async {
    if (_secondaryColor == color) return;
    
    final prefs = await SharedPreferences.getInstance();
    final index = AppConstants.kSecondaryColors.indexOf(color);
    if (index != -1) {
      await prefs.setInt('secondaryColor', index);
      _secondaryColor = color;
      _cachedTheme = null;
      notifyListeners();
    }
  }

  Future<void> setFont(String font) async {
    if (_font == font) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFont', font);
    _font = font;
    Util.appFont = font;
    _cachedTheme = null;
    notifyListeners();
  }

  ThemeData getTheme() {
    return _cachedTheme ??= ThemeConstants.getDarkTheme(
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      font: _font,
    );
  }
}
