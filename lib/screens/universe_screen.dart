import 'package:flutter/material.dart';
import '../data_notifier.dart';
import '../database.dart';
import '../models.dart';

class UniverseScreen extends StatefulWidget {
  const UniverseScreen({super.key});
  @override
  State<UniverseScreen> createState() => _UniverseScreenState();
}

class _UniverseScreenState extends State<UniverseScreen> {
  final _db = DatabaseHelper.instance;
  Map<String, List<Word>> _families = {};
  Map<String, String> _roots = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DataNotifier.instance.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    DataNotifier.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final all = await _db.getAllWords();
    final m = <String, List<Word>>{};
    final rm = <String, String>{};
    for (final w in all) {
      m.putIfAbsent(w.family, () => []).add(w);
      rm[w.family] = w.rootMeaning;
    }
    if (!mounted) return;
    setState(() {
      _families = m;
      _roots = rm;
      _loading = false;
    });
  }

  Color _colorFor(Word w) {
    if (w.isMastered) return Colors.green;
    if (w.wrongCount > w.correctCount) return Colors.red;
    if (w.consecutiveCorrect > 0) return Colors.orange;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Kelime Evreni')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: _families.entries.map((e) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🌿 ${e.key}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('(${_roots[e.key] ?? ''})',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: e.value.map((w) {
                      final attempts = w.correctCount + w.wrongCount;
                      final size = 60.0 + (attempts.clamp(0, 8) * 4);
                      return GestureDetector(
                        onTap: () => _showDetail(w),
                        child: Tooltip(
                          message: '${w.english} → ${w.turkish}',
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _colorFor(w).withOpacity(0.8),
                                  _colorFor(w).withOpacity(0.4),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _colorFor(w).withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              w.english,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _legend(Colors.blueGrey, 'Yeni'),
                      const SizedBox(width: 10),
                      _legend(Colors.orange, 'Öğreniyor'),
                      const SizedBox(width: 10),
                      _legend(Colors.green, 'Ustalaştı'),
                      const SizedBox(width: 10),
                      _legend(Colors.red, 'Zorlanıyor'),
                    ],
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      );

  void _showDetail(Word w) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${w.english} (${w.pos})',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(w.turkish, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  '🌿 Kök: ${w.root} (${w.rootMeaning})\n${w.morphology}'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('Doğru: ${w.correctCount}')),
                Chip(label: Text('Yanlış: ${w.wrongCount}')),
                Chip(
                    label:
                        Text(w.isMastered ? '✓ Ustalaştı' : 'Öğreniyor'),
                    backgroundColor:
                        w.isMastered ? Colors.green.shade100 : null),
                if (w.nextReview != null)
                  Chip(
                      label: Text(
                          'Sonraki: ${w.nextReview!.toString().substring(0, 10)}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}