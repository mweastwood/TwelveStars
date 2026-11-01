import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/screens/saints_screen.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SaintDatabase.mockSaints = null;
    PrayerDatabase.mockPrayers = null;
    SaintDatabase.resetCache();
  });

  tearDown(() {
    SaintDatabase.mockSaints = null;
    PrayerDatabase.mockPrayers = null;
    SaintDatabase.resetCache();
  });

  group('Feast Day Parsing & DRY Month Table Tests', () {
    test('kMonthNames contains all 12 canonical English month names', () {
      expect(kMonthNames, [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ]);
    });

    test(
      'Saint.feastDates, hasFeastInMonth, and hasFeastOnDate parse single and multi-date feast strings',
      () {
        const multiSaint = Saint(
          id: 'mary-test',
          name: 'Blessed Virgin Mary',
          nationality: 'Jewish',
          profession: 'Mother of God',
          feastDay: 'January 1 / August 15 / December 8',
        );

        expect(multiSaint.feastDates, [
          (month: 1, day: 1),
          (month: 8, day: 15),
          (month: 12, day: 8),
        ]);
        expect(multiSaint.feastMonth, 1);
        expect(multiSaint.feastDayOfMonth, 1);

        expect(multiSaint.hasFeastInMonth(1), isTrue);
        expect(multiSaint.hasFeastInMonth(8), isTrue);
        expect(multiSaint.hasFeastInMonth(12), isTrue);
        expect(multiSaint.hasFeastInMonth(5), isFalse);

        expect(multiSaint.hasFeastOnDate(1, 1), isTrue);
        expect(multiSaint.hasFeastOnDate(8, 15), isTrue);
        expect(multiSaint.hasFeastOnDate(12, 8), isTrue);
        expect(multiSaint.hasFeastOnDate(8, 14), isFalse);

        // Also test fromJson precomputed feastDates
        final fromJsonSaint = Saint.fromJson({
          'id': 'joseph-test',
          'name': 'St. Joseph',
          'nationality': 'Jewish',
          'profession': 'Foster Father of Jesus',
          'feastDay': 'March 19, May 1; March 19',
        });

        expect(fromJsonSaint.feastDates, [
          (month: 3, day: 19),
          (month: 5, day: 1),
        ]);
        expect(fromJsonSaint.feastMonth, 3);
        expect(fromJsonSaint.feastDayOfMonth, 19);
        expect(fromJsonSaint.hasFeastInMonth(3), isTrue);
        expect(fromJsonSaint.hasFeastInMonth(5), isTrue);
        expect(fromJsonSaint.hasFeastOnDate(5, 1), isTrue);
      },
    );

    test(
      'searchSaints matches secondary feast months for St. Joseph, Mary, and St. John the Baptist',
      () async {
        final saints = await SaintDatabase.loadSaints();

        final maySaints = SaintDatabase.searchSaints(
          saints,
          feastMonth: 5,
          sortBy: SaintSortOption.feastDay,
        );
        expect(
          maySaints.any((s) => s.id == 'joseph'),
          isTrue,
          reason: 'St. Joseph (March 19 / May 1) should match May filter',
        );
        // Since St. Joseph the Worker is May 1, when sorting May saints by feastDay
        // he should appear among the May 1 saints at the very start of May.
        expect(maySaints.take(2).map((s) => s.id), contains('joseph'));

        final augustSaints = SaintDatabase.searchSaints(saints, feastMonth: 8);
        expect(
          augustSaints.any((s) => s.id == 'mary-mother-of-god'),
          isTrue,
          reason: 'Mary (Jan 1 / Aug 15 / Dec 8) should match August filter',
        );
        expect(
          augustSaints.any((s) => s.id == 'john-the-baptist'),
          isTrue,
          reason:
              'St. John the Baptist (June 24 / August 29) should match August filter',
        );

        final decemberSaints = SaintDatabase.searchSaints(
          saints,
          feastMonth: 12,
        );
        expect(
          decemberSaints.any((s) => s.id == 'mary-mother-of-god'),
          isTrue,
          reason: 'Mary (Jan 1 / Aug 15 / Dec 8) should match December filter',
        );
      },
    );

    test(
      'buildFeastDayMap and getSaintsForDate use Saint.feastDates for all feast days',
      () async {
        final saints = await SaintDatabase.loadSaints();
        final map = SaintDatabase.buildFeastDayMap(saints);

        expect(map['5_1']?.any((s) => s.id == 'joseph'), isTrue);
        expect(map['3_19']?.any((s) => s.id == 'joseph'), isTrue);
        expect(map['8_15']?.any((s) => s.id == 'mary-mother-of-god'), isTrue);
        expect(map['12_8']?.any((s) => s.id == 'mary-mother-of-god'), isTrue);
        expect(map['8_29']?.any((s) => s.id == 'john-the-baptist'), isTrue);

        // Uncached custom list path in getSaintsForDate
        final customList = [
          const Saint(
            id: 'custom-multi',
            name: 'St. Custom Multi',
            nationality: 'Roman',
            profession: 'Martyr',
            feastDay: 'February 10 & November 20',
          ),
        ];
        expect(
          SaintDatabase.getSaintsForDate(
            DateTime(2026, 11, 20),
            customList,
          ).map((s) => s.id),
          ['custom-multi'],
        );
        expect(
          SaintDatabase.getSaintsForDate(DateTime(2026, 11, 21), customList),
          isEmpty,
        );
      },
    );

    testWidgets(
      'SaintsScreen shows filter-appropriate empty-state message when non-query filter yields no results',
      (tester) async {
        SaintDatabase.mockSaints = const [
          Saint(
            id: 'thomas-aquinas',
            name: 'St. Thomas Aquinas',
            birthDate: '1225',
            deathDate: '1274',
            nationality: 'Italian',
            profession: 'Dominican Friar & Theologian',
            isDoctor: true,
            feastDay: 'January 28',
            gender: 'male',
          ),
        ];
        PrayerDatabase.mockPrayers = [
          Prayer.mock(
            id: 'sign_of_the_cross',
            defaultTitle: 'Sign of the Cross',
            hasAmen: true,
            translations: {
              PrayerLanguage.english: [
                PrayerTranslation.mock(
                  title: 'Sign of the Cross',
                  subtitle: 'Signum Crucis',
                  text: 'In the name of the Father...',
                ),
              ],
            },
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(child: const SaintsScreen()),
        );
        await tester.pumpAndSettle();

        // Tap Angels filter chip (no angels in mockSaints, search query is empty)
        final angelsChip = find.byKey(const Key('angels_filter_chip'));
        await tester.ensureVisible(angelsChip);
        await tester.pumpAndSettle();
        await tester.tap(angelsChip);
        await tester.pumpAndSettle();

        expect(find.text('No saints found'), findsOneWidget);
        expect(
          find.text('Try adjusting or clearing your active filters.'),
          findsOneWidget,
        );
      },
    );
  });
}
