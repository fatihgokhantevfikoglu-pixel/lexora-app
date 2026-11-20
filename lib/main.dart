import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'database.dart';
import 'screens/match_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/universe_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? dbError;
  try {
    // Veritabanını başlat (Hata olursa ekranda göstermek için yakalıyoruz)
    await DatabaseHelper.instance.init();
  } catch (e) {
    dbError = e.toString();
  }
  runApp(LexoraApp(dbError: dbError));
}

class LexoraApp extends StatelessWidget {
  final String? dbError;
  const LexoraApp({super.key, this.dbError});

  @override
  Widget build(BuildContext context) {
    // EĞER VERİTABANI HATA VERİRSE EKRANDA GÖSTER
    if (dbError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Veritabanı Hatası:\n\n$dbError',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: Consumer<AppState>(
        builder: (_, state, __) => MaterialApp(
          title: 'LEXORA',
          debugShowCheckedModeBanner: false,
          theme: state.currentTheme,
          home: const RootShell(),
        ),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _i = 0;
  static const _screens = [
    MatchScreen(),
    StatsScreen(),
    UniverseScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.gamepad_outlined), selectedIcon: Icon(Icons.gamepad), label: 'Eşleştir'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'İstatistik'),
          NavigationDestination(icon: Icon(Icons.bubble_chart_outlined), selectedIcon: Icon(Icons.bubble_chart), label: 'Evren'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}
