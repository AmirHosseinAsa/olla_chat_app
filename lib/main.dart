import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'providers/theme_provider.dart';
import 'objectbox/objectbox.dart';
import 'pages/chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ObjectBox
  objectbox = await ObjectBox.create();

  // Initialize window manager
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();

  // Configure window
  await windowManager.setTitle('OllaChat');
  await windowManager.setMinimumSize(const Size(800, 600));
  await windowManager.setSize(const Size(1200, 800));
  await windowManager.center();
  await windowManager.show();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const OllaChatApp(),
    ),
  );
}

class OllaChatApp extends StatelessWidget {
  const OllaChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'OllaChat',
          theme: themeProvider.getTheme(),
          themeMode: ThemeMode.dark,
          home: ChatPage(onThemeToggle: () {}),
        );
      },
    );
  }
}
