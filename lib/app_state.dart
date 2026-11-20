import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  String _themeName = 'midnight';
  int _batchSize = 6;

  String get themeName => _themeName;
  int get batchSize => _batchSize;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _themeName = p.getString('theme') ?? 'midnight';
    _batchSize = p.getInt('batchSize') ?? 6;
    notifyListeners();
  }

  Future<void> setTheme(String name) async {
    _themeName = name;
    final p = await SharedPreferences.getInstance();
    await p.setString('theme', name);
    notifyListeners();
  }

  Future<void> setBatchSize(int size) async {
    _batchSize = size;
    final p = await SharedPreferences.getInstance();
    await p.setInt('batchSize', size);
    notifyListeners();
  }

  ThemeData get currentTheme {
    switch (_themeName) {
      case 'paper':
        return _paper;
      case 'forest':
        return _forest;
      case 'light':
        return _light;
      default:
        return _midnight;
    }
  }

  static final _midnight = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C4DFF), brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF0D0D1A),
    appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A2E), foregroundColor: Colors.white),
  );

  static final _paper = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B6F47),
      surface: const Color(0xFFF5F0E1),
    ),
    scaffoldBackgroundColor: const Color(0xFFFAF5E8),
    appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF8B6F47), foregroundColor: Colors.white),
  );

  static final _forest = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32), brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF0F1A0F),
    appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B2E1B), foregroundColor: Colors.white),
  );

  static final _light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    scaffoldBackgroundColor: const Color(0xFFF5F5F7),
  );
}