import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  // Override sqlite3 FFI loading on Linux
  open.overrideFor(OperatingSystem.linux, () {
    try {
      return DynamicLibrary.open('libsqlite3.so.0');
    } catch (_) {
      return DynamicLibrary.open('libsqlite3.so');
    }
  });

  group('Prayers Compiled SQLite Database', () {
    late Database db;

    setUpAll(() {
      final dbFile = File('assets/prayers.db');
      expect(
        dbFile.existsSync(),
        isTrue,
        reason: 'assets/prayers.db must exist. Run bin/assemble_db.dart first.',
      );
      db = sqlite3.open(dbFile.path);
    });

    tearDownAll(() {
      db.dispose();
    });

    test('contains exactly three starter prayers', () {
      final rows = db.select(
        'SELECT id FROM prayers ORDER BY default_order ASC',
      );
      expect(rows.length, 3);
      expect(rows[0]['id'], 'our_father');
      expect(rows[1]['id'], 'hail_mary');
      expect(rows[2]['id'], 'glory_be');
    });

    test('each prayer has translations for all target languages', () {
      final prayers = db.select('SELECT id FROM prayers');
      final expectedLanguages = [
        'english',
        'spanish',
        'french',
        'italian',
        'latin',
        'vietnamese',
        'tagalog',
        'traditionalChinese',
      ];

      for (final p in prayers) {
        final prayerId = p['id'] as String;
        final tRows = db.select(
          'SELECT DISTINCT language FROM translations WHERE prayer_id = ?',
          [prayerId],
        );
        final languages = tRows.map((r) => r['language'] as String).toList();
        for (final expected in expectedLanguages) {
          expect(
            languages.contains(expected),
            isTrue,
            reason: 'Prayer $prayerId is missing translation for $expected',
          );
        }
      }
    });

    test('translations contain valid data and sources', () {
      final rows = db.select('SELECT * FROM translations');
      expect(rows.isNotEmpty, isTrue);
      for (final r in rows) {
        final title = r['title'] as String;
        final text = r['text'] as String;
        final sourceName = r['source_name'] as String;
        final sourceUrl = r['source_url'] as String;

        expect(title.isNotEmpty, isTrue);
        expect(text.isNotEmpty, isTrue);
        expect(sourceName.isNotEmpty, isTrue);
        expect(sourceUrl.startsWith('https://'), isTrue);
      }
    });

    test('traditionalChinese translations contain valid pinyin lines', () {
      final rows = db.select(
        'SELECT * FROM translations WHERE language = "traditionalChinese"',
      );
      expect(rows.isNotEmpty, isTrue);
      for (final r in rows) {
        final chineseLinesJson = r['chinese_lines'] as String?;
        expect(chineseLinesJson, isNotNull);
        final List<dynamic> lines = jsonDecode(chineseLinesJson!);
        expect(lines.isNotEmpty, isTrue);
        for (final line in lines) {
          final List<dynamic> charList = line;
          expect(charList.isNotEmpty, isTrue);
          for (final charItem in charList) {
            final map = charItem as Map<String, dynamic>;
            expect(map['char']?.isNotEmpty ?? false, isTrue);
          }
        }
      }
    });
  });
}
