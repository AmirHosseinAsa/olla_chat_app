import 'package:flutter/material.dart';
import 'app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConstants {
  // Cache themes to prevent unnecessary rebuilds
  static ThemeData? _cachedDarkTheme;
  static String? _cachedFont;
  static Color? _cachedPrimaryColor;
  static Color? _cachedSecondaryColor;

  static ThemeData getDarkTheme({
    required Color primaryColor,
    required Color secondaryColor,
    String font = 'Roboto',
  }) {
    // Return cached theme if nothing changed
    if (_cachedDarkTheme != null &&
        _cachedFont == font &&
        _cachedPrimaryColor == primaryColor &&
        _cachedSecondaryColor == secondaryColor) {
      return _cachedDarkTheme!;
    }

    // Cache the text styles to prevent rebuilding them for each text widget
    final baseTextTheme = ThemeData.dark().textTheme;
    final googleFont = GoogleFonts.getFont(font);
    final textTheme = _createTextTheme(baseTextTheme, googleFont);

    _cachedDarkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      textTheme: textTheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Color(0xFF1A1B26),
      cardColor: Color(0xFF1E1B2C),
      dividerColor: Colors.white24,
      iconTheme: IconThemeData(color: Colors.white70),
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.kDarkSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      cardTheme: CardTheme(
        color: AppConstants.kDarkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppConstants.kBorderColor,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.kDarkSurfaceLight.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppConstants.kBorderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppConstants.kBorderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: primaryColor,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Colors.white70,
          hoverColor: primaryColor.withOpacity(0.1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.1),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: AppConstants.kBorderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppConstants.kDarkSurfaceLight,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.kDarkSurfaceLight,
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppConstants.kDarkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppConstants.kDarkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppConstants.kBorderColor,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppConstants.kDarkSurfaceLight,
        deleteIconColor: Colors.white70,
        labelStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    // Update cache values
    _cachedFont = font;
    _cachedPrimaryColor = primaryColor;
    _cachedSecondaryColor = secondaryColor;

    return _cachedDarkTheme!;
  }

  // Extract text theme creation to reduce code duplication
  static TextTheme _createTextTheme(TextTheme baseTheme, TextStyle googleFont) {
    return baseTheme.copyWith(
      displayLarge: googleFont.copyWith(color: Colors.white),
      displayMedium: googleFont.copyWith(color: Colors.white),
      displaySmall: googleFont.copyWith(color: Colors.white),
      headlineLarge: googleFont.copyWith(color: Colors.white),
      headlineMedium: googleFont.copyWith(color: Colors.white),
      headlineSmall: googleFont.copyWith(color: Colors.white),
      titleLarge: googleFont.copyWith(color: Colors.white),
      titleMedium: googleFont.copyWith(color: Colors.white),
      titleSmall: googleFont.copyWith(color: Colors.white),
      bodyLarge: googleFont.copyWith(color: Colors.white),
      bodyMedium: googleFont.copyWith(color: Colors.white),
      bodySmall: googleFont.copyWith(color: Colors.white),
      labelLarge: googleFont.copyWith(color: Colors.white),
      labelMedium: googleFont.copyWith(color: Colors.white),
      labelSmall: googleFont.copyWith(color: Colors.white),
    );
  }

  static ThemeData getLightTheme({
    Color primaryColor = AppConstants.kPrimaryPurple,
    Color secondaryColor = AppConstants.kPrimaryCyan,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: AppConstants.kLightSurface,
        background: AppConstants.kLightBackground,
        error: Colors.red.shade400,
      ),
      scaffoldBackgroundColor: AppConstants.kLightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.kLightSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      cardTheme: CardTheme(
        color: AppConstants.kLightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppConstants.kBorderColor.withOpacity(0.2),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppConstants.kBorderColor.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppConstants.kBorderColor.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: primaryColor,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Colors.black87,
          hoverColor: primaryColor.withOpacity(0.1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.1),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: AppConstants.kBorderColor.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey.shade900,
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppConstants.kLightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppConstants.kLightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppConstants.kBorderColor.withOpacity(0.2),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade200,
        deleteIconColor: Colors.black54,
        labelStyle: TextStyle(color: Colors.black87),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
