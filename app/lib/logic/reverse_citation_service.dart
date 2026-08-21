import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/library_database.dart';

class ReverseCitation {
  final String sourceBookId;
  final String sourceAssetPath;
  final String sourceBookTitle;
  final String sectionId;
  final String sectionTitle;
  final int? questionNumber;
  final String snippet;
  final BibleCitation citation;

  const ReverseCitation({
    required this.sourceBookId,
    required this.sourceAssetPath,
    required this.sourceBookTitle,
    required this.sectionId,
    required this.sectionTitle,
    this.questionNumber,
    required this.snippet,
    required this.citation,
  });
}

class ReverseCitationService {
  static const int maxIndexedSources = 80;
  static final Map<String, List<ReverseCitation>> _indexedSources = {};
  static final Map<int, Map<int, List<ReverseCitation>>> _chapterIndex = {};
  static final Map<int, Map<int, Map<int, List<ReverseCitation>>>> _verseIndex =
      {};
  static Future<void>? _inFlightIndexing;

  static int get indexedSourcesCount => _indexedSources.length;

  static List<String> get catalogPaths => const [
    'assets/catechism/json/baltimore_1.json',
    'assets/catechism/json/baltimore_2.json',
    'assets/catechism/json/baltimore_3.json',
    'assets/catechism/json/baltimore_4.json',
    'assets/catechism/json/council_of_trent.json',
    'assets/catechism/json/didache_lightfoot.json',
    'assets/catechism/json/first_clement_lightfoot.json',
    'assets/catechism/json/second_clement_lightfoot.json',
    'assets/catechism/json/ignatius_ephesians_lightfoot.json',
    'assets/catechism/json/ignatius_magnesians_lightfoot.json',
    'assets/catechism/json/ignatius_trallians_lightfoot.json',
    'assets/catechism/json/ignatius_romans_lightfoot.json',
    'assets/catechism/json/ignatius_philadelphians_lightfoot.json',
    'assets/catechism/json/ignatius_smyrnaeans_lightfoot.json',
    'assets/catechism/json/ignatius_polycarp_lightfoot.json',
    'assets/catechism/json/polycarp_philippians_lightfoot.json',
    'assets/catechism/json/polycarp_martyrdom_lightfoot.json',
    'assets/catechism/json/diognetus_lightfoot.json',
    'assets/catechism/json/justin_first_apology_dods.json',
    'assets/catechism/json/justin_second_apology_dods.json',
    'assets/catechism/json/justin_dialogue_trypho_dods.json',
    'assets/catechism/json/irenaeus_against_heresies_book1.json',
    'assets/catechism/json/irenaeus_against_heresies_book2.json',
    'assets/catechism/json/irenaeus_against_heresies_book3.json',
    'assets/catechism/json/irenaeus_against_heresies_book4.json',
    'assets/catechism/json/irenaeus_against_heresies_book5.json',
    'assets/catechism/json/athanasius_on_the_incarnation.json',
    'assets/catechism/json/augustine_confessions_book1.json',
    'assets/catechism/json/augustine_confessions_book2.json',
    'assets/catechism/json/augustine_confessions_book3.json',
    'assets/catechism/json/augustine_confessions_book4.json',
    'assets/catechism/json/augustine_confessions_book5.json',
    'assets/catechism/json/augustine_confessions_book6.json',
    'assets/catechism/json/augustine_confessions_book7.json',
    'assets/catechism/json/augustine_confessions_book8.json',
    'assets/catechism/json/augustine_confessions_book9.json',
    'assets/catechism/json/augustine_confessions_book10.json',
    'assets/catechism/json/augustine_confessions_book11.json',
    'assets/catechism/json/augustine_confessions_book12.json',
    'assets/catechism/json/augustine_confessions_book13.json',
    'assets/catechism/json/augustine_city_of_god_book1.json',
    'assets/catechism/json/augustine_city_of_god_book2.json',
    'assets/catechism/json/augustine_city_of_god_book3.json',
    'assets/catechism/json/augustine_city_of_god_book4.json',
    'assets/catechism/json/augustine_city_of_god_book5.json',
    'assets/catechism/json/augustine_city_of_god_book6.json',
    'assets/catechism/json/augustine_city_of_god_book7.json',
    'assets/catechism/json/augustine_city_of_god_book8.json',
    'assets/catechism/json/augustine_city_of_god_book9.json',
    'assets/catechism/json/augustine_city_of_god_book10.json',
    'assets/catechism/json/augustine_city_of_god_book11.json',
    'assets/catechism/json/augustine_city_of_god_book12.json',
    'assets/catechism/json/augustine_city_of_god_book13.json',
    'assets/catechism/json/augustine_city_of_god_book14.json',
    'assets/catechism/json/augustine_city_of_god_book15.json',
    'assets/catechism/json/augustine_city_of_god_book16.json',
    'assets/catechism/json/augustine_city_of_god_book17.json',
    'assets/catechism/json/augustine_city_of_god_book18.json',
    'assets/catechism/json/augustine_city_of_god_book19.json',
    'assets/catechism/json/augustine_city_of_god_book20.json',
    'assets/catechism/json/augustine_city_of_god_book21.json',
    'assets/catechism/json/augustine_city_of_god_book22.json',
    'assets/catechism/json/cyril_catechetical_lectures_vol1.json',
    'assets/catechism/json/cyril_catechetical_lectures_vol2.json',
    'assets/catechism/json/cyril_catechetical_lectures_vol3.json',
    'assets/catechism/json/cyril_catechetical_lectures_vol4.json',
    'assets/catechism/json/john_cross_ascent_mount_carmel.json',
    'assets/catechism/json/john_cross_dark_night_soul.json',
    'assets/catechism/json/montfort_true_devotion.json',
    'assets/catechism/json/anselm_proslogion.json',
    'assets/catechism/json/anselm_cur_deus_homo_book1.json',
    'assets/catechism/json/anselm_cur_deus_homo_book2.json',
    'assets/catechism/json/benedict_rule.json',
    'assets/catechism/json/sales_devout_life_part1.json',
    'assets/catechism/json/sales_devout_life_part2.json',
    'assets/catechism/json/sales_devout_life_part3.json',
    'assets/catechism/json/sales_devout_life_part4.json',
    'assets/catechism/json/sales_devout_life_part5.json',
    'assets/catechism/json/teresa_interior_castle.json',
  ];

