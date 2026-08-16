import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TocEntry {
  final String id;
  final String title;

  TocEntry({required this.id, required this.title});

  factory TocEntry.fromJson(Map<String, dynamic> json) {
    return TocEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }
}

class ContentItem {
  final String type; // 'qa', 'text', or 'heading'
  final int? questionNumber;
  final int? crossRefQNum;
  final String? question;
  final String? answer;
  final String? explanation;
  final String? text;

  ContentItem({
    required this.type,
    this.questionNumber,
    this.crossRefQNum,
    this.question,
    this.answer,
    this.explanation,
    this.text,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      type: json['type'] as String? ?? 'text',
      questionNumber: json['questionNumber'] as int?,
      crossRefQNum: json['crossRefQNum'] as int?,
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      explanation: json['explanation'] as String?,
      text: json['text'] as String?,
    );
  }
}

class BookSection {
  final String id;
  final String title;
  final String subtitle;
  final List<ContentItem> content;

  BookSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  factory BookSection.fromJson(Map<String, dynamic> json) {
    final rawList = json['content'] as List<dynamic>? ?? [];
    return BookSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      content: rawList
          .map((c) => ContentItem.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ParsedBookData {
  final String bookId;
  final String title;
  final String subtitle;
  final String author;
  final String verseSystem;
  final List<TocEntry> toc;
  final List<BookSection> sections;

  ParsedBookData({
    required this.bookId,
    required this.title,
    required this.subtitle,
    required this.author,
    this.verseSystem = 'vulgate',
    required this.toc,
    required this.sections,
  });

  factory ParsedBookData.fromJson(Map<String, dynamic> json) {
    final rawToc = json['toc'] as List<dynamic>? ?? [];
    final rawSec = json['sections'] as List<dynamic>? ?? [];
    return ParsedBookData(
      bookId: json['bookId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      author: json['author'] as String? ?? '',
      verseSystem: json['verseSystem'] as String? ?? 'vulgate',
      toc: rawToc
          .map((t) => TocEntry.fromJson(t as Map<String, dynamic>))
          .toList(),
      sections: rawSec
          .map((s) => BookSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BaltimoreVolume {
  final String volumeKey;
  final String name;
  final String shortName;
  final String description;
  final String assetPath;

  const BaltimoreVolume({
    required this.volumeKey,
    required this.name,
    required this.shortName,
    required this.description,
    required this.assetPath,
  });
}

class LibraryBookItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String author;
  final String description;
  final String? defaultAssetPath;
  final List<BaltimoreVolume>? volumes;
  final String verseSystem;

  const LibraryBookItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.author,
    required this.description,
    this.defaultAssetPath,
    this.volumes,
    this.verseSystem = 'vulgate',
  });

  bool get isSeries => volumes != null && volumes!.isNotEmpty;
}

class BookSearchResult {
  final String bookTitle;
  final String sectionId;
  final String sectionTitle;
  final String matchedSnippet;

  BookSearchResult({
    required this.bookTitle,
    required this.sectionId,
    required this.sectionTitle,
    required this.matchedSnippet,
  });
}

class LibraryHelper {
  static const int maxCacheSize = 5;
  static final Map<String, ParsedBookData> _cache = {};

  @visibleForTesting
  static int get cacheSize => _cache.length;

  @visibleForTesting
  static void clearCache() => _cache.clear();

  static const List<BaltimoreVolume> baltimoreVolumes = [
    BaltimoreVolume(
      volumeKey: 'no1',
      name: 'No. 1 (First Communion)',
      shortName: 'No. 1',
      description: 'Abridged version for First Communion classes (33 Lessons).',
      assetPath: 'assets/catechism/json/baltimore_1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'no2',
      name: 'No. 2 (Confirmation & Grammar)',
      shortName: 'No. 2',
      description:
          'Standard edition for Confirmation and grammar grades (37 Lessons).',
      assetPath: 'assets/catechism/json/baltimore_2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'no3',
      name: 'No. 3 (Post-Confirmation Course)',
      shortName: 'No. 3',
      description:
          'Comprehensive 2-year post-confirmation study course (37 Lessons, 1400+ Q&As).',
      assetPath: 'assets/catechism/json/baltimore_3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'no4',
      name: 'No. 4 (Explanation by Fr. Kinkead)',
      shortName: 'No. 4',
      description:
          'Complete explanation with commentary and pastoral guidance by Rev. Thomas L. Kinkead.',
      assetPath: 'assets/catechism/json/baltimore_4.json',
    ),
  ];

  static List<LibraryBookItem> getCatalog() {
    return [
      const LibraryBookItem(
        id: 'baltimore_catechism',
        title: 'Baltimore Catechism',
        subtitle: 'Third Plenary Council of Baltimore (1885)',
        category: 'Catechisms',
        author: 'Third Plenary Council of Baltimore / Rev. Thomas L. Kinkead',
        description:
            'The official national Catholic catechism of the United States from 1885 to the late 20th century. Features 4 progressive editions for all age levels.',
        volumes: baltimoreVolumes,
      ),
      const LibraryBookItem(
        id: 'council_of_trent',
        title: 'Catechism of the Council of Trent',
        subtitle: 'The Roman Catechism (St. Pius V, 1566)',
        category: 'Catechisms',
        author:
            'Council of Trent / Commission of St. Pius V (Trans. Rev. J. Donovan)',
        description:
            'Promulgated by Pope St. Pius V in 1566. The authoritative Roman Catechism expounding Catholic doctrine, sacraments, commandments, and prayer.',
        defaultAssetPath: 'assets/catechism/json/council_of_trent.json',
      ),
      const LibraryBookItem(
        id: 'didache_lightfoot',
        title: 'The Didache',
        subtitle:
            'The Teaching of the Twelve Apostles (Trans. J. B. Lightfoot, 1891)',
        category: 'Apostolic Fathers',
        author: 'The Apostolic Fathers (Trans. J. B. Lightfoot)',
        description:
            'The earliest surviving non-canonical Christian treatise (c. 1st century), presenting the doctrine of the Two Ways, early liturgical rites for Baptism and the Eucharist, and instructions on church order.',
        defaultAssetPath: 'assets/catechism/json/didache_lightfoot.json',
      ),
    ];
  }

  static Future<ParsedBookData> loadBookData(String assetPath) async {
    if (_cache.containsKey(assetPath)) {
      final cached = _cache.remove(assetPath)!;
      _cache[assetPath] = cached;
      return cached;
    }
    final rawString = await rootBundle.loadString(assetPath);
    final map = json.decode(rawString) as Map<String, dynamic>;
    final parsed = ParsedBookData.fromJson(map);
    if (_cache.length >= maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[assetPath] = parsed;
    return parsed;
  }

  static List<BookSearchResult> searchInBook(
    ParsedBookData book,
    String query,
  ) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];
    final words = cleanQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return [];

    final results = <BookSearchResult>[];

    for (final sec in book.sections) {
      for (final item in sec.content) {
        String fullText = '';
        if (item.type == 'qa') {
          fullText =
              'Q. ${item.questionNumber} ${item.question ?? ""} A. ${item.answer ?? ""}';
        } else {
          fullText = item.text ?? '';
        }

        final lowerText = fullText.toLowerCase();
        final matches = words.every((w) => lowerText.contains(w));
        if (matches) {
          int matchIdx = lowerText.indexOf(words.first);
          int start = (matchIdx - 30).clamp(0, fullText.length);
          int end = (matchIdx + 120).clamp(0, fullText.length);
          String snippet = fullText.substring(start, end).replaceAll('\n', ' ');
          if (start > 0) snippet = '...$snippet';
          if (end < fullText.length) snippet = '$snippet...';

          results.add(
            BookSearchResult(
              bookTitle: book.title,
              sectionId: sec.id,
              sectionTitle: sec.title,
              matchedSnippet: snippet,
            ),
          );
          if (results.length >= 50) break;
        }
      }
      if (results.length >= 50) break;
    }

    return results;
  }
}
