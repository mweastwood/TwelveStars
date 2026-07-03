import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';

part 'bible_database.g.dart';

@DriftDatabase(include: {'bible.drift'})
class BibleDatabase extends _$BibleDatabase {
  BibleDatabase([QueryExecutor? executor])
    : super(executor ?? openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(favoritePassages);
      }
    },
  );

  // Retrieve verses for a specific chapter
  Future<List<BibleVerse>> getChapterVerses(
    String translation,
    int bookNum,
    int chapterNum,
  ) {
    return (select(bibleVerses)
          ..where(
            (t) =>
                t.translationCode.equals(translation) &
                t.bookNumber.equals(bookNum) &
                t.chapter.equals(chapterNum),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.verseNumber)]))
        .get();
  }

  // Populate a specific book if not already populated
  Future<void> ensureBookPopulated(
    int bookNumber,
    String bookName,
    String abbrev,
  ) async {
    final existingCheck =
        await (select(bibleVerses)
              ..where((t) => t.bookNumber.equals(bookNumber))
              ..limit(1))
            .get();
    if (existingCheck.isNotEmpty) {
      return; // Already populated
    }

    try {
      final numStr = bookNumber.toString().padLeft(2, '0');
      final assetPath =
          'assets/bible/cpdv/usfm/$numStr-$abbrev-ENG[B]CPDV2009[pd].p.sfm';
      final usfmContent = await rootBundle.loadString(assetPath);
      final parsedVerses = UsfmParser.parse(
        usfmContent,
        'CPDV',
        bookNumber,
        bookName,
      );

      await batch((batch) {
        batch.insertAll(
          bibleVerses,
          parsedVerses.map(
            (v) => BibleVersesCompanion.insert(
              bookNumber: v['bookNumber'] as int,
              bookName: v['bookName'] as String,
              chapter: v['chapter'] as int,
              verseNumber: v['verseNumber'] as int,
              verseText: v['verseText'] as String,
              translationCode: v['translationCode'] as String,
            ),
          ),
        );
      });
      debugPrint('Successfully populated Bible database with $bookName');
    } catch (e) {
      debugPrint('Error populating book $bookName ($bookNumber): $e');
    }
  }

  // Populate translation if empty (default to Genesis for compatibility)
  Future<void> ensurePopulated() async {
    await ensureBookPopulated(1, 'Genesis', 'GEN');
    await _ensureLectionaryPopulated();
  }

  // Retrieve readings for a specific liturgical day key
  Future<List<LectionaryReading>> getReadings(String key) async {
    await _ensureLectionaryPopulated();
    return (select(lectionaryReadings)
          ..where((t) => t.readingKey.equals(key))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
  }

  // Populate lectionary if empty
  Future<void> _ensureLectionaryPopulated() async {
    final countCheck = await (select(lectionaryReadings)..limit(1)).get();
    if (countCheck.isNotEmpty) {
      return; // Already populated
    }

    try {
      final jsonContent = await rootBundle.loadString(
        'assets/bible/lectionary.json',
      );
      final List<dynamic> decoded = jsonDecode(jsonContent);

      await batch((batch) {
        batch.insertAll(
          lectionaryReadings,
          decoded.map(
            (item) => LectionaryReadingsCompanion.insert(
              readingKey: item['reading_key'] as String,
              readingType: item['reading_type'] as String,
              bookNumber: item['book_number'] as int,
              bookName: item['book_name'] as String,
              chapter: item['chapter'] as int,
              verseRange: item['verse_range'] as String,
              citation: item['citation'] as String,
            ),
          ),
        );
      });
      debugPrint(
        'Successfully seeded lectionary database with ${decoded.length} entries',
      );
    } catch (e) {
      debugPrint('Error seeding lectionary database: $e');
    }
  }

  // Favorites operations
  Future<List<FavoritePassage>> getFavorites() {
    return select(favoritePassages).get();
  }

  Future<int> saveFavorite(FavoritePassagesCompanion companion) {
    return into(favoritePassages).insert(companion);
  }

  Future<int> deleteFavorite(int id) {
    return (delete(favoritePassages)..where((t) => t.id.equals(id))).go();
  }
}

// Simple USFM Parser
class UsfmParser {
  static List<Map<String, dynamic>> parse(
    String usfmContent,
    String translationCode,
    int bookNumber,
    String bookName,
  ) {
    final List<Map<String, dynamic>> verses = [];
    final lines = usfmContent.split('\n');
    int currentChapter = 0;

    final verseRegex = RegExp(r'^\\v\s+(\d+)\s+(.*)');

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith(r'\c ')) {
        final chapterStr = line.substring(3).trim();
        currentChapter = int.tryParse(chapterStr) ?? 0;
      } else if (line.startsWith(r'\v ')) {
        final match = verseRegex.firstMatch(line);
        if (match != null) {
          final verseNumber = int.parse(match.group(1)!);
          var text = match.group(2)!;

          // Strip inline formatting tags (like \nd ... \nd*, \add ... \add*)
          text = text.replaceAll(
            RegExp(r'\\f\s+.*\\f\*'),
            '',
          ); // strip footnotes
          text = text.replaceAll(
            RegExp(r'\\[a-zA-Z0-9]+(?:\*|\s)?'),
            '',
          ); // strip formatting
          text = text.trim();

          verses.add({
            'bookNumber': bookNumber,
            'bookName': bookName,
            'chapter': currentChapter,
            'verseNumber': verseNumber,
            'verseText': text,
            'translationCode': translationCode,
          });
        }
      }
    }
    return verses;
  }
}

class BibleDatabaseHelper {
  static BibleDatabase? _db;

  static BibleDatabase get db {
    _db ??= BibleDatabase();
    return _db!;
  }

  @visibleForTesting
  static set db(BibleDatabase database) {
    _db = database;
  }
}