  @visibleForTesting
  static int get totalIndexedCitations =>
      _indexedSources.values.fold(0, (sum, list) => sum + list.length);

  @visibleForTesting
  static bool get isInFlightIndexing => _inFlightIndexing != null;

  @visibleForTesting
  static void clear() {
    _indexedSources.clear();
    _chapterIndex.clear();
    _verseIndex.clear();
    _inFlightIndexing = null;
  }

  static void prune() {
    bool changed = false;
    while (_indexedSources.length > maxIndexedSources) {
      _indexedSources.remove(_indexedSources.keys.first);
      changed = true;
    }
    if (changed) {
      _rebuildIndices();
    }
  }

  static Future<void> ensureIndexed() {
    if (_inFlightIndexing != null) return _inFlightIndexing!;
    final future = () async {
      try {
        final catalogPaths = ReverseCitationService.catalogPaths;

        for (final path in catalogPaths) {
          if (_indexedSources.containsKey(path)) {
            final existing = _indexedSources.remove(path)!;
            _indexedSources[path] = existing;
            continue;
          }
          try {
            final rawJson = await rootBundle.loadString(path);
            final bookData = ParsedBookData.fromJson(
              jsonDecode(rawJson) as Map<String, dynamic>,
            );
            indexBookData(path, bookData);
          } catch (e, stack) {
            debugPrint(
              'ReverseCitationService error indexing $path: $e\n$stack',
            );
          }
        }
      } finally {
        _inFlightIndexing = null;
      }
    }();
    _inFlightIndexing = future;
    return future;
  }

  static void _insertCitations(Iterable<ReverseCitation> citations) {
    for (final rc in citations) {
      final c = rc.citation;
      final b = c.bookNumber;
      final ch = c.chapter;

      if (c.isEntireChapter) {
        _chapterIndex
            .putIfAbsent(b, () => {})
            .putIfAbsent(ch, () => [])
            .add(rc);
      } else if (c.verse != null) {
        final start = c.verse!;
        final end = c.endVerse ?? start;
        final bookChapterMap = _verseIndex
            .putIfAbsent(b, () => {})
            .putIfAbsent(ch, () => {});
        for (int v = start; v <= end; v++) {
          bookChapterMap.putIfAbsent(v, () => []).add(rc);
        }
      }
    }
  }

  static void _rebuildIndices() {
    _chapterIndex.clear();
    _verseIndex.clear();

    for (final citations in _indexedSources.values) {
      _insertCitations(citations);
    }
  }

  static void indexBookData(String sourceKey, ParsedBookData bookData) {
    bool needsFullRebuild = false;
    if (_indexedSources.containsKey(sourceKey)) {
      _indexedSources.remove(sourceKey);
      needsFullRebuild = true;
    } else if (_indexedSources.length >= maxIndexedSources) {
      _indexedSources.remove(_indexedSources.keys.first);
      needsFullRebuild = true;
    }

    final List<ReverseCitation> citations = [];
    for (final sec in bookData.sections) {
      for (final item in sec.content) {
        final textToParse = [
          if (item.question != null) item.question!,
          if (item.answer != null) item.answer!,
          if (item.explanation != null) item.explanation!,
          if (item.text != null) item.text!,
        ].join(' ');

        if (textToParse.isEmpty) continue;

        final segments = BibleCitationParser.parse(
          textToParse,
          verseSystem: bookData.verseSystem,
        );
        for (final seg in segments) {
          if (seg.isCitation) {
            citations.add(
              ReverseCitation(
                sourceBookId: bookData.bookId,
                sourceAssetPath: sourceKey,
                sourceBookTitle: bookData.title,
                sectionId: sec.id,
                sectionTitle: sec.title,
                questionNumber: item.questionNumber,
                snippet: item.question ?? item.text ?? sec.title,
                citation: seg.citation!,
              ),
            );
          }
        }
      }
    }
    _indexedSources[sourceKey] = citations;
    if (needsFullRebuild) {
      _rebuildIndices();
    } else {
      _insertCitations(citations);
    }
  }

  static List<ReverseCitation> getChapterCitations(
    int bookNumber,
    int chapter,
  ) {
    return _chapterIndex[bookNumber]?[chapter] ?? const [];
  }

  static List<ReverseCitation> getVerseCitations(
    int bookNumber,
    int chapter,
    int verseNumber,
  ) {
    return _verseIndex[bookNumber]?[chapter]?[verseNumber] ?? const [];
  }
}
