import 'package:flutter/material.dart';

class AppConstants {
  // API
  static const String kOllamaBaseUrl = 'http://localhost:11434/api';
  static const String kDefaultModelKey = 'default_model';

  // Fonts
  static const List<String> kAvailableFonts = [
    'Inter',
    'Roboto',
    'Lato',
    'Open Sans',
    'Montserrat',
    'Source Code Pro',
    'JetBrains Mono',
    'Fira Code',
    'Ubuntu',
    'Poppins',
  ];

  // Colors
  static const Color kPrimaryPurple = Color(0xFF8B5CF6);
  static const Color kPrimaryCyan = Color(0xFF22D3EE);
  static const Color kAccentPink = Color(0xFFEC4899);
  static const Color kAccentGreen = Color(0xFF10B981);
  static const Color kAccentYellow = Color(0xFFFBBF24);
  static const Color kAccentOrange = Color(0xFFF97316);

  // Dark theme colors
  static const Color kDarkSurface = Color(0xFF1E1B2C);
  static const Color kDarkBackground = Color(0xFF0F0B1A);
  static const Color kDarkSurfaceLight = Color(0xFF2D2E32);
  static const Color kBorderColor = Color(0xFF2D2E32);

  // Light theme colors
  static const Color kLightSurface = Color(0xFFFAFAFA);
  static const Color kLightBackground = Color(0xFFF4F4F5);
  static const Color kLightSurfaceDark = Color(0xFFE4E4E7);
  static const Color kLightBorderColor = Color(0xFFD4D4D8);

  // Theme color options
  static const List<Color> kPrimaryColors = [
    Color(0xFF8B5CF6), // Default purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
  ];

  static const List<Color> kSecondaryColors = [
    Color(0xFF22D3EE), // Default cyan
    Color(0xFF6EE7B7), // Mint
    Color(0xFFFBBF24), // Yellow
    Color(0xFF818CF8), // Indigo
  ];

  // File extensions
  static const Set<String> kAllowedFileExtensions = {
    'json',
    'md',
    'txt',
    'cs',
    'js',
    'py',
    'java',
    'cpp',
    'css',
    'html',
    'xml',
    'yaml',
    'ini',
    'toml',
    'htm',
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
  };

  static const Set<String> kImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
  };

  static const Set<String> kDocumentExtensions = {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'md',
    'json',
    'csv',
    'rtf',
  };

  // Default values
  static const double kDefaultTemperature = 0.7;
  static const String kDefaultSystemPrompt =
      'You are a helpful AI assistant. Be concise and clear in your responses.';

  // UI Constants
  static const double kSidebarWidth = 250.0;
  static const double kMaxContentWidth = 800.0;
  static const double kMaxChatWidth = 600.0;
  static const double kMaxInputHeight = 200.0;
  static const double kMinInputHeight = 56.0;

  // Animation durations
  static const Duration kFastDuration = Duration(milliseconds: 200);
  static const Duration kNormalDuration = Duration(milliseconds: 300);
  static const Duration kSlowDuration = Duration(milliseconds: 500);

  // Pagination
  static const int kSessionsPageSize = 20;
  static const int kChatsPageSize = 50;
  static const int kMaxFilesPerUpload = 10;

  // TTS Settings
  static const double kDefaultSpeechRate = 0.4;
  static const double kDefaultVolume = 0.9;
  static const double kDefaultPitch = 1.5;
  static const String kDefaultLanguage = 'en-us';
}
