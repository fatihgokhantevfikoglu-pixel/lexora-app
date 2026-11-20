import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  static const _dictBase = 'https://api.dictionaryapi.dev/api/v2/entries/en';
  static const _datamuseBase = 'https://api.datamuse.com';

  Future<Map<String, dynamic>?> fetchWordDetails(String word) async {
    try {
      final res = await http.get(Uri.parse('$_dictBase/$word'));
      if (res.statusCode != 200) return null;
      final List data = jsonDecode(res.body);
      if (data.isEmpty) return null;

      final entry = data[0];
      final meanings = entry['meanings'] as List?;
      final origin = entry['origin'] as String? ?? '';

      String pos = 'n.';
      String definition = '';
      if (meanings != null && meanings.isNotEmpty) {
        pos = meanings[0]['partOfSpeech'] ?? 'n.';
        final defs = meanings[0]['definitions'] as List?;
        if (defs != null && defs.isNotEmpty) {
          definition = defs[0]['definition'] ?? '';
        }
      }

      return {
        'word': word,
        'pos': _abbreviatePos(pos),
        'definition': definition,
        'origin': origin,
      };
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> fetchRelatedWords(String seed, {int limit = 10}) async {
    try {
      final res = await http
          .get(Uri.parse('$_datamuseBase/words?ml=$seed&max=$limit&md=d'));
      if (res.statusCode != 200) return [];
      final List data = jsonDecode(res.body);
      return data
          .map((e) => e['word'] as String?)
          .whereType<String>()
          .where((w) => w.length > 2 && !w.contains(' '))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Word>> enrichAndCreateWords(List<String> rawWords) async {
    final List<Word> newWords = [];
    for (final raw in rawWords) {
      final details = await fetchWordDetails(raw);
      if (details == null) continue;

      final origin = details['origin'] as String? ?? '';
      final rootInfo = _extractRootFromOrigin(origin);

      newWords.add(Word(
        english: raw,
        turkish: '(çeviri bekleniyor)',
        pos: details['pos'] as String? ?? 'n.',
        root: rootInfo['root'] ?? 'unknown',
        rootMeaning: rootInfo['meaning'] ?? 'bilinmiyor',
        morphology: origin.isNotEmpty ? origin : 'Köken bilgisi yok',
        family: rootInfo['root'] ?? 'misc',
      ));
    }
    return newWords;
  }

  Map<String, String> _extractRootFromOrigin(String origin) {
    final lower = origin.toLowerCase();
    final rootPatterns = {
      'fer': 'taşımak',
      'port': 'taşımak',
      'spect': 'bakmak',
      'dict': 'söylemek',
      'scrib': 'yazmak',
      'script': 'yazmak',
      'vis': 'görmek',
      'vid': 'görmek',
      'aud': 'duymak',
      'man': 'el',
      'mit': 'göndermek',
      'miss': 'göndermek',
      'duc': 'yönetmek',
      'duct': 'yönetmek',
      'tract': 'çekmek',
      'pos': 'koymak',
      'pon': 'koymak',
    };
    for (final entry in rootPatterns.entries) {
      if (lower.contains(entry.key)) {
        return {'root': entry.key, 'meaning': entry.value};
      }
    }
    final match = RegExp(r'from\s+(\w+)').firstMatch(lower);
    return {
      'root': match?.group(1) ?? 'unknown',
      'meaning': 'bilinmiyor',
    };
  }

  String _abbreviatePos(String pos) {
    switch (pos) {
      case 'noun': return 'n.';
      case 'verb': return 'v.';
      case 'adjective': return 'adj.';
      case 'adverb': return 'adv.';
      default: return pos;
    }
  }
}