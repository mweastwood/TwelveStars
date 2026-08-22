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
    'assets/catechism/json/athanasius_life_of_anthony.json',
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
    'assets/catechism/json/ambrose_on_the_mysteries.json',
    'assets/catechism/json/ambrose_on_the_sacraments.json',
    'assets/catechism/json/aquinas_compendium_of_theology_part1.json',
    'assets/catechism/json/aquinas_compendium_of_theology_part2.json',
    'assets/catechism/json/aquinas_catechetical_creed.json',
    'assets/catechism/json/aquinas_catechetical_sacraments.json',
    'assets/catechism/json/aquinas_catechetical_commandments.json',
    'assets/catechism/json/aquinas_catechetical_prayer.json',
    'assets/catechism/json/aquinas_catechetical_hail_mary.json',
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
    'assets/catechism/json/sales_love_of_god_vol1.json',
    'assets/catechism/json/sales_love_of_god_vol2.json',
    'assets/catechism/json/sales_love_of_god_vol3.json',
    'assets/catechism/json/sales_love_of_god_vol4.json',
    'assets/catechism/json/teresa_interior_castle.json',
    'assets/catechism/json/teresa_way_perfection_part1.json',
    'assets/catechism/json/teresa_way_perfection_part2.json',
    'assets/catechism/json/kempis_imitation_of_christ.json',
    'assets/catechism/json/bonaventure_minds_road_to_god.json',
    'assets/catechism/json/basil_on_the_holy_spirit.json',
    'assets/catechism/json/chrysostom_on_the_priesthood_book1.json',
    'assets/catechism/json/chrysostom_on_the_priesthood_book2.json',
    'assets/catechism/json/chrysostom_on_the_priesthood_book3.json',
    'assets/catechism/json/chrysostom_on_the_priesthood_book4.json',
    'assets/catechism/json/chrysostom_on_the_priesthood_book5.json',
    'assets/catechism/json/chrysostom_on_the_priesthood_book6.json',
    'assets/catechism/json/vincent_commonitory.json',
    'assets/catechism/json/leo_tome_and_letters.json',
    'assets/catechism/json/leo_selected_sermons.json',
    'assets/catechism/json/cyprian_unity_and_lapsed.json',
    'assets/catechism/json/cyprian_prayer_and_treatises.json',
    'assets/catechism/json/damascene_orthodox_faith_book1.json',
    'assets/catechism/json/damascene_orthodox_faith_book2.json',
    'assets/catechism/json/damascene_orthodox_faith_book3.json',
    'assets/catechism/json/damascene_orthodox_faith_book4.json',
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
