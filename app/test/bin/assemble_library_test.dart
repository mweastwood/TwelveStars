import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../bin/assemble_library.dart' as assemble_library;

void main() {
  group('parseBaltimoreFile', () {
    test(
      'baltimore_1.json preserves Q. 173 answer and emits separate Q. 173a item',
      () {
        final file = File('assets/catechism/json/baltimore_1.json');
        expect(file.existsSync(), isTrue);
        final data =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final sections = data['sections'] as List<dynamic>;

        final q173Items = <Map<String, dynamic>>[];
        for (final sec in sections) {
          final content =
              (sec as Map<String, dynamic>)['content'] as List<dynamic>;
          for (final item in content) {
            final map = item as Map<String, dynamic>;
            if (map['type'] == 'qa' && map['questionNumber'] == 173) {
              q173Items.add(map);
            }
          }
        }

        expect(q173Items, hasLength(2));
        expect(
          q173Items[0]['question'],
          'To receive Confirmation worthily is it necessary to be in the state of grace?',
        );
        expect(
          q173Items[0]['answer'],
          'To receive Confirmation worthily it is necessary to be in the state of grace.',
        );
        expect(q173Items[0]['explanation'], isNull);

        expect(q173Items[1]['question'], 'What is a state of grace?');
        expect(
          q173Items[1]['answer'],
          'A state of grace is freedom from mortal sin.',
        );
      },
    );

    test(
      'baltimore_1.json (Q. 420) and baltimore_2.json (Q. 421) have null explanation and back-matter prayers as headings/text',
      () {
        for (final entry in [
          ('assets/catechism/json/baltimore_1.json', 420, 35),
          ('assets/catechism/json/baltimore_2.json', 421, 39),
        ]) {
          final file = File(entry.$1);
          expect(file.existsSync(), isTrue);
          final data =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          final sections = data['sections'] as List<dynamic>;
          expect(sections, hasLength(entry.$3));

          Map<String, dynamic>? finalQa;
          for (final sec in sections) {
            final content =
                (sec as Map<String, dynamic>)['content'] as List<dynamic>;
            for (final item in content) {
              final map = item as Map<String, dynamic>;
              if (map['type'] == 'qa' && map['questionNumber'] == entry.$2) {
                finalQa = map;
              }
            }
          }

          expect(
            finalQa,
            isNotNull,
            reason: 'Missing Q. ${entry.$2} in ${entry.$1}',
          );
          expect(finalQa!['explanation'], isNull);

          final lastSection = sections.last as Map<String, dynamic>;
          final lastContent = (lastSection['content'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          final headings = lastContent
              .where((item) => item['type'] == 'heading')
              .map((item) => item['text'] as String)
              .toList();
          expect(headings, contains('Morning Prayers'));
          expect(headings, contains('*The Sanctus'));
          expect(
            headings.where((h) => h.startsWith('(')),
            isEmpty,
            reason: 'Parenthetical author credits should not be headings',
          );
        }
      },
    );

    test(
      'baltimore_3.json emits uppercase headings in sec_1 and sec_2 instead of swallowing into explanations',
      () {
        final file = File('assets/catechism/json/baltimore_3.json');
        expect(file.existsSync(), isTrue);
        final data =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final sections = data['sections'] as List<dynamic>;

        final sec1 =
            sections.firstWhere(
                  (s) => (s as Map<String, dynamic>)['id'] == 'sec_1',
                )
                as Map<String, dynamic>;
        final sec2 =
            sections.firstWhere(
                  (s) => (s as Map<String, dynamic>)['id'] == 'sec_2',
                )
                as Map<String, dynamic>;

        final combinedContent = [
          ...(sec1['content'] as List<dynamic>),
          ...(sec2['content'] as List<dynamic>),
        ].cast<Map<String, dynamic>>();

        final headings = combinedContent
            .where((item) => item['type'] == 'heading')
            .map((item) => item['text'] as String)
            .toList();

        expect(headings, contains('The Angelical Salutation.'));
        expect(headings, contains("The Apostles' Creed."));

        final q26 = combinedContent.firstWhere(
          (item) => item['type'] == 'qa' && item['questionNumber'] == 26,
        );
        expect(q26['explanation'], isNull);

        final q48 = combinedContent.firstWhere(
          (item) => item['type'] == 'qa' && item['questionNumber'] == 48,
        );
        expect(q48['explanation'], isNull);
      },
    );

    test(
      'synthetic Baltimore input preserves leading {N} crossRefQNum and handles uppercase headings with subsequent text',
      () {
        final tempDir = Directory.systemTemp.createTempSync(
          'baltimore_parser_test_',
        );
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final inputFile = File(p.join(tempDir.path, 'synthetic_baltimore.txt'));
        inputFile.writeAsStringSync('''
LESSON FIRST
ON FAITH

{1} Q. 130. Who made the world?
A. God made the world.

173. Q. To receive Confirmation worthily is it necessary to be in the state of grace?
A. To receive Confirmation worthily it is necessary to be in the state of grace.

173a. Q. What is a state of grace?
A. A state of grace is freedom from mortal sin.

THE APOSTLES' CREED.

I believe in God, the Father Almighty, Creator of heaven and earth.
''');

        assemble_library.parseBaltimoreFile(
          inputFile.path,
          'synthetic_baltimore',
          'Synthetic Baltimore',
          'Test Subtitle',
          tempDir,
        );

        final outFile = File(p.join(tempDir.path, 'synthetic_baltimore.json'));
        expect(outFile.existsSync(), isTrue);

        final parsed =
            jsonDecode(outFile.readAsStringSync()) as Map<String, dynamic>;
        final sections = parsed['sections'] as List<dynamic>;
        expect(sections, hasLength(1));

        final content =
            ((sections.first as Map<String, dynamic>)['content']
                    as List<dynamic>)
                .cast<Map<String, dynamic>>();

        expect(content, hasLength(5));
        expect(content[0]['type'], 'qa');
        expect(content[0]['questionNumber'], 130);
        expect(content[0]['crossRefQNum'], 1);
        expect(content[0]['question'], 'Who made the world?');

        expect(content[1]['type'], 'qa');
        expect(content[1]['questionNumber'], 173);
        expect(
          content[1]['answer'],
          'To receive Confirmation worthily it is necessary to be in the state of grace.',
        );
        expect(content[1]['explanation'], isNull);

        expect(content[2]['type'], 'qa');
        expect(content[2]['questionNumber'], 173);
        expect(content[2]['question'], 'What is a state of grace?');
        expect(
          content[2]['answer'],
          'A state of grace is freedom from mortal sin.',
        );
        expect(content[2]['explanation'], isNull);

        expect(content[3]['type'], 'heading');
        expect(content[3]['text'], "The Apostles' Creed.");

        expect(content[4]['type'], 'text');
        expect(
          content[4]['text'],
          'I believe in God, the Father Almighty, Creator of heaven and earth.',
        );
      },
    );
  });
}
