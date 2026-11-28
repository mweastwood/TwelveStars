import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';
import 'package:twelve_stars/logic/lectionary_responses.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/psalm_response_service.dart';
import 'package:twelve_stars/widgets/reader/mass_psalm_widgets.dart';

void main() {
  group('resolvePsalmStanzas', () {
    test(
      'preserves comma-separated stanza boundaries with Vulgate mapping',
      () {
        // Modern Psalm 95:1-2, 3-5, 6-7ab -> Vulgate Psalm 94
        final stanzas = resolvePsalmStanzas(
          bookNumber: 21,
          defaultChapter: 95,
          defaultVerseRange: '1-2, 3-5, 6-7ab',
          citation: 'Psalm 95:1-2, 3-5, 6-7ab',
        );
        expect(stanzas, [
          [
            const ChapterVerseRange(chapter: 94, verses: [1, 2]),
          ],
          [
            const ChapterVerseRange(chapter: 94, verses: [3, 4, 5]),
          ],
          [
            const ChapterVerseRange(chapter: 94, verses: [6, 7]),
          ],
        ]);
      },
    );

    test('repeats shared boundary half-verses in both adjacent stanzas', () {
      // Modern Psalm 23:1-3a, 3b-4, 5, 6 -> Vulgate Psalm 22
      final stanzas = resolvePsalmStanzas(
        bookNumber: 21,
        defaultChapter: 23,
        defaultVerseRange: '1-3a, 3b-4, 5, 6',
        citation: 'Psalm 23:1-3a, 3b-4, 5, 6',
      );
      expect(stanzas, [
        [
          const ChapterVerseRange(chapter: 22, verses: [1, 2, 3]),
        ],
        [
          const ChapterVerseRange(chapter: 22, verses: [3, 4]),
        ],
        [
          const ChapterVerseRange(chapter: 22, verses: [5]),
        ],
        [
          const ChapterVerseRange(chapter: 22, verses: [6]),
        ],
      ]);
    });

    test(
      'keeps conjunctions (and / &) within the same stanza in liturgical order',
      () {
        // Modern Psalm 136:1 and 23-24, 10-12, 13-15 -> Vulgate Psalm 135
        final stanzas = resolvePsalmStanzas(
          bookNumber: 21,
          defaultChapter: 136,
          defaultVerseRange: '1 and 23-24, 10-12, 13-15',
          citation: 'Psalm 136:1 and 23-24, 10-12, 13-15',
        );
        expect(stanzas, [
          [
            const ChapterVerseRange(chapter: 135, verses: [1, 23, 24]),
          ],
          [
            const ChapterVerseRange(chapter: 135, verses: [10, 11, 12]),
          ],
          [
            const ChapterVerseRange(chapter: 135, verses: [13, 14, 15]),
          ],
        ]);

        final ampersandStanzas = resolvePsalmStanzas(
          bookNumber: 21,
          defaultChapter: 1,
          defaultVerseRange: '1-2, 3, 4 & 6',
          citation: 'Psalm 1:1-2, 3, 4 & 6',
        );
        expect(ampersandStanzas, [
          [
            const ChapterVerseRange(chapter: 1, verses: [1, 2]),
          ],
          [
            const ChapterVerseRange(chapter: 1, verses: [3]),
          ],
          [
            const ChapterVerseRange(chapter: 1, verses: [4, 6]),
          ],
        ]);
      },
    );

    test('handles semicolon cross-chapter Psalm 42/43 citations', () {
      final stanzas = resolvePsalmStanzas(
        bookNumber: 21,
        defaultChapter: 42,
        defaultVerseRange: '2-3; 43',
        citation: 'Psalm 42:2-3; 43:3, 4',
      );
      expect(stanzas, [
        [
          const ChapterVerseRange(chapter: 41, verses: [2, 3]),
        ],
        [
          const ChapterVerseRange(chapter: 42, verses: [3]),
        ],
        [
          const ChapterVerseRange(chapter: 42, verses: [4]),
        ],
      ]);
    });

    test('handles chained dashes and split Vulgate psalms', () {
      final chained = resolvePsalmStanzas(
        bookNumber: 21,
        defaultChapter: 85,
        defaultVerseRange: '9-10-11-12, 13-14',
        citation: 'Psalm 85:9-10-11-12, 13-14',
      );
      expect(chained, [
        [
          const ChapterVerseRange(chapter: 84, verses: [9, 10, 11, 12]),
        ],
        [
          const ChapterVerseRange(chapter: 84, verses: [13, 14]),
        ],
      ]);

      // Modern Psalm 116:12-13, 15-16, 17-18 -> Vulgate Psalm 115:3-4, 6-7, 8-9
      final split = resolvePsalmStanzas(
        bookNumber: 21,
        defaultChapter: 116,
        defaultVerseRange: '12-13, 15-16, 17-18',
        citation: 'Psalm 116:12-13, 15-16, 17-18',
      );
      expect(split, [
        [
          const ChapterVerseRange(chapter: 115, verses: [3, 4]),
        ],
        [
          const ChapterVerseRange(chapter: 115, verses: [6, 7]),
        ],
        [
          const ChapterVerseRange(chapter: 115, verses: [8, 9]),
        ],
      ]);
    });

    test('deduplicates repeated verse numbers within a single stanza', () {
      final stanzas = resolvePsalmStanzas(
        bookNumber: 21,
        defaultChapter: 13,
        defaultVerseRange: '6ab and 6c',
        citation: 'Psalm 13:6ab and 6c',
      );
      expect(stanzas, [
        [
          const ChapterVerseRange(chapter: 12, verses: [6]),
        ],
      ]);
    });
  });

  group('lectionary.json psalm dataset integrity', () {
    late List<dynamic> lectionaryData;
    late Map<String, PsalmResponseSpec> parsedResponses;

    setUpAll(() {
      final file = File('assets/bible/lectionary.json');
      expect(file.existsSync(), isTrue);
      lectionaryData = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      parsedResponses = PsalmResponseService.parseEntriesFromJson(
        lectionaryData,
      );
    });

    test('all 697 psalm entries have valid stanzas and response specs', () {
      final psalms = lectionaryData
          .whereType<Map<String, dynamic>>()
          .where((e) => (e['reading_type'] as String?) == 'psalm')
          .toList();
      expect(psalms.length, 697);

      for (final psalm in psalms) {
        final key = psalm['reading_key'] as String;
        final bookNumber = psalm['book_number'] as int;
        final chapter = psalm['chapter'] as int;
        final verseRange = psalm['verse_range'] as String;
        final citation = psalm['citation'] as String;

        final stanzas = resolvePsalmStanzas(
          bookNumber: bookNumber,
          defaultChapter: chapter,
          defaultVerseRange: verseRange,
          citation: citation,
        );
        expect(stanzas, isNotEmpty, reason: 'No stanzas resolved for $key');

        final spec = parsedResponses[key];
        expect(spec, isNotNull, reason: 'Missing response spec for $key');
        expect(spec!.hasRefrain, isTrue, reason: 'Empty refrain for $key');

        if (!spec.isAlleluia) {
          final ranges = spec.resolveVulgateRanges(
            defaultBookNumber: bookNumber,
            defaultChapter: chapter,
          );
          expect(
            ranges,
            isNotEmpty,
            reason: 'Response ref failed to resolve for $key',
          );
        }
      }
    });

    test('spot-checks canonical liturgical refrains', () {
      // Sat 34th Week OT II: Ps 95:1-2, 3-5, 6-7ab -> R. v. 8 (Vulgate 94:8)
      final ps95 = parsedResponses['season_ordinary_time_34_saturday_2']!;
      expect(ps95.verseRef, '8');
      expect(
        ps95.resolveVulgateRanges(defaultBookNumber: 21, defaultChapter: 95),
        [
          const ChapterVerseRange(chapter: 94, verses: [8]),
        ],
      );

      // Holy Thursday: Ps 116 -> R. 1 Cor 10:16
      final holyThursday = parsedResponses['triduum_holy_thursday']!;
      expect(holyThursday.bookNumber, 55);
      expect(holyThursday.chapter, 10);
      expect(holyThursday.verseRef, '16');

      // Advent 1 Mon: Ps 19 -> R. John 6:68 (Vulgate John 6:69)
      final advent1Mon = parsedResponses['season_advent_1_monday']!;
      expect(advent1Mon.bookNumber, 52);
      expect(advent1Mon.chapter, 6);
      expect(
        advent1Mon.resolveVulgateRanges(
          defaultBookNumber: 21,
          defaultChapter: 19,
        ),
        [
          const ChapterVerseRange(chapter: 6, verses: [69]),
        ],
      );

      // Easter Vigil: Ps 118 -> pure Alleluia
      final easterVigil = parsedResponses['triduum_holy_saturday']!;
      expect(easterVigil.isAlleluia, isTrue);

      // Easter Sunday: Ps 118 -> R. v. 24 + or: Alleluia
      final easterSunday = parsedResponses['season_easter_sunday']!;
      expect(easterSunday.verseRef, '24');
      expect(easterSunday.allowAlleluia, isTrue);

      // Corrected weekday refs: Sat 24th Week OT II (Ps 56:14) & Thu 13th Week OT II (Ps 19:10)
      expect(
        parsedResponses['season_ordinary_time_24_saturday_2']!.verseRef,
        '14',
      );
      expect(
        parsedResponses['season_ordinary_time_13_thursday_2']!.verseRef,
        '10',
      );
    });
  });

  group('PsalmResponseService lifecycle and concurrency', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      PsalmResponseService.clear();
    });

    tearDown(() {
      PsalmResponseService.clear();
    });

    test(
      'ensureLoaded loads bundled lectionary.json and caches immutably',
      () async {
        expect(PsalmResponseService.isLoaded, isFalse);
        expect(
          PsalmResponseService.getForReadingKey(
            'season_ordinary_time_34_saturday_2',
          ),
          isNull,
        );

        await PsalmResponseService.ensureLoaded();
        expect(PsalmResponseService.isLoaded, isTrue);
        final spec = PsalmResponseService.getForReadingKey(
          'season_ordinary_time_34_saturday_2',
        );
        expect(spec, isNotNull);
        expect(spec!.verseRef, '8');

        // Calling ensureLoaded again returns immediately with cached data
        await PsalmResponseService.ensureLoaded();
        expect(
          PsalmResponseService.getForReadingKey(
            'season_ordinary_time_34_saturday_2',
          ),
          equals(spec),
        );
      },
    );

    test(
      'deduplicates concurrent ensureLoaded calls in the same Zone',
      () async {
        final f1 = PsalmResponseService.ensureLoaded();
        final f2 = PsalmResponseService.ensureLoaded();
        expect(identical(f1, f2), isTrue);
        await Future.wait([f1, f2]);
        expect(PsalmResponseService.isLoaded, isTrue);
      },
    );

    test(
      'load generation guard prevents stale ensureLoaded from overwriting setEmptyForTesting or clear',
      () async {
        final inFlight = PsalmResponseService.ensureLoaded();
        PsalmResponseService.setEmptyForTesting();
        await inFlight;
        expect(PsalmResponseService.isLoaded, isTrue);
        expect(
          PsalmResponseService.getForReadingKey(
            'season_ordinary_time_34_saturday_2',
          ),
          isNull,
        );

        PsalmResponseService.clear();
        final inFlight2 = PsalmResponseService.ensureLoaded();
        PsalmResponseService.clear();
        await inFlight2;
        expect(PsalmResponseService.isLoaded, isFalse);
      },
    );
  });

  group('resolvePsalmStanzas dash-crossing fallback', () {
    test('delegates dash-crossing multi-chapter citations cleanly', () {
      final stanzas = resolvePsalmStanzas(
        bookNumber: 21,
        defaultChapter: 42,
        defaultVerseRange: '2-43:4',
        citation: 'Psalm 42:2-43:4',
      );
      expect(stanzas, hasLength(1));
      expect(stanzas.first.first.chapter, 41);
      expect(stanzas.first.first.startVerseLimit, 2);
      expect(stanzas.first.last.chapter, 42);
      expect(stanzas.first.last.endVerseLimit, 4);
    });
  });

  group('formatCompactRefrainPreview & LectionaryResponses helpers', () {
    test('keeps short refrains intact and truncates long refrains cleanly', () {
      expect(
        formatCompactRefrainPreview(
          'If today you hear his voice, harden not your hearts:',
        ),
        'If today you hear his voice, harden not your hearts:',
      );
      expect(
        formatCompactRefrainPreview(
          'The Lord is compassionate and merciful, patient and full of mercy to all who call upon him.',
          maxChars: 42,
        ),
        'The Lord is compassionate and merciful…',
      );
    });

    test(
      'returns localized Alleluia and or labels for all PrayerLanguages',
      () {
        for (final lang in PrayerLanguage.values) {
          expect(LectionaryResponses.getAlleluia(lang), isNotEmpty);
          expect(LectionaryResponses.getOrLabel(lang), isNotEmpty);
        }
        expect(
          LectionaryResponses.getAlleluia(PrayerLanguage.english),
          'Alleluia.',
        );
        expect(
          LectionaryResponses.getAlleluia(PrayerLanguage.latin),
          'Allelúia.',
        );
        expect(LectionaryResponses.getOrLabel(PrayerLanguage.latin), 'vel');
        expect(
          LectionaryResponses.getAlleluia(PrayerLanguage.spanish),
          'Aleluya.',
        );
      },
    );
  });
}
