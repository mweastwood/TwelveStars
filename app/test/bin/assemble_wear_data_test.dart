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
    test('includes all 4 mystery sets with 5 decades each', () {
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
      if (File('assets/prayers.json').existsSync()) {
        expect(prayers, contains('our_father'));
        expect(prayers, contains('hail_mary'));
        expect(prayers, contains('glory_be'));
      }
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
