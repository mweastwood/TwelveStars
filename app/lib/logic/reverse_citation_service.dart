import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/library_database.dart';

class ReverseCitation {
  final String sourceBookId;
  final String sourceBookTitle;
  final String sectionId;
  final String sectionTitle;
  final int? questionNumber;
  final String snippet;
  final BibleCitation citation;

  const ReverseCitation({
    required this.sourceBookId,
    required this.sourceBookTitle,
    required this.sectionId,
    required this.sectionTitle,
    this.questionNumber,
    required this.snippet,
    required this.citation,
  });
}

class ReverseCitationService {
  static final List<ReverseCitation> _index = [];
  static bool _indexed = false;

  static Future<void> ensureIndexed() async {
    if (_indexed) return;
    _indexed = true;

    final catalogPaths = [
      'assets/catechism/json/baltimore_1.json',
      'assets/catechism/json/baltimore_2.json',
      'assets/catechism/json/baltimore_3.json',
      'assets/catechism/json/baltimore_4.json',
      'assets/catechism/json/council_of_trent.json',
    ];

    for (final path in catalogPaths) {
      try {
        final rawJson = await rootBundle.loadString(path);
        final bookData = ParsedBookData.fromJson(
          jsonDecode(rawJson) as Map<String, dynamic>,
        );
        _indexBookData(bookData);
      } catch (_) {}
    }
  }

  static void _indexBookData(ParsedBookData bookData) {
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
            _index.add(
              ReverseCitation(
                sourceBookId: bookData.bookId,
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
  }

  static List<ReverseCitation> getChapterCitations(
    int bookNumber,
    int chapter,
  ) {
    return _index.where((rc) {
      final c = rc.citation;
      return c.bookNumber == bookNumber &&
          c.chapter == chapter &&
          c.isEntireChapter;
    }).toList();
  }

  static List<ReverseCitation> getVerseCitations(
    int bookNumber,
    int chapter,
    int verseNumber,
  ) {
    return _index.where((rc) {
      final c = rc.citation;
      if (c.bookNumber != bookNumber ||
          c.chapter != chapter ||
          c.isEntireChapter) {
        return false;
      }
      final start = c.verse!;
      final end = c.endVerse ?? start;
      return verseNumber >= start && verseNumber <= end;
    }).toList();
  }
}
