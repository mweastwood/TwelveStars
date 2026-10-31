import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:twelve_stars/logic/prayers.dart';

import '../../bin/assemble_library.dart';
import '../../bin/verify_sources.dart';

void main() {
  group('verify_sources softNormalize word boundary handling', () {
    test(
      'preserves words containing role/amen substrings like sacrament, parish, elector',
      () {
        expect(
          softNormalize(
            'Blessed Sacrament of the New Testament in the parish elector amenability',
            language: PrayerLanguage.english,
          ),
          'blessedsacramentofthenewtestamentintheparishelectoramenability',
        );
      },
    );

    test(
      'strips standalone role labels and Amen across languages while keeping surrounding words intact',
      () {
        expect(
          softNormalize(
            'Priest: Most holy Sacrament. People: Amen.',
            language: PrayerLanguage.english,
          ),
          'mostholysacrament',
        );

        expect(
          softNormalize(
            'Reader: The elector of the parish. Deacon: Amen.',
            language: PrayerLanguage.english,
          ),
          'theelectoroftheparish',
        );

        expect(
          softNormalize(
            'Sacerdos: Tantum ergo Sacramentum. Populus: Lector: Diaconus: Amen.',
            language: PrayerLanguage.latin,
          ),
          'tantumergosacramentum',
        );

        expect(
          softNormalize(
            'Sacerdote: Asamblea: Pueblo: Diácono: Sacramento del altar. Amén.',
            language: PrayerLanguage.spanish,
          ),
          'sacramentodelaltar',
        );

        expect(
          softNormalize(
            'Pari: Namumuno: Bayan: Kabayanan at bayanihan. Amen.',
            language: PrayerLanguage.tagalog,
          ),
          'kabayananatbayanihan',
        );
      },
    );
  });

  group('assemble_library parseChapteredBookFile', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('assemble_library_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'preserves existing verseSystem on disk and includes un-subtitled chapters in toc',
      () {
        final inputTxt = File(p.join(tempDir.path, 'sample_book.txt'));
        inputTxt.writeAsStringSync('''
Chapter 1
1:1 First verse of an un-subtitled chapter.
A non-verse continuation line that must not become a subtitle.
1:2 Second verse of chapter 1.

Chapter 2
The Second Chapter Subtitle
2:1 First verse of a subtitled chapter.
''');

        final outDir = Directory(p.join(tempDir.path, 'out'));
        outDir.createSync(recursive: true);

        // Pre-seed an existing JSON with verseSystem = 'modern'
        final existingJsonFile = File(p.join(outDir.path, 'sample_book.json'));
        existingJsonFile.writeAsStringSync(
          jsonEncode({'bookId': 'sample_book', 'verseSystem': 'modern'}),
        );

        parseChapteredBookFile(
          filepath: inputTxt.path,
          bookId: 'sample_book',
          secIdPrefix: 'sample',
          title: 'Sample Book',
          subtitle: 'Sample Subtitle',
          author: 'Sample Author',
          outputDir: outDir,
        );

        final generated =
            jsonDecode(existingJsonFile.readAsStringSync())
                as Map<String, dynamic>;

        expect(generated['verseSystem'], equals('modern'));

        final toc = generated['toc'] as List<dynamic>;
        expect(toc, hasLength(2));
        expect(toc[0], {'id': 'sec_sample_1', 'title': 'Chapter 1'});
        expect(toc[1], {
          'id': 'sec_sample_2',
          'title': 'Chapter 2: The Second Chapter Subtitle',
        });

        final sections = generated['sections'] as List<dynamic>;
        expect(sections, hasLength(2));
        final sec1 = sections[0] as Map<String, dynamic>;
        expect(sec1['subtitle'], equals(''));
        final sec1Content = sec1['content'] as List<dynamic>;
        expect(sec1Content, hasLength(3));
        expect(
          sec1Content[0]['text'],
          '1. First verse of an un-subtitled chapter.',
        );
        expect(
          sec1Content[1]['text'],
          'A non-verse continuation line that must not become a subtitle.',
        );
        expect(sec1Content[2]['text'], '2. Second verse of chapter 1.');
      },
    );
  });
}
