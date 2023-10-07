import 'package:random_desktop_background/pages/main_page.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';

const appTitle = "Random Desktop Background";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManager.instance.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle(appTitle);
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData.from(colorScheme: const ColorScheme.dark().copyWith(primary: Colors.white)),
      home: const MainPage(),
    );
  }
}
