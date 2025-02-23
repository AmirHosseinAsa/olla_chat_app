import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'pages/chat_page.dart';
import 'utils/util.dart';

class OllaChatApp extends StatelessWidget {
  const OllaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Update global font
        Util.appFont = themeProvider.font;
        
        return MaterialApp(
          title: 'OllaChat',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getTheme(),
          themeMode: ThemeMode.dark,
          home: child,
        );
      },
      child: const ChatPage(onThemeToggle: null), // Prevent ChatPage from rebuilding when theme changes
    );
  }
}
