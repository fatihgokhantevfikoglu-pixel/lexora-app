import 'models.dart';

class SRSService {
  /// quality: 0=Again, 1=Hard, 2=Good, 3=Easy → SM-2 q değerine map
  static void schedule(Word word, int quality) {
    const map = {0: 1, 1: 3, 2: 4, 3: 5};
    final q = map[quality] ?? 4;

    if (q < 3) {
      word.repetitions = 0;
      word.intervalDays = 1;
    } else {
      if (word.repetitions == 0) {
        word.intervalDays = 1;
      } else if (word.repetitions == 1) {
        word.intervalDays = 6;
      } else {
        word.intervalDays = (word.intervalDays * word.easeFactor).round();
      }
      word.repetitions++;
    }

    word.easeFactor =
        word.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (word.easeFactor < 1.3) word.easeFactor = 1.3;

    word.lastReviewed = DateTime.now();
    word.nextReview = DateTime.now().add(Duration(days: word.intervalDays));
  }
}