import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TexasHoldApp());
}

class TexasHoldApp extends StatelessWidget {
  const TexasHoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Texas Hold'em",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
