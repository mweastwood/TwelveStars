import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

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
      expect(prayersJson.isNotEmpty, isTrue);
      final ids = prayersJson.map((p) => p['id'] as String).toList();
      // Verify a core set of fundamental prayers is always present
      expect(ids, contains('our_father'));
      expect(ids, contains('hail_mary'));
      expect(ids, contains('glory_be'));
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
          if (prayerId == 'now_i_lay_me' &&
              (lang == 'latin' || lang == 'spanish' || lang == 'vietnamese')) {
            continue;
          }
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
            expect(
              sourceUrl.startsWith('https://') ||
                  sourceUrl.startsWith('http://'),
              isTrue,
            );
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

    test('tokens are aligned across all translations of each prayer', () {
      for (final p in prayersJson) {
        final pMap = p as Map<String, dynamic>;
        final prayerId = pMap['id'] as String;
        final transMap = pMap['translations'] as Map<String, dynamic>;

        final Map<String, List<String>> translationTokenIds = {};

        for (final entry in transMap.entries) {
          final lang = entry.key;
          final transList = entry.value as List<dynamic>;

          for (
            int versionIndex = 0;
            versionIndex < transList.length;
            versionIndex++
          ) {
            final tMap = transList[versionIndex] as Map<String, dynamic>;
            final tokensList = tMap['tokens'] as List<dynamic>?;
            if (tokensList != null) {
              final tokenIds = tokensList
                  .map((tok) => tok['id'] as String?)
                  .where((id) => id != null)
                  .map((id) => id!)
                  .toList();
              if (tokenIds.isNotEmpty) {
                translationTokenIds['${lang}_v${versionIndex + 1}'] = tokenIds;
              }
            }
          }
        }

        if (translationTokenIds.length > 1) {
          final entries = translationTokenIds.entries.toList();
          final firstEntry = entries.first;
          final firstTokenIds = firstEntry.value;

          for (int i = 1; i < entries.length; i++) {
            final otherEntry = entries[i];
            final otherTokenIds = otherEntry.value;

            expect(
              otherTokenIds,
              equals(firstTokenIds),
              reason:
                  'Token alignment mismatch in prayer "$prayerId": '
                  '${firstEntry.key} has tokens $firstTokenIds, but '
                  '${otherEntry.key} has tokens $otherTokenIds',
            );
          }
        }
      }
    });

    test(
      'raw markdown files in each prayer directory have consistent metadata',
      () {
        final dir = Directory('assets/prayers');
        expect(dir.existsSync(), isTrue);

        final folders = dir.listSync().whereType<Directory>().toList();
        for (final folder in folders) {
          final prayerId = folder.path.split(Platform.pathSeparator).last;
          final mdFiles = folder
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.md'))
              .toList();

          if (mdFiles.isEmpty) continue;

          String? expectedCategory;
          int? expectedDefaultOrder;
          String? expectedDefaultTitle;
          String? expectedCategorySource;
          String? expectedDefaultOrderSource;
          String? expectedDefaultTitleSource;

          for (final file in mdFiles) {
            final filename = file.path.split(Platform.pathSeparator).last;
            final content = file.readAsStringSync();
            final normalizedContent = content.replaceAll('\r\n', '\n');
            final parts = normalizedContent.split('---\n');
            expect(
              parts.length,
              greaterThanOrEqualTo(3),
              reason: 'Invalid markdown structure in ${file.path}',
            );

            final yamlMap = loadYaml(parts[1]) as YamlMap;
            final category = yamlMap['category'] as String?;
            final defaultOrder = yamlMap['default_order'] as int?;
            final defaultTitle = yamlMap['default_title'] as String?;

            if (expectedCategory == null) {
              expectedCategory = category;
              expectedCategorySource = filename;
            } else {
              expect(
                category,
                equals(expectedCategory),
                reason:
                    'Inconsistent category for "$prayerId": '
                    '$expectedCategorySource has "$expectedCategory" but '
                    '$filename has "$category"',
              );
            }

            if (expectedDefaultOrder == null) {
              expectedDefaultOrder = defaultOrder;
              expectedDefaultOrderSource = filename;
            } else {
              expect(
                defaultOrder,
                equals(expectedDefaultOrder),
                reason:
                    'Inconsistent default_order for "$prayerId": '
                    '$expectedDefaultOrderSource has "$expectedDefaultOrder" but '
                    '$filename has "$defaultOrder"',
              );
            }

            if (expectedDefaultTitle == null) {
              expectedDefaultTitle = defaultTitle;
              expectedDefaultTitleSource = filename;
            } else {
              expect(
                defaultTitle,
                equals(expectedDefaultTitle),
                reason:
                    'Inconsistent default_title for "$prayerId": '
                    '$expectedDefaultTitleSource has "$expectedDefaultTitle" but '
                    '$filename has "$defaultTitle"',
              );
            }
          }
        }
      },
    );

    test('default_order is unique across all prayers', () {
      final dir = Directory('assets/prayers');
      expect(dir.existsSync(), isTrue);

      final folders = dir.listSync().whereType<Directory>().toList();
      final Map<int, String> orderToPrayerId = {};

      for (final folder in folders) {
        final prayerId = folder.path.split(Platform.pathSeparator).last;
        final mdFiles = folder
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))
            .toList();

        if (mdFiles.isEmpty) continue;

        final firstFile = mdFiles.first;
        final content = firstFile.readAsStringSync();
        final normalizedContent = content.replaceAll('\r\n', '\n');
        final parts = normalizedContent.split('---\n');
        final yamlMap = loadYaml(parts[1]) as YamlMap;
        final defaultOrder = yamlMap['default_order'] as int?;

        if (defaultOrder != null) {
          expect(
            orderToPrayerId.containsKey(defaultOrder),
            isFalse,
            reason:
                'Duplicate default_order "$defaultOrder" found between '
                '"${orderToPrayerId[defaultOrder]}" and "$prayerId"',
          );
          orderToPrayerId[defaultOrder] = prayerId;
        }
      }
    });

    test(
      'consistent handling of punctuation and whitespace within phrase keys',
      () {
        for (final p in prayersJson) {
          final pMap = p as Map<String, dynamic>;
          final prayerId = pMap['id'] as String;
          final transMap = pMap['translations'] as Map<String, dynamic>;

          for (final entry in transMap.entries) {
            final lang = entry.key;
            final transList = entry.value as List<dynamic>;

            for (
              int versionIndex = 0;
              versionIndex < transList.length;
              versionIndex++
            ) {
              final tMap = transList[versionIndex] as Map<String, dynamic>;
              final tokensList = tMap['tokens'] as List<dynamic>?;
              if (tokensList == null) continue;

              for (final token in tokensList) {
                final id = token['id'] as String?;
                if (id == null) continue; // Skip non-phrase tokens

                final text = token['text'] as String;

                // 1. Must not start or end with whitespace
                expect(
                  text.trim(),
                  equals(text),
                  reason:
                      'Phrase "$text" (id: $id) in prayer "$prayerId" ($lang, version ${versionIndex + 1}) has leading or trailing whitespace.',
                );

                // 2. Must not start with punctuation
                final startsWithPunct = RegExp(
                  r'^[.,;:!?，。；：！？«»‘’“”"()]',
                ).hasMatch(text);
                expect(
                  startsWithPunct,
                  isFalse,
                  reason:
                      'Phrase "$text" (id: $id) in prayer "$prayerId" ($lang, version ${versionIndex + 1}) starts with punctuation.',
                );
              }
            }
          }
        }
      },
    );

    test('every prayer has at least one phrase', () {
      for (final p in prayersJson) {
        final pMap = p as Map<String, dynamic>;
        final prayerId = pMap['id'] as String;
        final transMap = pMap['translations'] as Map<String, dynamic>;

        for (final entry in transMap.entries) {
          final lang = entry.key;
          final transList = entry.value as List<dynamic>;

          for (
            int versionIndex = 0;
            versionIndex < transList.length;
            versionIndex++
          ) {
            final tMap = transList[versionIndex] as Map<String, dynamic>;
            final tokensList = tMap['tokens'] as List<dynamic>?;

            expect(
              tokensList,
              isNotNull,
              reason:
                  'Tokens list is null in prayer "$prayerId" ($lang, version ${versionIndex + 1})',
            );

            final hasPhrase = tokensList!.any((tok) => tok['id'] != null);
            expect(
              hasPhrase,
              isTrue,
              reason:
                  'Prayer "$prayerId" ($lang, version ${versionIndex + 1}) has no phrase keys.',
            );
          }
        }
      }
    });
  });
}
