import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/home_screen.dart';
import 'package:twelve_stars/screens/saints_screen.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import '../test_helper.dart';

void main() {
  final mockSaintsList = [
    const Saint(
      id: 'thomas-aquinas',
      name: 'St. Thomas Aquinas',
      birthDate: '1225',
      deathDate: '1274',
      nationality: 'Italian',
      profession: 'Dominican Friar & Theologian',
      isDoctor: true,
      feastDay: 'January 28',
      patronage: 'Students, Academics, Theologians',
      summary: 'Angelic Doctor of the Church, author of Summa Theologiae.',
      gender: 'male',
    ),
    const Saint(
      id: 'francis-of-assisi',
      name: 'St. Francis of Assisi',
      birthDate: '1181',
      deathDate: '1226',
      nationality: 'Italian',
      profession: 'Friar Minor & Founder',
      isDoctor: false,
      feastDay: 'October 4',
      patronage: 'Animals, Ecology, Peace',
      summary: 'Founder of Franciscan Orders, received the stigmata.',
      gender: 'male',
    ),
    const Saint(
      id: 'therese-of-lisieux',
      name: 'St. Thérèse of Lisieux',
      birthDate: '1873',
      deathDate: '1897',
      nationality: 'French',
      profession: 'Discalced Carmelite Nun',
      isDoctor: true,
      feastDay: 'October 1',
      patronage: 'Missions, Florists',
      summary: 'Doctor of the Church known for the Little Way.',
      gender: 'female',
    ),
  ];

  setUp(() {
    SaintDatabase.mockSaints = mockSaintsList;
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
  });

  tearDown(() {
    SaintDatabase.mockSaints = null;
    PrayerDatabase.mockPrayers = null;
  });

  group('SaintsScreen Widget Tests', () {
    testWidgets(
      'Renders SaintsScreen with search bar, doctor and gender filters, and saint tiles',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(child: const SaintsScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Saint Database'), findsOneWidget);
        expect(find.byKey(const Key('saints_search_field')), findsOneWidget);
        expect(find.byKey(const Key('doctor_filter_chip')), findsOneWidget);
        expect(find.byKey(const Key('men_filter_chip')), findsOneWidget);
        expect(find.byKey(const Key('women_filter_chip')), findsOneWidget);
        expect(find.text('3 saints'), findsOneWidget);

        expect(
          find.byKey(const Key('saint_tile_thomas-aquinas')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_francis-of-assisi')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_therese-of-lisieux')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Filters saints by search query in real time and clears query',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(child: const SaintsScreen()),
        );
        await tester.pumpAndSettle();

        // Enter search text "Francis"
        await tester.enterText(
          find.byKey(const Key('saints_search_field')),
          'Francis',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_francis-of-assisi')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_thomas-aquinas')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('saint_tile_therese-of-lisieux')),
          findsNothing,
        );
        expect(find.text('1 saint'), findsOneWidget);

        // Clear search button
        expect(
          find.byKey(const Key('clear_saints_search_button')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('clear_saints_search_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_thomas-aquinas')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_francis-of-assisi')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_therese-of-lisieux')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Filters by Doctors of the Church toggle', (tester) async {
      await tester.pumpWidget(buildTestableWidget(child: const SaintsScreen()));
      await tester.pumpAndSettle();

      // Toggle doctor filter chip
      await tester.tap(find.byKey(const Key('doctor_filter_chip')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('saint_tile_thomas-aquinas')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('saint_tile_therese-of-lisieux')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('saint_tile_francis-of-assisi')),
        findsNothing,
      );
      expect(find.text('2 saints'), findsOneWidget);
    });

    testWidgets('Filters by Men and Women gender chips', (tester) async {
      await tester.pumpWidget(buildTestableWidget(child: const SaintsScreen()));
      await tester.pumpAndSettle();

      // Tap Men filter
      await tester.tap(find.byKey(const Key('men_filter_chip')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('saint_tile_thomas-aquinas')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('saint_tile_francis-of-assisi')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('saint_tile_therese-of-lisieux')),
        findsNothing,
      );
      expect(find.text('2 saints'), findsOneWidget);

      // Tap Women filter (switches selection)
      await tester.tap(find.byKey(const Key('women_filter_chip')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('saint_tile_therese-of-lisieux')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('saint_tile_thomas-aquinas')), findsNothing);
      expect(
        find.byKey(const Key('saint_tile_francis-of-assisi')),
        findsNothing,
      );
      expect(find.text('1 saint'), findsOneWidget);

      // Untap Women filter (clears selection)
      await tester.tap(find.byKey(const Key('women_filter_chip')));
      await tester.pumpAndSettle();

      expect(find.text('3 saints'), findsOneWidget);
    });

    testWidgets(
      'Displays empty state and reset button when search yields no results',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(child: const SaintsScreen()),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('saints_search_field')),
          'NonExistentSaint',
        );
        await tester.pumpAndSettle();

        expect(find.text('No saints found'), findsOneWidget);
        expect(find.byKey(const Key('reset_filters_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('reset_filters_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_thomas-aquinas')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Tapping a saint tile opens bottom sheet with complete details including gender',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(child: const SaintsScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('saint_tile_thomas-aquinas')));
        await tester.pumpAndSettle();

        // Verify bottom sheet contents
        final sheetFinder = find.byType(SaintDetailsSheet);
        expect(sheetFinder, findsOneWidget);
        expect(
          find.descendant(of: sheetFinder, matching: find.text('Doctor')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheetFinder, matching: find.text('1225 – 1274')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheetFinder, matching: find.text('January 28')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheetFinder, matching: find.text('Gender: ')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheetFinder, matching: find.text('Male')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheetFinder, matching: find.text('Italian')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheetFinder,
            matching: find.text('Dominican Friar & Theologian'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheetFinder,
            matching: find.text('Students, Academics, Theologians'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheetFinder,
            matching: find.text(
              'Angelic Doctor of the Church, author of Summa Theologiae.',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheetFinder,
            matching: find.textContaining('Confirmation Tip:'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Filters by category chips (Priests & Religious)', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(child: const SaintsScreen()));
      await tester.pumpAndSettle();

      final chipFinder = find.byKey(const Key('religious_filter_chip'));
      await tester.ensureVisible(chipFinder);
      await tester.pumpAndSettle();
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('saint_tile_francis-of-assisi')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('saint_tile_thomas-aquinas')), findsNothing);
      expect(
        find.byKey(const Key('saint_tile_therese-of-lisieux')),
        findsNothing,
      );
      expect(find.text('1 saint'), findsOneWidget);
    });

    testWidgets(
      'Filters by category chips (Angels, Apostles, and Evangelists)',
      (tester) async {
        SaintDatabase.mockSaints = [
          ...mockSaintsList,
          const Saint(
            id: 'michael-the-archangel',
            name: 'St. Michael the Archangel',
            nationality: 'Angelic / Heavenly',
            profession: 'Archangel & Defender of the Church',
            isDoctor: false,
            feastDay: 'September 29',
            gender: 'group',
          ),
          const Saint(
            id: 'peter-the-apostle',
            name: 'St. Peter the Apostle',
            nationality: 'Jewish / Roman',
            profession: 'Fisherman, Apostle & First Pope',
            isDoctor: false,
            feastDay: 'June 29',
            gender: 'male',
          ),
          const Saint(
            id: 'luke-the-evangelist',
            name: 'St. Luke the Evangelist',
            nationality: 'Greek / Syrian',
            profession: 'Physician, Historian & Evangelist',
            isDoctor: false,
            feastDay: 'October 18',
            gender: 'male',
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(child: const SaintsScreen()),
        );
        await tester.pumpAndSettle();

        // Test Angels filter
        final angelsChip = find.byKey(const Key('angels_filter_chip'));
        await tester.ensureVisible(angelsChip);
        await tester.pumpAndSettle();
        await tester.tap(angelsChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_michael-the-archangel')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_peter-the-apostle')),
          findsNothing,
        );
        expect(find.text('1 saint'), findsOneWidget);

        // Untap Angels, tap Apostles
        await tester.tap(angelsChip);
        await tester.pumpAndSettle();

        final apostlesChip = find.byKey(const Key('apostles_filter_chip'));
        await tester.ensureVisible(apostlesChip);
        await tester.pumpAndSettle();
        await tester.tap(apostlesChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_peter-the-apostle')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_luke-the-evangelist')),
          findsNothing,
        );

        // Untap Apostles, tap Evangelists
        await tester.tap(apostlesChip);
        await tester.pumpAndSettle();

        final evangelistsChip = find.byKey(
          const Key('evangelists_filter_chip'),
        );
        await tester.ensureVisible(evangelistsChip);
        await tester.pumpAndSettle();
        await tester.tap(evangelistsChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_luke-the-evangelist')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_peter-the-apostle')),
          findsNothing,
        );
      },
    );

    testWidgets('Opens sort modal and changes sort option', (tester) async {
      await tester.pumpWidget(buildTestableWidget(child: const SaintsScreen()));
      await tester.pumpAndSettle();

      // Open sort bottom sheet
      expect(find.byKey(const Key('saints_sort_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('saints_sort_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sort Saints'), findsOneWidget);
      expect(find.byKey(const Key('sort_option_nameDesc')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sort_option_nameDesc')));
      await tester.pumpAndSettle();

      expect(find.text('Name (Z–A)'), findsOneWidget);
    });

    testWidgets(
      'Navigation from HomeScreen drawer to SaintsScreen works properly',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget(child: const HomeScreen()));
        await tester.pumpAndSettle();

        // Open drawer
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('drawer_saints_tile')), findsOneWidget);

        // Tap drawer saint item
        await tester.tap(find.byKey(const Key('drawer_saints_tile')));
        await tester.pumpAndSettle();

        // Verify SaintsScreen is shown
        expect(find.byType(SaintsScreen), findsOneWidget);
        expect(find.text('Saint Database'), findsOneWidget);
      },
    );

    testGoldens(
      'SaintsScreen renders populated list, filters, sort sheet, detail sheet, and widescreen layout',
      (tester) async {
        // 1. Populated Saints Screen
        await tester.pumpWidgetBuilder(
          const SaintsScreen(),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'saints_screen_golden');

        // 2. Doctors filter active
        await tester.tap(find.byKey(const Key('doctor_filter_chip')));
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'saints_screen_doctors_filter_golden',
        );

        // Reset filter
        await tester.tap(find.byKey(const Key('doctor_filter_chip')));
        await tester.pumpAndSettle();

        // 3. Category filter active (Priests & Religious)
        final chipFinder = find.byKey(const Key('religious_filter_chip'));
        await tester.ensureVisible(chipFinder);
        await tester.pumpAndSettle();
        await tester.tap(chipFinder);
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'saints_screen_religious_filter_golden',
        );

        // Reset category filter
        await tester.tap(chipFinder);
        await tester.pumpAndSettle();

        // 4. Sort bottom sheet open
        await tester.tap(find.byKey(const Key('saints_sort_button')));
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'saints_screen_sort_sheet_golden');

        // Close sort modal
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // 5. Saint details modal bottom sheet
        await tester.tap(find.byKey(const Key('saint_tile_thomas-aquinas')));
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'saints_screen_detail_sheet_golden');

        // Close details sheet
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // 6. Widescreen 2-column layout
        await tester.pumpWidgetBuilder(
          const SaintsScreen(),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(1024, 768),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'saints_screen_widescreen_golden');
      },
    );
  });
}
