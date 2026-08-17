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
  static const int maxIndexedSources = 10;
  static final Map<String, List<ReverseCitation>> _indexedSources = {};
  static final Map<int, Map<int, List<ReverseCitation>>> _chapterIndex = {};
  static final Map<int, Map<int, Map<int, List<ReverseCitation>>>> _verseIndex =
      {};
  static Future<void>? _inFlightIndexing;

  @visibleForTesting
  static int get indexedSourcesCount => _indexedSources.length;

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
        final catalogPaths = [
          'assets/catechism/json/baltimore_1.json',
          'assets/catechism/json/baltimore_2.json',
          'assets/catechism/json/baltimore_3.json',
          'assets/catechism/json/baltimore_4.json',
          'assets/catechism/json/council_of_trent.json',
          'assets/catechism/json/didache_lightfoot.json',
        ];

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

  static void _rebuildIndices() {
    _chapterIndex.clear();
    _verseIndex.clear();

    for (final citations in _indexedSources.values) {
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
  }

  static void indexBookData(String sourceKey, ParsedBookData bookData) {
    if (_indexedSources.containsKey(sourceKey)) {
      _indexedSources.remove(sourceKey);
    } else if (_indexedSources.length >= maxIndexedSources) {
      _indexedSources.remove(_indexedSources.keys.first);
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
    _rebuildIndices();
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
