import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';
import 'seed_data.dart';
import 'api_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();
  Database? _db;
  Future<Database>? _dbFuture; // YENİ: Eşzamanlı istekleri engeller
  final _api = ApiService();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _dbFuture ??= _open();
    _db = await _dbFuture;
    return _db!;
  }

  Future<void> init() async {
    await db;
  }

    Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'lexora.db');
    return openDatabase(
      path,
      version: 2, // SÜRÜMÜ 2 YAPTIK: Eski veritabanı silinecek
      onCreate: (db, v) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // Eski bozuk tabloları sil ve yeniden oluştur
        await db.execute('DROP TABLE IF EXISTS words');
        await db.execute('DROP TABLE IF EXISTS review_log');
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        english TEXT UNIQUE NOT NULL,
        turkish TEXT NOT NULL,
        pos TEXT NOT NULL,
        root TEXT NOT NULL,
        root_meaning TEXT NOT NULL,
        morphology TEXT NOT NULL,
        family TEXT NOT NULL,
        correct_count INTEGER DEFAULT 0,
        wrong_count INTEGER DEFAULT 0,
        consecutive_correct INTEGER DEFAULT 0,
        is_mastered INTEGER DEFAULT 0,
        last_reviewed TEXT,
        next_review TEXT,
        ease_factor REAL DEFAULT 2.5,
        interval_days INTEGER DEFAULT 0,
        repetitions INTEGER DEFAULT 0,
        times_shown INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE review_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        was_correct INTEGER NOT NULL,
        quality INTEGER NOT NULL,
        response_time_ms INTEGER NOT NULL,
        reviewed_at TEXT NOT NULL
      )
    ''');
    final batch = db.batch();
    for (final w in seedWords) {
      batch.insert('words', w.toMap());
    }
    await batch.commit(noResult: true);
  }
  
  Future<List<Word>> getActiveWords() async {
    final d = await db;
    final rows = await d.query('words', where: 'is_mastered = 0');
    return rows.map((r) => Word.fromMap(r)).toList();
  }

  Future<List<Word>> getAllWords() async {
    final d = await db;
    final rows = await d.query('words');
    return rows.map((r) => Word.fromMap(r)).toList();
  }

  Future<void> updateWord(Word w) async {
    final d = await db;
    await d.update('words', w.toMap(), where: 'id = ?', whereArgs: [w.id]);
  }

  Future<int> fetchAndStoreNewWords({int count = 10}) async {
    final d = await db;
    final existingRows = await d.query('words', columns: ['english']);
    final existing = existingRows.map((r) => r['english'] as String).toSet();

    final seeds = seedWords.map((w) => w.english).toList();
    final randomSeed = (seeds..shuffle()).first;
    final related = await _api.fetchRelatedWords(randomSeed, limit: count + 5);

    final candidates =
        related.where((w) => !existing.contains(w)).take(count).toList();
    if (candidates.isEmpty) return 0;

    final enriched = await _api.enrichAndCreateWords(candidates);

    int added = 0;
    for (final w in enriched) {
      try {
        await d.insert('words', w.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
        added++;
      } catch (_) {}
    }
    return added;
  }

  Future<void> logReview(int wordId, bool correct, int quality, int ms) async {
    final d = await db;
    await d.insert('review_log', {
      'word_id': wordId,
      'was_correct': correct ? 1 : 0,
      'quality': quality,
      'response_time_ms': ms,
      'reviewed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, int>> getSummaryStats() async {
    final d = await db;
    final total = Sqflite.firstIntValue(
            await d.rawQuery('SELECT COUNT(*) FROM words')) ??
        0;
    final mastered = Sqflite.firstIntValue(await d
            .rawQuery('SELECT COUNT(*) FROM words WHERE is_mastered = 1')) ??
        0;
    final correct = Sqflite.firstIntValue(
            await d.rawQuery('SELECT COALESCE(SUM(correct_count),0) FROM words')) ??
        0;
    final wrong = Sqflite.firstIntValue(
            await d.rawQuery('SELECT COALESCE(SUM(wrong_count),0) FROM words')) ??
        0;
    final due = Sqflite.firstIntValue(await d.rawQuery(
            'SELECT COUNT(*) FROM words WHERE is_mastered = 0 AND (next_review IS NULL OR next_review <= ?)',
            [DateTime.now().toIso8601String()])) ??
        0;
    return {
      'total': total,
      'mastered': mastered,
      'correct': correct,
      'wrong': wrong,
      'due': due,
      'learning': total - mastered,
    };
  }

  Future<List<Map<String, dynamic>>> getRootStats() async {
    final d = await db;
    return d.rawQuery('''
      SELECT root, root_meaning,
             COUNT(*) as word_count,
             SUM(correct_count) as correct,
             SUM(wrong_count) as wrong
      FROM words
      GROUP BY root
      ORDER BY word_count DESC
    ''');
  }

  Future<List<Word>> getTopWrong({int limit = 10}) async {
    final d = await db;
    final rows = await d.query('words',
        where: 'wrong_count > 0', orderBy: 'wrong_count DESC', limit: limit);
    return rows.map((r) => Word.fromMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getDailyActivity({int days = 30}) async {
    final d = await db;
    final from = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    return d.rawQuery('''
      SELECT substr(reviewed_at, 1, 10) as day,
             COUNT(*) as total,
             SUM(was_correct) as correct
      FROM review_log
      WHERE reviewed_at >= ?
      GROUP BY day
      ORDER BY day
    ''', [from]);
  }

  Future<void> resetAll() async {
    final d = await db;
    await d.delete('review_log');
    await d.delete('words');
    for (final w in seedWords) {
      await d.insert('words', w.toMap());
    }
  }
}
