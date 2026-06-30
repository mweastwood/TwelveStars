import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Prayers Compiled JSON Database', () {
    late List<dynamic> prayersJson;

    setUpAll(() {
      final jsonFile = File('assets/prayers.json');
      expect(
        jsonFile.existsSync(),
        isTrue,
        reason:
            'assets/prayers.json must exist. Run bin/assemble_db.dart first.',
      );
      prayersJson = jsonDecode(jsonFile.readAsStringSync()) as List<dynamic>;
    });

    test('contains correct prayers', () {
      expect(prayersJson.length, 9);
      final ids = prayersJson.map((p) => p['id'] as String).toList();
      expect(ids, contains('our_father'));
      expect(ids, contains('hail_mary'));
      expect(ids, contains('glory_be'));
      expect(ids, contains('act_of_contrition'));
      expect(ids, contains('nicene_creed'));
      expect(ids, contains('apostles_creed'));
      expect(ids, contains('fatima_prayer'));
      expect(ids, contains('hail_holy_queen'));
      expect(ids, contains('anima_christi'));
    });

    test('each prayer has required translations', () {
      final expectedLanguagesForStarter = [
        'english',
        'spanish',
        'french',
        'italian',
        'latin',
        'vietnamese',
        'tagalog',
        'traditionalChinese',
      ];
      final expectedLanguagesForOthers = ['english', 'spanish', 'latin'];

      for (final p in prayersJson) {
        final pMap = p as Map<String, dynamic>;
        final prayerId = pMap['id'] as String;
        final category = pMap['category'] as String? ?? 'starter';
        final transMap = pMap['translations'] as Map<String, dynamic>;
        final languages = transMap.keys.toList();

        final expected = category == 'starter'
            ? expectedLanguagesForStarter
            : expectedLanguagesForOthers;

        for (final lang in expected) {
          expect(
            languages.contains(lang),
            isTrue,
            reason: 'Prayer $prayerId is missing translation for $lang',
          );
        }
      }
    });

    test('translations contain valid data and sources', () {
      for (final p in prayersJson) {
        final pMap = p as Map<String, dynamic>;
        final transMap = pMap['translations'] as Map<String, dynamic>;

        for (final entry in transMap.entries) {
          final transList = entry.value as List<dynamic>;
          for (final t in transList) {
            final tMap = t as Map<String, dynamic>;
            final title = tMap['title'] as String;
            final text = tMap['text'] as String;
            final sourceName = tMap['source_name'] as String;
            final sourceUrl = tMap['source_url'] as String;

            expect(title.isNotEmpty, isTrue);
            expect(text.isNotEmpty, isTrue);
            expect(sourceName.isNotEmpty, isTrue);
            expect(sourceUrl.startsWith('https://'), isTrue);
          }
        }
      }
    });

    test('traditionalChinese translations contain valid pinyin lines', () {
      for (final p in prayersJson) {
        final pMap = p as Map<String, dynamic>;
        final transMap = pMap['translations'] as Map<String, dynamic>;

        if (transMap.containsKey('traditionalChinese')) {
          final transList = transMap['traditionalChinese'] as List<dynamic>;
          for (final t in transList) {
            final tMap = t as Map<String, dynamic>;
            final lines = tMap['chinese_lines'] as List<dynamic>?;
            expect(lines, isNotNull);
            expect(lines!.isNotEmpty, isTrue);

            for (final line in lines) {
              final List<dynamic> charList = line;
              expect(charList.isNotEmpty, isTrue);
              for (final charItem in charList) {
                final map = charItem as Map<String, dynamic>;
                expect(map['char']?.isNotEmpty ?? false, isTrue);
              }
            }
          }
        }
      }
    });
  });
}
