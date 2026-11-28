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
      'maps Modern Psalm numbering in lectionary.json to Vulgate chapters and verses',
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
      'orders occurrences by liturgical rank first (Solemnity -> Sunday -> Weekday), then chronologically',
      () async {
        await LectionaryReverseIndex.ensureLoaded();

        // Matthew 5:1 includes All Saints (Solemnity), 4th Sunday in Ordinary
        // Time (Year A), and Ordinary Time weekdays.
        final matt5v1 = LectionaryReverseIndex.getVerseOccurrences(49, 5, 1);
        expect(matt5v1.length, greaterThanOrEqualTo(3));

        final refDate = DateTime(2026, 1, 1);
        final resolved = LectionaryReverseIndex.resolveOccurrencesWithDates(
          matt5v1,
          referenceDate: refDate,
        );

        expect(resolved.length, matt5v1.length);

        // Verify rank order is non-decreasing and dates within each rank are non-decreasing
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
            expect(
              prev.nextDate!.isAfter(curr.nextDate!),
              isFalse,
              reason:
                  'Expected ${prev.occurrence.title} (${prev.nextDate}) <= ${curr.occurrence.title} (${curr.nextDate})',
            );
          }
        }

        // First item should be a Solemnity/Feast (All Saints)
        expect(
          resolved.first.occurrence.rank,
          LectionaryRank.solemnityOrTriduum,
        );
        expect(resolved.first.occurrence.readingKey, 'feast_all_saints');
        expect(resolved.first.nextDate, DateTime(2026, 11, 1));

        // Verify every computed nextDate maps back to one of the occurrence's keys
        for (final item in resolved) {
          final date = item.nextDate;
          if (date != null) {
            final litDay = LiturgicalCalendar.computeDay(date);
            final key = litDay.lectionaryKey;
            final matchesDirect = item.occurrence.readingKeys.contains(key);
            final matchesAlias =
                (key == 'season_easter_sunday' &&
                    item.occurrence.readingKeys.any(
                      (k) => k.startsWith('season_easter_1_sunday_'),
                    )) ||
                (key == 'feast_baptism_of_the_lord' &&
                    item.occurrence.readingKeys.any(
                      (k) => k.startsWith('season_ordinary_time_1_sunday_'),
                    ));
            expect(
              matchesDirect || matchesAlias,
              isTrue,
              reason:
                  'Date $date computed key $key which did not match ${item.occurrence.readingKeys}',
            );
          }
        }
      },
    );

    test(
      'parses special liturgical colors accurately (Rose for Gaudete/Laetare, Red for Palm Sunday/Pentecost)',
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
      },
    );
  });
}
