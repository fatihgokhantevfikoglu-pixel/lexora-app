class Word {
  final int? id;
  final String english;
  final String turkish;
  final String pos;
  final String root;
  final String rootMeaning;
  final String morphology;
  final String family;
  int correctCount;
  int wrongCount;
  int consecutiveCorrect;
  bool isMastered;
  DateTime? lastReviewed;
  DateTime? nextReview;
  double easeFactor;
  int intervalDays;
  int repetitions;
  int timesShown;

  Word({
    this.id,
    required this.english,
    required this.turkish,
    required this.pos,
    required this.root,
    required this.rootMeaning,
    required this.morphology,
    required this.family,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.consecutiveCorrect = 0,
    this.isMastered = false,
    this.lastReviewed,
    this.nextReview,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.timesShown = 0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'english': english,
        'turkish': turkish,
        'pos': pos,
        'root': root,
        'root_meaning': rootMeaning,
        'morphology': morphology,
        'family': family,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'consecutive_correct': consecutiveCorrect,
        'is_mastered': isMastered ? 1 : 0,
        'last_reviewed': lastReviewed?.toIso8601String(),
        'next_review': nextReview?.toIso8601String(),
        'ease_factor': easeFactor,
        'interval_days': intervalDays,
        'repetitions': repetitions,
        'times_shown': timesShown,
      };

  factory Word.fromMap(Map<String, dynamic> m) => Word(
        id: m['id'] as int?,
        english: m['english'] as String,
        turkish: m['turkish'] as String,
        pos: m['pos'] as String,
        root: m['root'] as String,
        rootMeaning: m['root_meaning'] as String,
        morphology: m['morphology'] as String,
        family: m['family'] as String,
        correctCount: (m['correct_count'] as int?) ?? 0,
        wrongCount: (m['wrong_count'] as int?) ?? 0,
        consecutiveCorrect: (m['consecutive_correct'] as int?) ?? 0,
        isMastered: ((m['is_mastered'] as int?) ?? 0) == 1,
        lastReviewed: m['last_reviewed'] != null
            ? DateTime.parse(m['last_reviewed'] as String)
            : null,
        nextReview: m['next_review'] != null
            ? DateTime.parse(m['next_review'] as String)
            : null,
        easeFactor: (m['ease_factor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: (m['interval_days'] as int?) ?? 0,
        repetitions: (m['repetitions'] as int?) ?? 0,
        timesShown: (m['times_shown'] as int?) ?? 0,
      );
}