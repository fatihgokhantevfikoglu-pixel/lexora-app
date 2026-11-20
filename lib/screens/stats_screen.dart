import 'package:flutter/material.dart';
import '../data_notifier.dart';
import '../database.dart';
import '../models.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _db = DatabaseHelper.instance;
  Map<String, int> _summary = {};
  List<Word> _topWrong = [];
  List<Map<String, dynamic>> _daily = [];
  List<Map<String, dynamic>> _roots = [];
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
    final s = await _db.getSummaryStats();
    final tw = await _db.getTopWrong();
    final dl = await _db.getDailyActivity();
    final rt = await _db.getRootStats();
    if (!mounted) return;
    setState(() {
      _summary = s;
      _topWrong = tw;
      _daily = dl;
      _roots = rt;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _kpiGrid(),
            const SizedBox(height: 16),
            _section('📈 Son 30 Gün'),
            _dailyChart(),
            const SizedBox(height: 16),
            _section('🔥 En Çok Yanlış Yapılanlar'),
            _topWrongList(),
            const SizedBox(height: 16),
            _section('🌿 Kök Analizi'),
            _rootList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _kpiGrid() {
    final items = [
      ('Toplam Kelime', '${_summary['total'] ?? 0}', Colors.indigo),
      ('Ustalaşılan', '${_summary['mastered'] ?? 0}', Colors.green),
      ('Öğreniliyor', '${_summary['learning'] ?? 0}', Colors.orange),
      ('Tekrar Bekleyen', '${_summary['due'] ?? 0}', Colors.red),
      ('Doğru', '${_summary['correct'] ?? 0}', Colors.teal),
      ('Yanlış', '${_summary['wrong'] ?? 0}', Colors.pink),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: items.map((it) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(it.$1,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(it.$2,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: it.$3)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dailyChart() {
    if (_daily.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Henüz veri yok.')),
        ),
      );
    }
    final maxV = _daily.fold<int>(1, (m, r) {
      final v = (r['total'] as int?) ?? 0;
      return v > m ? v : m;
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _daily.map((r) {
              final total = (r['total'] as int?) ?? 0;
              final correct = (r['correct'] as int?) ?? 0;
              final h = (total / maxV) * 100;
              final ch = (correct / maxV) * 100;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                            color: Colors.indigo.shade300,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3))),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: ch,
                            color: Colors.green.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('${r['day'].toString().substring(8)}',
                          style: const TextStyle(fontSize: 7)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _topWrongList() {
    if (_topWrong.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Henüz yanlış yok. Harika!')),
        ),
      );
    }
    return Card(
      child: Column(
        children: _topWrong.map((w) {
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Text('${w.wrongCount}',
                  style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(w.english,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${w.turkish} • kök: ${w.root}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _rootList() {
    if (_roots.isEmpty) return const SizedBox();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: _roots.map((r) {
            final wc = (r['word_count'] as int?) ?? 0;
            final wrong = (r['wrong'] as int?) ?? 0;
            final correct = (r['correct'] as int?) ?? 0;
            final total = wrong + correct;
            final ratio = total == 0 ? 0.0 : correct / total;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${r['root']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('(${r['root_meaning']})',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                      const Spacer(),
                      Text('$wc kelime',
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: ratio, minHeight: 6),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}