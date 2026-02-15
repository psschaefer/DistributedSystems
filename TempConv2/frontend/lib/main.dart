import 'package:flutter/material.dart';
import 'screens/converter_screen.dart';

void main() {
  runApp(const TempConv2App());
}

class TempConv2App extends StatelessWidget {
  const TempConv2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TempConv2 (gRPC)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const ConverterScreen(),
    );
  }
}
