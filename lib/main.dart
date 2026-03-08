import 'package:flutter/material.dart';
import 'screens/main_menu.dart';
import 'screens/game_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/leaderboard_screen.dart';

void main() {
  runApp(const HexaFallApp());
}

class HexaFallApp extends StatelessWidget {
  const HexaFallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hexa Fall',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainMenu(),
        '/game': (context) => const GameScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
    );
  }
}