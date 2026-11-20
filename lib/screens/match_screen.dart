import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../data_notifier.dart';
import '../database.dart';
import '../models.dart';
import '../srs.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final _db = DatabaseHelper.instance;
  List<Word> _session = [];
  List<Word> _left = [];
  List<Word> _right = [];
  Word? _selectedLeft;
  Word? _selectedRight;
  bool? _matchResult;
  bool _showHint = false;
  int _sessionCorrect = 0;
  int _sessionWrong = 0;
  DateTime? _tapStart;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadBatch(reset: true));
  }

    Future<void> _loadBatch({bool reset = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      if (reset) {
        _sessionCorrect = 0;
        _sessionWrong = 0;
      }
    });

    try {
      final size = context.read<AppState>().batchSize;
      var all = await _db.getActiveWords();

      if (all.length < size) {
        final added = await _db.fetchAndStoreNewWords(count: size * 2);
        if (added > 0) {
          all = await _db.getActiveWords();
        }
      }

      final now = DateTime.now();
      all.sort((a, b) {
        final aDue = a.nextReview == null || !a.nextReview!.isAfter(now);
        final bDue = b.nextReview == null || !b.nextReview!.isAfter(now);
        if (aDue != bDue) return aDue ? -1 : 1;
        if (a.wrongCount != b.wrongCount) return b.wrongCount.compareTo(a.wrongCount);
        if (a.consecutiveCorrect != b.consecutiveCorrect) {
          return a.consecutiveCorrect.compareTo(b.consecutiveCorrect);
        }
        return a.id!.compareTo(b.id!);
      });

      final batch = all.take(size).toList();
      if (!mounted) return;
      setState(() {
        _session = batch;
        _left = List.from(batch)..shuffle();
        _right = List.from(batch)..shuffle();
        _selectedLeft = null;
        _selectedRight = null;
        _matchResult = null;
        _showHint = false;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Eşleştirme yüklenirken hata: $e");
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }
  
  void _onLeftTap(Word w) {
    if (_busy || _matchResult == true) return;
    setState(() {
      _selectedLeft = w;
      _selectedRight = null;
      _matchResult = null;
      _showHint = true;
      _tapStart = DateTime.now();
    });
  }

  Future<void> _onRightTap(Word w) async {
    if (_busy || _selectedLeft == null || _matchResult == true) return;
    final ms = _tapStart != null
        ? DateTime.now().difference(_tapStart!).inMilliseconds
        : 0;
    final ok = _selectedLeft!.id == w.id;
    setState(() {
      _busy = true;
      _selectedRight = w;
      _matchResult = ok;
      if (ok) {
        _sessionCorrect++;
      } else {
        _sessionWrong++;
      }
    });

    if (ok) {
      final s = _selectedLeft!;
      s.correctCount++;
      s.consecutiveCorrect++;
      s.timesShown++;
      if (s.consecutiveCorrect >= 5) s.isMastered = true;
      await _showQuality(s, ms);
    } else {
      final s = _selectedLeft!;
      s.wrongCount++;
      s.consecutiveCorrect = 0;
      s.timesShown++;
      SRSService.schedule(s, 0);
      await _db.updateWord(s);
      await _db.logReview(s.id!, false, 0, ms);
      DataNotifier.instance.notify();
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _selectedLeft = null;
        _selectedRight = null;
        _matchResult = null;
        _showHint = false;
        _busy = false;
      });
    }
  }

  Future<void> _showQuality(Word w, int ms) async {
    final q = await showModalBottomSheet<int>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _QualitySheet(word: w),
    );
    if (q == null) return;
    SRSService.schedule(w, q);
    await _db.updateWord(w);
    await _db.logReview(w.id!, true, q, ms);
    DataNotifier.instance.notify();
    if (!mounted) return;
    setState(() {
      _session.removeWhere((x) => x.id == w.id);
      _left.removeWhere((x) => x.id == w.id);
      _right.removeWhere((x) => x.id == w.id);
      _selectedLeft = null;
      _selectedRight = null;
      _matchResult = null;
      _showHint = false;
      _busy = false;
    });
    if (_session.length < 2) await _loadBatch();
  }

  Color _btnColor(Word w, bool isLeft) {
    final sel = isLeft ? _selectedLeft == w : _selectedRight == w;
    if (!sel) return Theme.of(context).colorScheme.surfaceContainerHighest;
    if (isLeft && _matchResult == null) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    return _matchResult == true ? Colors.green.shade400 : Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('LEXORA',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3)),
        actions: [
          _chip('Oturum: ${_sessionCorrect + _sessionWrong}'),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _statsBar(),
          Expanded(
            child: _session.length < 2 && _left.isEmpty
                ? _completedView()
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _column(_left, true)),
                        const SizedBox(width: 12),
                        Expanded(child: _column(_right, false)),
                      ],
                    ),
                  ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.black26, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(fontSize: 11)),
      );

  Widget _statsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color:
          Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statPill('✓ $_sessionCorrect', Colors.green),
          _statPill('✗ $_sessionWrong', Colors.red),
          _statPill('Havuz: ${_session.length}', Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _statPill(String txt, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4))),
        child: Text(txt,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      );

  Widget _completedView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 96, color: Colors.amber),
              const SizedBox(height: 16),
              const Text('Tüm kelimeler tamamlandı!',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'Bu oturumdaki tüm kelimeleri ustalaştın ya da liste bitti.\nAyarlar\'dan ilerlemeni sıfırlayabilirsin.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadBatch(reset: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Yeni Oturum'),
              )
            ],
          ),
        ),
      );

  Widget _bottomBar() => Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
                onPressed: () => _loadBatch(reset: true),
                icon: const Icon(Icons.shuffle),
                label: const Text('Karıştır')),
            TextButton.icon(
                onPressed: _loadBatch,
                icon: const Icon(Icons.refresh),
                label: const Text('Yenile')),
          ],
        ),
      );

  Widget _column(List<Word> list, bool isLeft) => ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final w = list[i];
          final sel = isLeft ? _selectedLeft == w : _selectedRight == w;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: _btnColor(w, isLeft),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: isLeft ? () => _onLeftTap(w) : () => _onRightTap(w),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isLeft ? w.english : w.turkish,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: sel && _matchResult != null
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ),
                            if (isLeft)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text(w.pos,
                                    style: const TextStyle(fontSize: 9)),
                              ),
                            if (isLeft && w.wrongCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                child: Text('${w.wrongCount}',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        if (isLeft && _showHint && _selectedLeft == w)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '🌿 ${w.morphology}',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: sel && _matchResult != null
                                    ? Colors.white
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _QualitySheet extends StatelessWidget {
  final Word word;
  const _QualitySheet({required this.word});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${word.english} → ${word.turkish}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  'Kök: ${word.root} (${word.rootMeaning})\n${word.morphology}',
                  style: const TextStyle(
                      fontSize: 12, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 16),
            const Text('Bu kelimeyi nasıl değerlendirirsin?',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _qBtn(context, 'Zor', Colors.orange, 1),
                const SizedBox(width: 8),
                _qBtn(context, 'İyi', Colors.blue, 2),
                const SizedBox(width: 8),
                _qBtn(context, 'Kolay', Colors.green, 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qBtn(BuildContext c, String label, Color color, int q) => Expanded(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
          ),
          onPressed: () => Navigator.pop(c, q),
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
}
