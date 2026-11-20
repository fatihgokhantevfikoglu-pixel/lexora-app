import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../data_notifier.dart';
import '../database.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('🎨 Tema'),
          Wrap(
            spacing: 8,
            children: [
              _themeChip(context, state, 'midnight', 'Midnight', Colors.indigo),
              _themeChip(context, state, 'paper', 'Paper', Colors.brown),
              _themeChip(context, state, 'forest', 'Forest', Colors.green),
              _themeChip(context, state, 'light', 'Light', Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 20),
          _section('📦 Parti Boyutu'),
          Text(
              'Eşleştirme ekranında aynı anda gösterilen kelime sayısı: ${state.batchSize}',
              style: const TextStyle(fontSize: 13)),
          Slider(
            min: 4,
            max: 10,
            divisions: 6,
            value: state.batchSize.toDouble(),
            label: '${state.batchSize}',
            onChanged: (v) => state.setBatchSize(v.round()),
          ),
          const SizedBox(height: 20),
          _section('ℹ️ Hakkında'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LEXORA 2.0',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text(
                      'Kök odaklı İngilizce kelime öğrenme. SM-2 aralıklı tekrar algoritması, morfolojik kök analizi, kişisel istatistikler, internetten otomatik kelime genişletme.',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _section('⚠️ Tehlikeli Bölge'),
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text('Tüm İlerlemeyi Sıfırla'),
              subtitle: const Text(
                  'İstatistikler ve kelime durumları başlangıca döner.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _confirmReset(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(t,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );

  Widget _themeChip(
      BuildContext c, AppState s, String key, String label, Color color) {
    final sel = s.themeName == key;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      selectedColor: color.withOpacity(0.3),
      avatar: CircleAvatar(backgroundColor: color, radius: 6),
      onSelected: (_) => s.setTheme(key),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content:
            const Text('Tüm ilerleme silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sıfırla')),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.resetAll();
      DataNotifier.instance.notify();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İlerleme sıfırlandı.')));
      }
    }
  }
}