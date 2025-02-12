import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'pages/chat_page.dart';

class OllaChatApp extends StatelessWidget {
  const OllaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'OllaChat',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getTheme(),
          themeMode: ThemeMode.dark,
          home: ChatPage(onThemeToggle: null),
        );
      },
    );
  }
}
