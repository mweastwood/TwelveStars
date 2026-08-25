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

    testWidgets(
      'Filters by category chips (Priests, Deacons, Brothers, Nuns)',
      (tester) async {
        SaintDatabase.mockSaints = [
          ...mockSaintsList,
          const Saint(
            id: 'stephen-first-martyr',
            name: 'St. Stephen',
            nationality: 'Jewish / Hellenistic',
            profession: 'Deacon & Protomartyr of Christianity',
            categories: [SaintCategory.deacon, SaintCategory.martyr],
            isDoctor: false,
            feastDay: 'December 26',
            gender: 'male',
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(child: const SaintsScreen()),
        );
        await tester.pumpAndSettle();

        // Test Priests filter
        final priestsChipFinder = find.byKey(const Key('priests_filter_chip'));
        await tester.ensureVisible(priestsChipFinder);
        await tester.pumpAndSettle();
        await tester.tap(priestsChipFinder);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_thomas-aquinas')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_francis-of-assisi')),
          findsNothing,
        );
        expect(find.text('1 saint'), findsOneWidget);

        // Untap Priests, tap Deacons
        await tester.tap(priestsChipFinder);
        await tester.pumpAndSettle();

        final deaconsChipFinder = find.byKey(const Key('deacons_filter_chip'));
        await tester.ensureVisible(deaconsChipFinder);
        await tester.pumpAndSettle();
        await tester.tap(deaconsChipFinder);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_stephen-first-martyr')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_thomas-aquinas')),
          findsNothing,
        );
        expect(find.text('1 saint'), findsOneWidget);

        // Untap Deacons, tap Brothers
        await tester.tap(deaconsChipFinder);
        await tester.pumpAndSettle();

        final brothersChipFinder = find.byKey(
          const Key('brothers_filter_chip'),
        );
        await tester.ensureVisible(brothersChipFinder);
        await tester.pumpAndSettle();
        await tester.tap(brothersChipFinder);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_francis-of-assisi')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_thomas-aquinas')),
          findsNothing,
        );
        expect(find.text('1 saint'), findsOneWidget);

        // Untap Brothers, tap Nuns
        await tester.tap(brothersChipFinder);
        await tester.pumpAndSettle();

        final nunsChipFinder = find.byKey(const Key('nuns_filter_chip'));
        await tester.ensureVisible(nunsChipFinder);
        await tester.pumpAndSettle();
        await tester.tap(nunsChipFinder);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_therese-of-lisieux')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_thomas-aquinas')),
          findsNothing,
        );
        expect(find.text('1 saint'), findsOneWidget);
      },
    );

    testWidgets(
      'Filters by category chips (Angels, Apostles, Evangelists, Popes, Bishops, Mystics, Virgins, Monarchs, Healers, Holy Family, Laity)',
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
            gender: 'other',
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
          const Saint(
            id: 'joseph',
            name: 'St. Joseph',
            nationality: 'Judean',
            profession: 'Carpenter (Tekton) & Foster Father of Jesus',
            isDoctor: false,
            feastDay: 'March 19',
            gender: 'male',
          ),
          const Saint(
            id: 'dominic-savio',
            name: 'St. Dominic Savio',
            nationality: 'Italian',
            profession: 'Student & Pupil of Don Bosco',
            isDoctor: false,
            feastDay: 'May 6',
            gender: 'male',
          ),
          const Saint(
            id: 'pius-v',
            name: 'St. Pius V (Antonio Ghislieri)',
            nationality: 'Italian',
            profession: 'Pope & Dominican Friar',
            isDoctor: false,
            feastDay: 'April 30',
            gender: 'male',
          ),
          const Saint(
            id: 'nicholas-of-myra',
            name: 'St. Nicholas of Myra',
            nationality: 'Greek / Roman',
            profession: 'Bishop of Myra & Wonderworker',
            isDoctor: false,
            feastDay: 'December 6',
            gender: 'male',
          ),
          const Saint(
            id: 'padre-pio',
            name: 'St. Pio of Pietrelcina (Padre Pio)',
            nationality: 'Italian',
            profession: 'Capuchin Friar, Priest & Stigmatist',
            isDoctor: false,
            feastDay: 'September 23',
            gender: 'male',
          ),
          const Saint(
            id: 'kateri-tekakwitha',
            name: 'St. Kateri Tekakwitha',
            nationality: 'Mohawk / Algonquin',
            profession: 'Lay Consecrated Virgin & Lily of the Mohawks',
            isDoctor: false,
            feastDay: 'July 14',
            gender: 'female',
          ),
          const Saint(
            id: 'louis-ix-of-france',
            name: 'St. Louis IX of France',
            nationality: 'French',
            profession: 'King of France & Third Order Franciscan',
            isDoctor: false,
            feastDay: 'August 25',
            gender: 'male',
          ),
          const Saint(
            id: 'gianna-beretta-molla',
            name: 'St. Gianna Beretta Molla',
            nationality: 'Italian',
            profession: 'Pediatrician & Mother',
            isDoctor: false,
            feastDay: 'April 28',
            gender: 'female',
          ),
          const Saint(
            id: 'vietnamese-martyrs',
            name: 'The Vietnamese Martyrs (St. Andrew Dũng-Lạc & Companions)',
            nationality: 'Vietnamese / French / Spanish',
            profession: 'Priests, Catechists, Religious & Lay Martyrs',
            categories: [
              SaintCategory.group,
              SaintCategory.bishop,
              SaintCategory.priest,
              SaintCategory.brother,
              SaintCategory.martyr,
              SaintCategory.laity,
            ],
            isDoctor: false,
            feastDay: 'November 24',
            gender: 'other',
          ),
          const Saint(
            id: 'abraham-the-patriarch',
            name: 'Abraham the Patriarch',
            nationality: 'Hebrew',
            profession: 'Patriarch & Father of Faith',
            categories: [SaintCategory.patriarch],
            isDoctor: false,
            feastDay: 'October 9',
            gender: 'male',
          ),
          const Saint(
            id: 'moses-the-prophet',
            name: 'Moses the Prophet',
            nationality: 'Hebrew / Israelite',
            profession: 'Prophet, Lawgiver & Leader of Israel',
            categories: [SaintCategory.prophet],
            isDoctor: false,
            feastDay: 'September 4',
            gender: 'male',
          ),
          const Saint(
            id: 'samuel-the-prophet',
            name: 'Samuel the Prophet',
            nationality: 'Israelite',
            profession: 'Prophet & Judge',
            categories: [SaintCategory.prophet, SaintCategory.judge],
            isDoctor: false,
            feastDay: 'August 20',
            gender: 'male',
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(child: const SaintsScreen()),
        );
        await tester.pumpAndSettle();

        // Test Group filter
        final groupChip = find.byKey(const Key('group_filter_chip'));
        await tester.ensureVisible(groupChip);
        await tester.pumpAndSettle();
        await tester.tap(groupChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_vietnamese-martyrs')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_michael-the-archangel')),
          findsNothing,
        );
        expect(find.text('1 saint'), findsOneWidget);

        // Untap Group, tap Angels
        await tester.tap(groupChip);
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

        // Untap Angels, tap Patriarchs
        await tester.tap(angelsChip);
        await tester.pumpAndSettle();

        final patriarchsChip = find.byKey(const Key('patriarchs_filter_chip'));
        await tester.ensureVisible(patriarchsChip);
        await tester.pumpAndSettle();
        await tester.tap(patriarchsChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_abraham-the-patriarch')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_moses-the-prophet')),
          findsNothing,
        );

        // Untap Patriarchs, tap Prophets
        await tester.tap(patriarchsChip);
        await tester.pumpAndSettle();

        final prophetsChip = find.byKey(const Key('prophets_filter_chip'));
        await tester.ensureVisible(prophetsChip);
        await tester.pumpAndSettle();
        await tester.tap(prophetsChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_moses-the-prophet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_samuel-the-prophet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_abraham-the-patriarch')),
          findsNothing,
        );

        // Untap Prophets, tap Judges
        await tester.tap(prophetsChip);
        await tester.pumpAndSettle();

        final judgesChip = find.byKey(const Key('judges_filter_chip'));
        await tester.ensureVisible(judgesChip);
        await tester.pumpAndSettle();
        await tester.tap(judgesChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_moses-the-prophet')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('saint_tile_samuel-the-prophet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_abraham-the-patriarch')),
          findsNothing,
        );

        // Untap Judges, tap Apostles
        await tester.tap(judgesChip);
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

        // Untap Evangelists, tap Popes
        await tester.tap(evangelistsChip);
        await tester.pumpAndSettle();

        final popesChip = find.byKey(const Key('popes_filter_chip'));
        await tester.ensureVisible(popesChip);
        await tester.pumpAndSettle();
        await tester.tap(popesChip);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('saint_tile_pius-v')), findsOneWidget);
        expect(
          find.byKey(const Key('saint_tile_peter-the-apostle')),
          findsOneWidget,
        );

        // Untap Popes, tap Bishops
        await tester.tap(popesChip);
        await tester.pumpAndSettle();

        final bishopsChip = find.byKey(const Key('bishops_filter_chip'));
        await tester.ensureVisible(bishopsChip);
        await tester.pumpAndSettle();
        await tester.tap(bishopsChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_nicholas-of-myra')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('saint_tile_pius-v')), findsNothing);

        // Untap Bishops, tap Mystics
        await tester.tap(bishopsChip);
        await tester.pumpAndSettle();

        final mysticsChip = find.byKey(const Key('mystics_filter_chip'));
        await tester.ensureVisible(mysticsChip);
        await tester.pumpAndSettle();
        await tester.tap(mysticsChip);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('saint_tile_padre-pio')), findsOneWidget);
        expect(
          find.byKey(const Key('saint_tile_nicholas-of-myra')),
          findsNothing,
        );

        // Untap Mystics, tap Virgins
        await tester.tap(mysticsChip);
        await tester.pumpAndSettle();

        final virginsChip = find.byKey(const Key('virgins_filter_chip'));
        await tester.ensureVisible(virginsChip);
        await tester.pumpAndSettle();
        await tester.tap(virginsChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_kateri-tekakwitha')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('saint_tile_padre-pio')), findsNothing);

        // Untap Virgins, tap Monarchs
        await tester.tap(virginsChip);
        await tester.pumpAndSettle();

        final monarchsChip = find.byKey(const Key('monarchs_filter_chip'));
        await tester.ensureVisible(monarchsChip);
        await tester.pumpAndSettle();
        await tester.tap(monarchsChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_louis-ix-of-france')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_kateri-tekakwitha')),
          findsNothing,
        );

        // Untap Monarchs, tap Healers & Missionaries
        await tester.tap(monarchsChip);
        await tester.pumpAndSettle();

        final healersChip = find.byKey(const Key('healers_filter_chip'));
        await tester.ensureVisible(healersChip);
        await tester.pumpAndSettle();
        await tester.tap(healersChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_gianna-beretta-molla')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_luke-the-evangelist')),
          findsOneWidget,
        );

        // Untap Healers, tap Holy Family
        await tester.tap(healersChip);
        await tester.pumpAndSettle();

        final holyFamilyChip = find.byKey(const Key('holy_family_filter_chip'));
        await tester.ensureVisible(holyFamilyChip);
        await tester.pumpAndSettle();
        await tester.tap(holyFamilyChip);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('saint_tile_joseph')), findsOneWidget);
        expect(find.byKey(const Key('saint_tile_dominic-savio')), findsNothing);

        // Untap Holy Family, tap Laity
        await tester.tap(holyFamilyChip);
        await tester.pumpAndSettle();

        final laityChip = find.byKey(const Key('laity_filter_chip'));
        await tester.ensureVisible(laityChip);
        await tester.pumpAndSettle();
        await tester.tap(laityChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saint_tile_dominic-savio')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_gianna-beretta-molla')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('saint_tile_kateri-tekakwitha')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders dual and triple category badges on SaintCard and SaintDetailsSheet',
      (tester) async {
        final multiSaint = const Saint(
          id: 'test-multi-saint',
          name: 'St. Test Multi Saint',
          nationality: 'Italian',
          profession: 'Doctor of the Church, Carmelite Priest & Mystic',
          isDoctor: true,
          gender: 'male',
        );
        SaintDatabase.mockSaints = [multiSaint];

        await tester.pumpWidget(
          buildTestableWidget(child: const SaintsScreen()),
        );
        await tester.pumpAndSettle();

        // 1. SaintCard should display badges for Doctor, Mystic, and Priest
        expect(find.text('Doctor of the Church'), findsOneWidget);
        expect(find.text('Mystic & Contemplative'), findsOneWidget);
        expect(find.text('Priest'), findsOneWidget);

        // 2. Open details sheet
        await tester.tap(find.byKey(const Key('saint_tile_test-multi-saint')));
        await tester.pumpAndSettle();

        final sheetFinder = find.byType(SaintDetailsSheet);
        expect(sheetFinder, findsOneWidget);
        expect(
          find.descendant(
            of: sheetFinder,
            matching: find.text('Doctor of the Church'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheetFinder,
            matching: find.text('Mystic & Contemplative'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheetFinder, matching: find.text('Priest')),
          findsOneWidget,
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

        // 3. Category filter active (Priests)
        final chipFinder = find.byKey(const Key('priests_filter_chip'));
        await tester.ensureVisible(chipFinder);
        await tester.pumpAndSettle();
        await tester.tap(chipFinder);
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'saints_screen_priests_filter_golden',
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
