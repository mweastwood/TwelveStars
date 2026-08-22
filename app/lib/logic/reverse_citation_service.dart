import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/library_database.dart';

class ReverseCitation {
  final String sourceBookId;
  final String sourceAssetPath;
  final String sourceBookTitle;
  final String sourceAuthor;
  final String sectionId;
  final String sectionTitle;
  final int? questionNumber;
  final int itemIndex;
  final String snippet;
  final BibleCitation citation;

  const ReverseCitation({
    required this.sourceBookId,
    required this.sourceAssetPath,
    required this.sourceBookTitle,
    this.sourceAuthor = '',
    required this.sectionId,
    required this.sectionTitle,
    this.questionNumber,
    this.itemIndex = 0,
    required this.snippet,
    required this.citation,
  });
}

class ReverseCitationService {
  static const int maxIndexedSources = 160;
  static final Map<String, List<ReverseCitation>> _indexedSources = {};
  static final Map<int, Map<int, List<ReverseCitation>>> _chapterIndex = {};
  static final Map<int, Map<int, Map<int, List<ReverseCitation>>>> _verseIndex =
      {};
  static Future<void>? _inFlightIndexing;

  static int get indexedSourcesCount => _indexedSources.length;

  static final RegExp _digitRegex = RegExp(r'\d');
  static final RegExp _wordBoundaryRegex = RegExp(
    r'[\s\(\[\{\<"]|[\u201C\u201D\u2018\u2019]',
  );
  static final RegExp _wordTrimRegex = RegExp(r'^[^\w]+|[^\w]+$');
  static final RegExp _singleLetterRegex = RegExp(r'[a-zA-Z]');
  static final RegExp _whitespaceRegex = RegExp(r'\s');

  static const Set<String> _abbreviations = {
    'st',
    'saint',
    'fr',
    'dr',
    'mr',
    'mrs',
    'ms',
    'rev',
    'bp',
    'abp',
    'card',
    'ven',
    'bl',
    'prof',
    'sr',
    'br',
    'e.g',
    'i.e',
    'cf',
    'no',
    'nos',
    'ch',
    'chap',
    'v',
    'vv',
    'ver',
    'vol',
    'vols',
    'p',
    'pp',
    'art',
    'q',
    'qq',
    'sec',
    'etc',
    'viz',
    'al',
    'ca',
    'vs',
    'ad',
    'ibid',
    'op',
    'cit',
    'loc',
    'id',
    'inf',
    'sup',
    'gen',
    'ex',
    'lev',
    'num',
    'deut',
    'jos',
    'jdg',
    'judg',
    'rut',
    'sam',
    'ki',
    'chron',
    'par',
    'paralip',
    'esd',
    'neh',
    'tob',
    'jdt',
    'esth',
    'ps',
    'pss',
    'psa',
    'prov',
    'pro',
    'ecc',
    'eccl',
    'eccles',
    'cant',
    'sng',
    'wis',
    'wisd',
    'sir',
    'ecclus',
    'isa',
    'jer',
    'lam',
    'bar',
    'eze',
    'ezek',
    'dan',
    'hos',
    'joe',
    'joel',
    'amo',
    'amos',
    'oba',
    'obad',
    'jon',
    'mic',
    'nah',
    'hab',
    'zep',
    'zeph',
    'hag',
    'zech',
    'mal',
    'mach',
    'macc',
    'matt',
    'mat',
    'mk',
    'mar',
    'lk',
    'luk',
    'jn',
    'joh',
    'act',
    'acts',
    'rom',
    'cor',
    'gal',
    'eph',
    'php',
    'phil',
    'col',
    'thes',
    'thess',
    'tim',
    'tit',
    'phm',
    'heb',
    'jas',
    'jam',
    'pet',
    'jud',
    'apoc',
    'i',
    'ii',
    'iii',
    'iv',
    'vi',
    'vii',
    'viii',
    'ix',
    'x',
    'xi',
    'xii',
    'xiii',
    'xiv',
    'xv',
    'xvi',
    'xvii',
    'xviii',
    'xix',
    'xx',
    'xxi',
    'xxii',
  };

