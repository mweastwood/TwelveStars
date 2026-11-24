import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../bin/assemble_wear_data.dart' as wear_gen;

void main() {
  group('buildLiturgicalCalendarPayload', () {
    test('generates all days including leap day for leap year', () {
      final payload = wear_gen.buildLiturgicalCalendarPayload(
        startYear: 2024,
        endYear: 2024,
      );

      expect(payload['schemaVersion'], 1);
      expect(payload['startYear'], 2024);
      expect(payload['endYear'], 2024);

      final days = payload['days'] as Map<String, Map<String, dynamic>>;
      expect(days.length, 366);
      expect(days.containsKey('2024-02-29'), isTrue);
    });

    test('computes accurate liturgical metadata and rosary mystery', () {
      final payload = wear_gen.buildLiturgicalCalendarPayload(
        startYear: 2026,
        endYear: 2026,
      );
      final days = payload['days'] as Map<String, Map<String, dynamic>>;

      final christmas = days['2026-12-25']!;
      expect(christmas['season'], 'christmas');
      expect(christmas['color'], 'white');
      expect(christmas['name'], isNotNull);
      expect(christmas['rosaryMystery'], 'sorrowful'); // Friday

      final easter = days['2026-04-05']!;
      expect(easter['season'], 'easter');
      expect(easter['color'], 'white');
      expect(easter['rosaryMystery'], 'glorious'); // Sunday
    });

    test('throws ArgumentError when endYear < startYear', () {
      expect(
        () => wear_gen.buildLiturgicalCalendarPayload(
          startYear: 2027,
          endYear: 2026,
        ),
        throwsArgumentError,
      );
    });
  });

  group('buildRosaryPayload', () {
    const expectedPrayerIds = [
      'sign_of_the_cross',
      'apostles_creed',
      'our_father',
      'hail_mary',
      'glory_be',
      'fatima_prayer',
      'hail_holy_queen',
      'final_prayer_rosary',
    ];

    test('includes all 4 mystery sets and all 8 rosary prayers', () {
      final payload = wear_gen.buildRosaryPayload();
      expect(payload['schemaVersion'], 1);

      final mysteries =
          payload['mysteries'] as Map<String, Map<String, dynamic>>;
      expect(
        mysteries.keys,
        containsAll(['joyful', 'sorrowful', 'glorious', 'luminous']),
      );
      for (final entry in mysteries.values) {
        final decades = entry['decades'] as List;
        expect(decades.length, 5);
      }

      final prayers = payload['prayers'] as Map<String, Map<String, dynamic>>;
      expect(prayers.keys, containsAll(expectedPrayerIds));
      expect(prayers.length, expectedPrayerIds.length);
    });

    test(
      'extracts english and latin translations, defaultTitle, and hasAmen',
      () {
        final tempDir = Directory.systemTemp.createTempSync('wear_prayers_ok_');
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final fixture = File(p.join(tempDir.path, 'prayers.json'));
        final items = [
          for (final id in expectedPrayerIds)
            {
              'id': id,
              'default_title': 'Title $id',
              'has_amen': id != 'fatima_prayer',
              'translations': {
                'english': [
                  {'title': 'EN $id', 'text': 'English text for $id'},
                ],
                'latin': [
                  {'title': 'LA $id', 'text': 'Latin text for $id'},
                ],
                'french': [
                  {'title': 'FR $id', 'text': 'French text for $id'},
                ],
              },
            },
        ];
        fixture.writeAsStringSync(jsonEncode(items));

        final payload = wear_gen.buildRosaryPayload(prayersJsonFile: fixture);
        final prayers = payload['prayers'] as Map<String, Map<String, dynamic>>;
        expect(prayers.keys, containsAll(expectedPrayerIds));

        final closing = prayers['final_prayer_rosary']!;
        expect(closing['id'], 'final_prayer_rosary');
        expect(closing['defaultTitle'], 'Title final_prayer_rosary');
        expect(closing['hasAmen'], isTrue);

        final translations =
            closing['translations'] as Map<String, Map<String, String>>;
        expect(translations.keys, unorderedEquals(['english', 'latin']));
        expect(translations['english'], {
          'title': 'EN final_prayer_rosary',
          'text': 'English text for final_prayer_rosary',
        });
        expect(translations['latin'], {
          'title': 'LA final_prayer_rosary',
          'text': 'Latin text for final_prayer_rosary',
        });

        final fatima = prayers['fatima_prayer']!;
        expect(fatima['hasAmen'], isFalse);
      },
    );

    test('throws FileSystemException when prayers.json is missing', () {
      final missing = File(
        p.join(Directory.systemTemp.path, 'nonexistent_prayers_12345.json'),
      );
      expect(
        () => wear_gen.buildRosaryPayload(prayersJsonFile: missing),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('throws FormatException when prayers.json is malformed JSON', () {
      final tempDir = Directory.systemTemp.createTempSync('wear_prayers_bad_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      final badSyntax = File(p.join(tempDir.path, 'bad_syntax.json'))
        ..writeAsStringSync('{not valid json');
      expect(
        () => wear_gen.buildRosaryPayload(prayersJsonFile: badSyntax),
        throwsFormatException,
      );

      final notAList = File(p.join(tempDir.path, 'not_a_list.json'))
        ..writeAsStringSync('{"id": "our_father"}');
      expect(
        () => wear_gen.buildRosaryPayload(prayersJsonFile: notAList),
        throwsFormatException,
      );
    });

    test('throws StateError when a required prayer ID is missing', () {
      final tempDir = Directory.systemTemp.createTempSync('wear_prayers_miss_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      final incomplete = File(p.join(tempDir.path, 'incomplete.json'));
      final items = [
        for (final id in expectedPrayerIds.where(
          (id) => id != 'final_prayer_rosary',
        ))
          {
            'id': id,
            'default_title': 'Title $id',
            'has_amen': true,
            'translations': {},
          },
      ];
      incomplete.writeAsStringSync(jsonEncode(items));

      expect(
        () => wear_gen.buildRosaryPayload(prayersJsonFile: incomplete),
        throwsStateError,
      );
    });
  });

  group('CLI execution', () {
    test('writes liturgical_calendar.json and rosary_data.json to outDir', () {
      final tempDir = Directory.systemTemp.createTempSync('wear_data_test_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      wear_gen.main([
        '--start-year=2026',
        '--end-year=2026',
        '--out-dir=${tempDir.path}',
      ]);

      final calFile = File(p.join(tempDir.path, 'liturgical_calendar.json'));
      final rosaryFile = File(p.join(tempDir.path, 'rosary_data.json'));
      expect(calFile.existsSync(), isTrue);
      expect(rosaryFile.existsSync(), isTrue);

      final calJson =
          jsonDecode(calFile.readAsStringSync()) as Map<String, dynamic>;
      expect((calJson['days'] as Map).length, 365);

      final rosaryJson =
          jsonDecode(rosaryFile.readAsStringSync()) as Map<String, dynamic>;
      expect((rosaryJson['mysteries'] as Map).length, 4);
    });
  });
}
