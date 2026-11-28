import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/lectionary_reverse_index.dart';
import 'package:twelve_stars/logic/liturgical_calendar_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LectionaryReverseIndex Tests', () {
    setUp(() {
      LectionaryReverseIndex.resetForTesting();
      LiturgicalCalendar.resetCache();
    });

    tearDown(() {
      LectionaryReverseIndex.resetForTesting();
      LiturgicalCalendar.resetCache();
    });

    test(
      'loads bundled lectionary.json and indexes only the first pickup verse of each reading',
      () async {
        expect(LectionaryReverseIndex.isLoaded, isFalse);
        await LectionaryReverseIndex.ensureLoaded();
        expect(LectionaryReverseIndex.isLoaded, isTrue);

        // Revelation 7:2-4, 9-14 (All Saints 1st Reading):
        // Should appear on v. 2 ONLY, not v. 3 or v. 9.
        final rev7v2 = LectionaryReverseIndex.getVerseOccurrences(76, 7, 2);
        expect(rev7v2.any((o) => o.readingKey == 'feast_all_saints'), isTrue);
        final rev7v3 = LectionaryReverseIndex.getVerseOccurrences(76, 7, 3);
        expect(rev7v3.any((o) => o.readingKey == 'feast_all_saints'), isFalse);
        final rev7v9 = LectionaryReverseIndex.getVerseOccurrences(76, 7, 9);
        expect(rev7v9.any((o) => o.readingKey == 'feast_all_saints'), isFalse);
      },
    );

    test(
      'maps Modern Psalm numbering (including chained-dash Psalm 85:9-10-11-12) to Vulgate chapters and verses',
      () async {
        await LectionaryReverseIndex.ensureLoaded();

        // All Saints Psalm is Modern Psalm 24:1bc-2 -> Vulgate Psalm 23, verse 1
        final vulgatePs23v1 = LectionaryReverseIndex.getVerseOccurrences(
          21,
          23,
          1,
        );
        expect(
          vulgatePs23v1.any(
            (o) =>
                o.readingKey == 'feast_all_saints' &&
                o.role == LectionaryReadingRole.psalm,
          ),
          isTrue,
        );

        // 2nd Sunday of Advent (Year B) Psalm is Modern Psalm 85:9-10-11-12, 13-14
        // -> Vulgate Psalm 84, verse 9 (not 13).
        final vulgatePs84v9 = LectionaryReverseIndex.getVerseOccurrences(
          21,
          84,
          9,
        );
        expect(
          vulgatePs84v9.any(
            (o) =>
                o.readingKey == 'season_advent_2_sunday_b' &&
                o.role == LectionaryReadingRole.psalm,
          ),
          isTrue,
        );
      },
    );

    test(
      'deduplicates identical Ordinary Time Weekday Year I & II readings and prefers fuller citation',
      () async {
        await LectionaryReverseIndex.ensureLoaded();

        // Matthew 5:27-32 is read on Friday of the 10th Week in Ordinary Time
        // in both Year I ("Matthew 5:27-32") and Year II ("Mt 5:27-32").
        final matt5v27 = LectionaryReverseIndex.getVerseOccurrences(49, 5, 27);
        final ot10Fri = matt5v27
            .where(
              (o) => o.readingKey.startsWith('season_ordinary_time_10_friday'),
            )
            .toList();
        expect(ot10Fri.length, 1);
        expect(ot10Fri.first.readingKeys.length, 2);
        expect(ot10Fri.first.title, contains('Years I & II'));
        expect(ot10Fri.first.citation, 'Matthew 5:27-32');
      },
    );

    test(
      'resolves Holy Family and St. Joseph to their distinct upcoming dates',
      () async {
        await LectionaryReverseIndex.ensureLoaded();

        final all = LectionaryReverseIndex.allIndexedOccurrencesForTesting;
        final holyFamily = all.firstWhere(
          (o) => o.readingKey == 'feast_holy_family',
        );
        final stJoseph = all.firstWhere(
          (o) => o.readingKey == 'feast_st_joseph',
        );

        // Mid-year reference date after March 19, 2026:
        // Holy Family -> Dec 27, 2026; St. Joseph -> Mar 19, 2027.
        final resolved = LectionaryReverseIndex.resolveOccurrencesWithDates([
          holyFamily,
          stJoseph,
        ], referenceDate: DateTime(2026, 6, 1));

        final resolvedHf = resolved.firstWhere(
          (r) => r.occurrence.readingKey == 'feast_holy_family',
        );
        final resolvedSj = resolved.firstWhere(
          (r) => r.occurrence.readingKey == 'feast_st_joseph',
        );

        expect(resolvedHf.nextDate, DateTime(2026, 12, 27));
        expect(resolvedSj.nextDate, DateTime(2027, 3, 19));
      },
    );

    test(
      'orders occurrences by liturgical rank first (Solemnity -> Sunday -> Weekday), then chronologically',
      () async {
        await LectionaryReverseIndex.ensureLoaded();

        final matt5v1 = LectionaryReverseIndex.getVerseOccurrences(49, 5, 1);
        expect(matt5v1.length, greaterThanOrEqualTo(3));

        final refDate = DateTime(2026, 1, 1);
        final resolved = LectionaryReverseIndex.resolveOccurrencesWithDates(
          matt5v1,
          referenceDate: refDate,
        );

        expect(resolved.length, matt5v1.length);

        for (int i = 1; i < resolved.length; i++) {
          final prev = resolved[i - 1];
          final curr = resolved[i];
          expect(
            prev.occurrence.rank.index,
            lessThanOrEqualTo(curr.occurrence.rank.index),
          );
          if (prev.occurrence.rank == curr.occurrence.rank &&
              prev.nextDate != null &&
              curr.nextDate != null) {
            expect(prev.nextDate!.isAfter(curr.nextDate!), isFalse);
          }
        }

        expect(
          resolved.first.occurrence.rank,
          LectionaryRank.solemnityOrTriduum,
        );
        expect(resolved.first.occurrence.readingKey, 'feast_all_saints');
        expect(resolved.first.nextDate, DateTime(2026, 11, 1));
      },
    );

    test(
      'every indexed occurrence in bundled lectionary.json is recognized, excludes orphan keys, and resolves to a matching LiturgicalCalendar date',
      () async {
        await LectionaryReverseIndex.ensureLoaded();

        final all = LectionaryReverseIndex.allIndexedOccurrencesForTesting;
        expect(all, isNotEmpty);

        const orphanKeys = {
          'season_easter_1_sunday_a',
          'season_easter_1_sunday_b',
          'season_easter_1_sunday_c',
          'season_ordinary_time_1_sunday_a',
          'season_ordinary_time_1_sunday_b',
        };

        for (final occ in all) {
          for (final key in occ.readingKeys) {
            expect(
              orphanKeys.contains(key),
              isFalse,
              reason: 'Orphan key $key must not be indexed',
            );
            expect(
              LectionaryReverseIndex.isRecognizedKey(key),
              isTrue,
              reason: 'Key $key fell through to fallback parser',
            );
          }
        }

        // Deduplicate by primary readingKey to verify every distinct liturgical
        // occasion resolves a matching upcoming date (including rare dates via
        // the lazy extended scan).
        final byKey = <String, LectionaryOccurrence>{};
        for (final occ in all) {
          byKey.putIfAbsent(occ.readingKey, () => occ);
        }

        final resolvedAll = LectionaryReverseIndex.resolveOccurrencesWithDates(
          byKey.values.toList(),
          referenceDate: DateTime(2026, 1, 1),
        );

        for (final item in resolvedAll) {
          expect(
            item.nextDate,
            isNotNull,
            reason:
                'Expected upcoming date for ${item.occurrence.readingKeys} (${item.occurrence.title})',
          );
          final litDay = LiturgicalCalendar.computeDay(item.nextDate!);
          expect(
            item.occurrence.readingKeys.contains(litDay.lectionaryKey),
            isTrue,
            reason:
                'Date ${item.nextDate} resolved key ${litDay.lectionaryKey}, expected one of ${item.occurrence.readingKeys}',
          );
        }
      },
    );

    test(
      'parses special liturgical colors and Christmas Octave Feast ranks accurately',
      () {
        LectionaryReverseIndex.loadFromJsonString('''
[
  {
    "reading_key": "season_advent_3_sunday_a",
    "reading_type": "gospel",
    "book_number": 49,
    "book_name": "Matthew",
    "chapter": 11,
    "verse_range": "2-11",
    "citation": "Matthew 11:2-11"
  },
  {
    "reading_key": "season_lent_4_sunday_b",
    "reading_type": "gospel",
    "book_number": 52,
    "book_name": "John",
    "chapter": 3,
    "verse_range": "14-21",
    "citation": "John 3:14-21"
  },
  {
    "reading_key": "season_easter_8_sunday_a",
    "reading_type": "gospel",
    "book_number": 52,
    "book_name": "John",
    "chapter": 20,
    "verse_range": "19-23",
    "citation": "John 20:19-23"
  },
  {
    "reading_key": "season_christmas_12_26",
    "reading_type": "gospel",
    "book_number": 49,
    "book_name": "Matthew",
    "chapter": 10,
    "verse_range": "17-22",
    "citation": "Matthew 10:17-22"
  }
]
''');

        final gaudete = LectionaryReverseIndex.getVerseOccurrences(
          49,
          11,
          2,
        ).single;
        expect(gaudete.liturgicalColor, LiturgicalColor.rose);
        expect(gaudete.rank, LectionaryRank.sunday);
        expect(gaudete.title, '3rd Sunday of Advent (Year A)');

        final laetare = LectionaryReverseIndex.getVerseOccurrences(
          52,
          3,
          14,
        ).single;
        expect(laetare.liturgicalColor, LiturgicalColor.rose);
        expect(laetare.rank, LectionaryRank.sunday);

        final pentecost = LectionaryReverseIndex.getVerseOccurrences(
          52,
          20,
          19,
        ).single;
        expect(pentecost.liturgicalColor, LiturgicalColor.red);
        expect(pentecost.rank, LectionaryRank.solemnityOrTriduum);
        expect(pentecost.title, 'Pentecost Sunday (Year A)');

        final stStephen = LectionaryReverseIndex.getVerseOccurrences(
          49,
          10,
          17,
        ).single;
        expect(stStephen.liturgicalColor, LiturgicalColor.red);
        expect(stStephen.rank, LectionaryRank.solemnityOrTriduum);
      },
    );

    test(
      'load generation guard prevents stale ensureLoaded from overwriting setEmptyForTesting',
      () async {
        final loadFuture = LectionaryReverseIndex.ensureLoaded();
        LectionaryReverseIndex.setEmptyForTesting();
        await loadFuture;

        expect(LectionaryReverseIndex.isLoaded, isTrue);
        expect(LectionaryReverseIndex.allIndexedOccurrencesForTesting, isEmpty);
      },
    );
  });
}