  static List<String> extractSentences(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return const [];

    final sentences = <String>[];
    int start = 0;
    final len = clean.length;

    for (int i = 0; i < len; i++) {
      final char = clean[i];

      // Paragraph break check
      if (char == '\n') {
        int j = i;
        while (j < len &&
            (clean[j] == '\n' || clean[j] == '\r' || clean[j] == ' ')) {
          j++;
        }
        if (j > i + 1 ||
            (i > start &&
                (clean[i - 1] == '.' ||
                    clean[i - 1] == '!' ||
                    clean[i - 1] == '?'))) {
          final candidate = clean.substring(start, i).trim();
          if (candidate.isNotEmpty) {
            sentences.add(candidate);
          }
          start = j;
          i = j - 1;
          continue;
        }
      }

      if (char == '.' || char == '!' || char == '?') {
        if (char == '.') {
          // Ellipsis check
          if ((i + 1 < len && clean[i + 1] == '.') ||
              (i > 0 && clean[i - 1] == '.')) {
            continue;
          }
          // Decimal check (digit before and digit after)
          if (i > 0 &&
              i + 1 < len &&
              _digitRegex.hasMatch(clean[i - 1]) &&
              _digitRegex.hasMatch(clean[i + 1])) {
            continue;
          }

          // Word preceding period check
          int wordStart = i - 1;
          while (wordStart >= start &&
              !_wordBoundaryRegex.hasMatch(clean[wordStart])) {
            wordStart--;
          }
          wordStart++;
          final word = clean
              .substring(wordStart, i)
              .toLowerCase()
              .replaceAll(_wordTrimRegex, '');

          // Single letter initial check like "J." in "J. B. Lightfoot"
          if (word.length == 1 && _singleLetterRegex.hasMatch(word)) {
            continue;
          }

          if (_abbreviations.contains(word)) {
            continue;
          }
        }

        // Check if closing quotation or bracket follows the punctuation
        int endPunct = i;
        while (endPunct + 1 < len &&
            (clean[endPunct + 1] == '"' ||
                clean[endPunct + 1] == '\'' ||
                clean[endPunct + 1] == '\u201D' ||
                clean[endPunct + 1] == '\u2019' ||
                clean[endPunct + 1] == ')' ||
                clean[endPunct + 1] == ']')) {
          endPunct++;
        }

        // Check if end of text or followed by whitespace
        if (endPunct + 1 >= len ||
            _whitespaceRegex.hasMatch(clean[endPunct + 1])) {
          final sentence = clean.substring(start, endPunct + 1).trim();
          if (sentence.isNotEmpty) {
            sentences.add(sentence);
          }
          int nextStart = endPunct + 1;
          while (nextStart < len &&
              _whitespaceRegex.hasMatch(clean[nextStart])) {
            nextStart++;
          }
          start = nextStart;
          i = start - 1;
        }
      }
    }

    if (start < len) {
      final remaining = clean.substring(start).trim();
      if (remaining.isNotEmpty) {
        sentences.add(remaining);
      }
    }

    return sentences;
  }

  static String _buildContextualSnippet({
    required List<String> sentences,
    required int sentenceIndex,
    String? questionContext,
    String? fieldPrefix,
  }) {
    final windowStart = (sentenceIndex - 4).clamp(0, sentenceIndex);
    final selectedSentences = sentences.sublist(windowStart, sentenceIndex + 1);
    var windowText = selectedSentences.join(' ');
    if (windowStart > 0) {
      windowText = '... $windowText';
    }
    if (fieldPrefix != null && fieldPrefix.isNotEmpty) {
      windowText = '$fieldPrefix$windowText';
    }
    if (questionContext != null && questionContext.trim().isNotEmpty) {
      return 'Q. ${questionContext.trim()}\n$windowText';
    }
    return windowText;
  }

  static List<String> get catalogPaths => LibraryDatabase.getAllCatalogPaths();

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
      for (int itemIdx = 0; itemIdx < sec.content.length; itemIdx++) {
        final item = sec.content[itemIdx];

        void processText({
          required String text,
          String? questionContext,
          String? fieldPrefix,
        }) {
          if (text.trim().isEmpty) return;
          final sentences = extractSentences(text);
          if (sentences.isEmpty) return;

          for (int sIdx = 0; sIdx < sentences.length; sIdx++) {
            final sentence = sentences[sIdx];
            final segments = BibleCitationParser.parse(
              sentence,
              verseSystem: bookData.verseSystem,
            );
            for (final seg in segments) {
              if (seg.isCitation) {
                final snippet = _buildContextualSnippet(
                  sentences: sentences,
                  sentenceIndex: sIdx,
                  questionContext: questionContext,
                  fieldPrefix: fieldPrefix,
                );
                citations.add(
                  ReverseCitation(
                    sourceBookId: bookData.bookId,
                    sourceAssetPath: sourceKey,
                    sourceBookTitle: bookData.title,
                    sourceAuthor: bookData.author,
                    sectionId: sec.id,
                    sectionTitle: sec.title,
                    questionNumber: item.questionNumber,
                    itemIndex: itemIdx,
                    snippet: snippet,
                    citation: seg.citation!,
                  ),
                );
              }
            }
          }
        }

        if (item.type == 'qa') {
          if (item.question != null && item.question!.isNotEmpty) {
            processText(text: item.question!, fieldPrefix: 'Q. ');
          }
          if (item.answer != null && item.answer!.isNotEmpty) {
            processText(
              text: item.answer!,
              questionContext: item.question,
              fieldPrefix: 'A. ',
            );
          }
          if (item.explanation != null && item.explanation!.isNotEmpty) {
            processText(
              text: item.explanation!,
              questionContext: item.question,
            );
          }
          if (item.text != null && item.text!.isNotEmpty) {
            processText(text: item.text!, questionContext: item.question);
          }
        } else {
          if (item.text != null && item.text!.isNotEmpty) {
            processText(text: item.text!);
          }
          if (item.question != null && item.question!.isNotEmpty) {
            processText(text: item.question!);
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
