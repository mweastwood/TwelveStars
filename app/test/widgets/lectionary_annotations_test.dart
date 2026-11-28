import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/lectionary_reverse_index.dart';
import 'package:twelve_stars/logic/liturgical_calendar_core.dart';
import 'package:twelve_stars/routing/app_router.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';
import 'package:twelve_stars/widgets/reader/reader_annotation_chip.dart';
import '../test_helper.dart';

void main() {
  group('Lectionary Chip & Modal Widget Tests', () {
    setUp(() {
      LectionaryReverseIndex.resetForTesting();
      LiturgicalCalendar.resetCache();
    });

    tearDown(() {
      LectionaryReverseIndex.resetForTesting();
      LiturgicalCalendar.resetCache();
    });

    testWidgets(
      'ReaderAnnotationChip.lectionary renders church icon and count and handles tap',
      (tester) async {
        int tapCount = 0;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: ReaderAnnotationChip.lectionary(
                key: const Key('lectionary_chip'),
                count: 3,
                onTap: () => tapCount++,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.church_rounded), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        await tester.tap(find.byKey(const Key('lectionary_chip')));
        await tester.pump();
        expect(tapCount, 1);
      },
    );

    testWidgets(
      'BibleVerseRow renders lectionary chip alongside other badges and fires onTapLectionary',
      (tester) async {
        bool tappedLectionary = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: BibleVerseRow(
                verseNumber: 1,
                verseText:
                    'And seeing the multitudes, he went up into a mountain.',
                lectionaryCount: 2,
                citationsCount: 4,
                commentsCount: 1,
                isFavorite: true,
                onTapLectionary: () => tappedLectionary = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.church_rounded), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.church_rounded));
        await tester.pump();
        expect(tappedLectionary, isTrue);
      },
    );

    testWidgets(
      'showLectionaryReadingsModal displays rank-ordered cards and invokes onOpenMissalDate',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const occurrences = [
          LectionaryOccurrence(
            readingKey: 'season_ordinary_time_10_monday_1',
            readingKeys: [
              'season_ordinary_time_10_monday_1',
              'season_ordinary_time_10_monday_2',
            ],
            title: 'Monday of the 10th Week in Ordinary Time (Years I & II)',
            role: LectionaryReadingRole.gospel,
            rank: LectionaryRank.weekday,
            liturgicalColor: LiturgicalColor.green,
            bookNumber: 49,
            bookName: 'Matthew',
            startChapter: 5,
            startVerse: 1,
            citation: 'Matthew 5:1-12',
            verseRange: '1-12',
          ),
          LectionaryOccurrence(
            readingKey: 'season_ordinary_time_4_sunday_a',
            readingKeys: ['season_ordinary_time_4_sunday_a'],
            title: '4th Sunday in Ordinary Time (Year A)',
            role: LectionaryReadingRole.gospel,
            rank: LectionaryRank.sunday,
            liturgicalColor: LiturgicalColor.green,
            bookNumber: 49,
            bookName: 'Matthew',
            startChapter: 5,
            startVerse: 1,
            citation: 'Matthew 5:1-12a',
            verseRange: '1-12a',
          ),
          LectionaryOccurrence(
            readingKey: 'feast_all_saints',
            readingKeys: ['feast_all_saints'],
            title: 'All Saints',
            role: LectionaryReadingRole.gospel,
            rank: LectionaryRank.solemnityOrTriduum,
            liturgicalColor: LiturgicalColor.white,
            bookNumber: 49,
            bookName: 'Matthew',
            startChapter: 5,
            startVerse: 1,
            citation: 'Matthew 5:1-12a',
            verseRange: '1-12a',
          ),
        ];

        DateTime? openedDate;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showLectionaryReadingsModal(
                    context: context,
                    title: 'Matthew 5:1',
                    occurrences: occurrences,
                    referenceDate: DateTime(2026, 1, 1),
                    onOpenMissalDate: (d) => openedDate = d,
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Mass Readings from Matthew 5:1'), findsOneWidget);
        expect(find.text('All Saints'), findsOneWidget);
        expect(
          find.text('4th Sunday in Ordinary Time (Year A)'),
          findsOneWidget,
        );
        expect(
          find.text('Monday of the 10th Week in Ordinary Time (Years I & II)'),
          findsOneWidget,
        );

        // Verify visual vertical order: Solemnity -> Sunday -> Weekday
        final allSaintsTop = tester.getTopLeft(find.text('All Saints')).dy;
        final sundayTop = tester
            .getTopLeft(find.text('4th Sunday in Ordinary Time (Year A)'))
            .dy;
        final weekdayTop = tester
            .getTopLeft(
              find.text(
                'Monday of the 10th Week in Ordinary Time (Years I & II)',
              ),
            )
            .dy;
        expect(allSaintsTop, lessThan(sundayTop));
        expect(sundayTop, lessThan(weekdayTop));

        // Tap Open in Missal on All Saints card
        await tester.tap(
          find.byKey(const Key('open_missal_feast_all_saints_gospel')),
        );
        await tester.pumpAndSettle();

        expect(openedDate, DateTime(2026, 11, 1));
        expect(find.text('Mass Readings from Matthew 5:1'), findsNothing);
      },
    );

    testWidgets(
      'showLectionaryReadingsModal renders cleanly at 360px with 1.5x text scale, dark mode, Read today, and null nextDate',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const occurrences = [
          LectionaryOccurrence(
            readingKey: 'feast_all_saints',
            readingKeys: ['feast_all_saints'],
            title: 'All Saints',
            role: LectionaryReadingRole.gospel,
            rank: LectionaryRank.solemnityOrTriduum,
            liturgicalColor: LiturgicalColor.white,
            bookNumber: 49,
            bookName: 'Matthew',
            startChapter: 5,
            startVerse: 1,
            citation: 'Matthew 5:1-12a',
            verseRange: '1-12a',
          ),
          LectionaryOccurrence(
            readingKey: 'custom_unscheduled_key',
            readingKeys: ['custom_unscheduled_key'],
            title: 'Unscheduled Custom Feast',
            role: LectionaryReadingRole.first,
            rank: LectionaryRank.weekday,
            liturgicalColor: LiturgicalColor.purple,
            bookNumber: 49,
            bookName: 'Matthew',
            startChapter: 5,
            startVerse: 1,
            citation: 'Matthew 5:1-12',
            verseRange: '1-12',
          ),
        ];

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: MaterialApp(
              theme: ThemeData.dark(useMaterial3: true),
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showLectionaryReadingsModal(
                      context: context,
                      title: 'Matthew 5:1',
                      occurrences: occurrences,
                      referenceDate: DateTime(2026, 11, 1),
                    ),
                    child: const Text('Open Dark Modal'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dark Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Read today (Sun, Nov 1, 2026)'), findsOneWidget);
        expect(find.text('Unscheduled Custom Feast'), findsOneWidget);
        // Only the scheduled occurrence has an Open in Missal button.
        expect(find.text('Open in Missal'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Open in Missal navigates through GoRouter to /missal?date=YYYY-MM-DD',
      (tester) async {
        String? navigatedUri;
        const occurrences = [
          LectionaryOccurrence(
            readingKey: 'feast_all_saints',
            readingKeys: ['feast_all_saints'],
            title: 'All Saints',
            role: LectionaryReadingRole.gospel,
            rank: LectionaryRank.solemnityOrTriduum,
            liturgicalColor: LiturgicalColor.white,
            bookNumber: 49,
            bookName: 'Matthew',
            startChapter: 5,
            startVerse: 1,
            citation: 'Matthew 5:1-12a',
            verseRange: '1-12a',
          ),
        ];

        final router = GoRouter(
          initialLocation: AppRoutes.bible,
          routes: [
            GoRoute(
              path: AppRoutes.bible,
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showLectionaryReadingsModal(
                    context: context,
                    title: 'Matthew 5:1',
                    occurrences: occurrences,
                    referenceDate: DateTime(2026, 1, 1),
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.missal,
              builder: (context, state) {
                navigatedUri = state.uri.toString();
                return Scaffold(body: Text('Missal: ${state.uri}'));
              },
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('open_missal_feast_all_saints_gospel')),
        );
        await tester.pumpAndSettle();

        expect(navigatedUri, '/missal?date=2026-11-01');
        expect(find.text('Missal: /missal?date=2026-11-01'), findsOneWidget);
      },
    );

    testGoldens('renders Lectionary Readings modal cleanly for Matthew 5:1', (
      tester,
    ) async {
      const occurrences = [
        LectionaryOccurrence(
          readingKey: 'feast_all_saints',
          readingKeys: ['feast_all_saints'],
          title: 'All Saints',
          role: LectionaryReadingRole.gospel,
          rank: LectionaryRank.solemnityOrTriduum,
          liturgicalColor: LiturgicalColor.white,
          bookNumber: 49,
          bookName: 'Matthew',
          startChapter: 5,
          startVerse: 1,
          citation: 'Matthew 5:1-12a',
          verseRange: '1-12a',
        ),
        LectionaryOccurrence(
          readingKey: 'season_ordinary_time_4_sunday_a',
          readingKeys: ['season_ordinary_time_4_sunday_a'],
          title: '4th Sunday in Ordinary Time (Year A)',
          role: LectionaryReadingRole.gospel,
          rank: LectionaryRank.sunday,
          liturgicalColor: LiturgicalColor.green,
          bookNumber: 49,
          bookName: 'Matthew',
          startChapter: 5,
          startVerse: 1,
          citation: 'Matthew 5:1-12a',
          verseRange: '1-12a',
        ),
        LectionaryOccurrence(
          readingKey: 'season_ordinary_time_10_monday_1',
          readingKeys: [
            'season_ordinary_time_10_monday_1',
            'season_ordinary_time_10_monday_2',
          ],
          title: 'Monday of the 10th Week in Ordinary Time (Years I & II)',
          role: LectionaryReadingRole.gospel,
          rank: LectionaryRank.weekday,
          liturgicalColor: LiturgicalColor.green,
          bookNumber: 49,
          bookName: 'Matthew',
          startChapter: 5,
          startVerse: 1,
          citation: 'Matthew 5:1-12',
          verseRange: '1-12',
        ),
      ];

      await tester.pumpWidgetBuilder(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showLectionaryReadingsModal(
                  context: context,
                  title: 'Matthew 5:1',
                  occurrences: occurrences,
                  referenceDate: DateTime(2026, 1, 1),
                ),
                child: const Text('Show Lectionary'),
              ),
            ),
          ),
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
        ),
        surfaceSize: const Size(450, 800),
      );

      await tester.tap(find.text('Show Lectionary'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lectionary_readings_modal_golden');
    });
  });
}
