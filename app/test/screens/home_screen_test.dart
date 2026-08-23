import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/home_screen.dart';
import 'package:twelve_stars/screens/settings_screen.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:drift/native.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/time_helper.dart';
import '../test_helper.dart';

void main() {
  group('HomeScreen Widget', () {
    final mockPrayers = [
      Prayer.mock(
        id: 'sign_of_the_cross',
        defaultTitle: 'Sign of the Cross',
        hasAmen: true,
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Sign of the Cross',
              subtitle: 'Signum Crucis',
              text:
                  'In the name of the Father, and of the Son, and of the Holy Spirit.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'our_father',
        defaultTitle: 'Our Father',
        hasAmen: true,
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Our Father',
              subtitle: "The Lord's Prayer (Traditional)",
              text:
                  'Our Father, who art in heaven,\nhallowed be thy name;\nthy kingdom come;\nthy will be done\non earth as it is in heaven.\n\nGive us this day our daily bread;\nand forgive us our trespasses\nas we forgive those who trespass against us;\nand lead us not into temptation,\nbut deliver us from evil.',
              sourceName:
                  'Compendium of the Catechism of the Catholic Church (Vatican)',
              sourceUrl: 'https://vatican.va',
            ),
            PrayerTranslation.mock(
              title: 'Our Father (Modern)',
              subtitle: "The Lord's Prayer (Modern)",
              text: 'Our Father in heaven, hallowed be your name...',
              sourceName: 'Vatican Modern',
              sourceUrl: 'https://vatican.va',
            ),
          ],
          PrayerLanguage.traditionalChinese: [
            PrayerTranslation.mock(
              title: '天主經',
              subtitle: 'Lord’s Prayer',
              text:
                  '我們的天父，願祢的名受顯揚；願祢的國來臨；願祢的旨意奉行在人間，如同在天上。求祢今天賞給我們日用的食糧；求祢寬恕我們的罪過，如同我們寬恕別人一樣；不要讓我們陷於誘惑；但救我們免於凶惡。',
              sourceName: 'Wikipedia',
              sourceUrl: 'https://wikipedia.org',
              chineseLines: [
                [
                  ChineseChar('我', 'wǒ'),
                  ChineseChar('們', 'men'),
                  ChineseChar('的', 'de'),
                  ChineseChar('天', 'tiān'),
                  ChineseChar('父', 'fù'),
                  ChineseChar('，', ''),
                ],
              ],
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'hail_mary',
        defaultTitle: 'Hail Mary',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Hail Mary',
              subtitle: 'Angelic Salutation',
              text: 'Hail Mary, full of grace...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'glory_be',
        defaultTitle: 'Glory Be',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Glory Be',
              subtitle: 'Doxology',
              text: 'Glory be to the Father...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'apostles_creed',
        defaultTitle: 'Apostles\' Creed',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Apostles\' Creed',
              subtitle: 'Profession of Faith',
              text: 'I believe in God, the Father almighty...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'fatima_prayer',
        defaultTitle: 'Fatima Prayer',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Fatima Prayer',
              subtitle: 'Decade Prayer',
              text: 'O my Jesus, forgive us our sins...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'hail_holy_queen',
        defaultTitle: 'Hail Holy Queen',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Hail Holy Queen',
              subtitle: 'Salve Regina',
              text: 'Hail, holy Queen, Mother of mercy...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'final_prayer_rosary',
        defaultTitle: 'Final Prayer',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Final Prayer',
              subtitle: 'Rosary Closing Prayer',
              text: 'O God, whose only begotten Son...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'confiteor',
        defaultTitle: 'Confiteor',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Confiteor',
              subtitle: 'I confess to almighty God',
              text: 'I confess to almighty God...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'gloria',
        defaultTitle: 'Gloria',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Gloria',
              subtitle: 'Glory to God in the Highest',
              text: 'Glory to God in the highest...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'nicene_creed',
        defaultTitle: 'Nicene Creed',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Nicene Creed',
              subtitle: 'Symbol of Faith',
              text: 'I believe in one God, the Father almighty...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'mass_greeting',
        defaultTitle: 'Greeting',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Greeting',
              text:
                  'Priest: In the name of the Father...\nPeople: Amen.\n\nPriest: The Lord be with you.\nPeople: And with your spirit.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'kyrie_eleison',
        defaultTitle: 'Kyrie Eleison',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Kyrie Eleison',
              subtitle: 'Lord, Have Mercy',
              text: 'Lord, have mercy. Christ, have mercy. Lord, have mercy.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'sanctus',
        defaultTitle: 'Sanctus',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Sanctus',
              subtitle: 'Holy, Holy, Holy',
              text: 'Holy, Holy, Holy Lord God of hosts...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'sign_of_peace',
        defaultTitle: 'Sign of Peace',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Sign of Peace',
              text:
                  'Priest: The peace of the Lord be with you always.\nPeople: And with your spirit.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'agnus_dei',
        defaultTitle: 'Agnus Dei',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Agnus Dei',
              subtitle: 'Lamb of God',
              text: 'Lamb of God, you take away the sins of the world...',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'dismissal',
        defaultTitle: 'Blessing & Dismissal',
        category: 'liturgy',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Concluding Blessing & Dismissal',
              text: 'Go forth, the Mass is ended.\nPeople: Thanks be to God.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
    ];

    late BibleDatabase testDb;

    setUp(() async {
      testDb = BibleDatabase(NativeDatabase.memory());
      BibleDatabaseHelper.db = testDb;
      await testDb.ensurePopulated();
      PrayerDatabase.mockPrayers = mockPrayers;
    });

    tearDown(() async {
      TimeHelper.setCustomTime(null);
      await testDb.close();
    });

    testWidgets('HomeScreen drawer opens and navigates to settings', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
        ),
      );
      await tester.pumpAndSettle();

      // Verify drawer is closed initially
      expect(find.byType(Drawer), findsNothing);

      // Open drawer using the menu icon
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify drawer is open
      expect(find.byType(Drawer), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Menu')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('drawer_saints_tile')), findsOneWidget);
      expect(find.byKey(const Key('drawer_settings_tile')), findsOneWidget);
      expect(find.byKey(const Key('drawer_version_tile')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('drawer_version_tile')),
          matching: find.text('v0.0.0-dev'),
        ),
        findsOneWidget,
      );

      // Tap settings tile
      await tester.tap(find.byKey(const Key('drawer_settings_tile')));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byKey(const Key('settings_haptics_tile')), findsOneWidget);
    });

    testWidgets(
      'renders initial tab (Prayers), launches Rosary via FAB, and navigates tabs',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
          ),
        );
        await tester.pumpAndSettle(); // Let database load

        // Verify app bar and header are present
        expect(find.text('Twelve Stars'), findsOneWidget);

        // Verify default prayers are loaded in English initially
        expect(find.text('Our Father'), findsOneWidget);
        expect(find.text('Hail Mary', skipOffstage: false), findsOneWidget);

        // Verify navigation items
        expect(find.text('Prayers'), findsWidgets);
        expect(find.text('Missal'), findsWidgets);
        expect(find.text('Bible'), findsWidgets);

        // Verify FAB to start Rosary is present
        expect(find.text('Start Rosary'), findsOneWidget);

        // Tap FAB to start the Rosary
        await tester.tap(find.text('Start Rosary'));
        await tester.pumpAndSettle();

        // We should now be on the Rosary Screen
        expect(find.text('Select Mysteries'), findsOneWidget);
        expect(find.text('Sign of the Cross'), findsWidgets);

        // Tap the back arrow in the AppBar to pop the Rosary Screen
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // We should be back on the Home/Prayers screen
        expect(find.text('Start Rosary'), findsOneWidget);
        expect(find.text('Our Father'), findsOneWidget);

        // Switch to the Missal tab
        await tester.tap(find.text('Missal').last);
        await tester.pumpAndSettle();
        expect(find.text('Mass Missal'), findsOneWidget);

        // Switch to the Bible tab
        await tester.tap(find.text('Bible').last);
        await tester.pumpAndSettle();
        expect(find.textContaining('In the beginning'), findsOneWidget);
      },
    );

    testWidgets('changes language of prayer in dropdown', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
        ),
      );
      await tester.pumpAndSettle(); // Let database load

      // Tap title bar translate button to expand language selector
      await tester.tap(find.byIcon(Icons.translate_outlined));
      await tester.pumpAndSettle();

      // Select dropdown for Our Father
      final dropdownFinder = find.byType(DropdownButton<PrayerLanguage>).first;
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap Traditional Chinese (nativeName '繁體中文')
      final chineseItemFinder = find.text('繁體中文').last;
      await tester.tap(chineseItemFinder);
      await tester.pumpAndSettle();

      // Title should change to '天主經'
      expect(find.text('天主經'), findsOneWidget);
      expect(find.text('wǒ'), findsWidgets);
    });

    testWidgets('search bar filters prayers list and handles clear/close', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
        ),
      );
      await tester.pumpAndSettle(); // Let database load

      // Initially all three mock prayers are visible
      expect(find.text('Our Father'), findsOneWidget);
      expect(find.text('Hail Mary', skipOffstage: false), findsOneWidget);
      expect(find.text('Glory Be', skipOffstage: false), findsOneWidget);

      // Search button should be visible in Prayers tab
      final searchButton = find.byIcon(Icons.search);
      expect(searchButton, findsOneWidget);

      // Tap search button to open search
      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      // AppBar should contain TextField
      final searchTextField = find.byType(TextField);
      expect(searchTextField, findsOneWidget);

      // Enter search query "hail"
      await tester.enterText(searchTextField, 'hail');
      await tester.pumpAndSettle();

      // Only "Hail Mary" should match and be visible
      expect(find.text('Hail Mary'), findsOneWidget);
      expect(find.text('Our Father'), findsNothing);
      expect(find.text('Glory Be'), findsNothing);

      // Clear search via clear button
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // All mock prayers should be visible again
      expect(find.text('Our Father'), findsOneWidget);
      expect(find.text('Hail Mary', skipOffstage: false), findsOneWidget);
      expect(find.text('Glory Be', skipOffstage: false), findsOneWidget);

      // Type a query that yields no results
      await tester.enterText(searchTextField, 'nonexistentprayer');
      await tester.pumpAndSettle();

      // Verify empty search state is visible
      expect(
        find.text('No prayers matching "nonexistentprayer"'),
        findsOneWidget,
      );
      final clearSearchButton = find.text('Clear search');
      expect(clearSearchButton, findsOneWidget);

      // Tap "Clear search" in empty state
      await tester.tap(clearSearchButton);
      await tester.pumpAndSettle();

      // All mock prayers should be visible again
      expect(find.text('Our Father'), findsOneWidget);

      // Search is already open, so tap back button to close search
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // TextField should be gone, standard title back
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Twelve Stars'), findsOneWidget);
    });

    testWidgets('toggles language selector widget via title bar button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, language selector is hidden
      expect(find.text('Primary Language'), findsNothing);
      expect(find.text('Secondary Language'), findsNothing);

      // Tap title bar translate button to show language selectors
      await tester.tap(find.byIcon(Icons.translate_outlined));
      await tester.pumpAndSettle();

      // Language selector should now be visible
      expect(find.text('Primary Language'), findsOneWidget);
      expect(find.text('Secondary Language'), findsOneWidget);

      // Tap title bar translate button again to hide language selectors
      await tester.tap(find.byIcon(Icons.translate));
      await tester.pumpAndSettle();

      // Language selector should be hidden again
      expect(find.text('Primary Language'), findsNothing);
      expect(find.text('Secondary Language'), findsNothing);
    });

    testWidgets(
      'pushes content down when at top of page and preserves scroll viewport when scrolled down',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
          ),
        );
        await tester.pumpAndSettle();

        final scrollableFinder = find.byType(Scrollable).first;
        final scrollState = tester.state<ScrollableState>(scrollableFinder);

        // 1. At top of page: initial scroll offset is 0.0
        expect(scrollState.position.pixels, equals(0.0));

        // Tap translate button to expand language selector while at top
        await tester.tap(find.byIcon(Icons.translate_outlined));
        await tester.pumpAndSettle();

        // Language selector is visible at top of scroll view and scroll offset stays at 0.0 (pushing prayers down)
        expect(find.text('Primary Language'), findsOneWidget);
        expect(scrollState.position.pixels, equals(0.0));

        // Close language selector
        await tester.tap(find.byIcon(Icons.translate));
        await tester.pumpAndSettle();
        expect(find.text('Primary Language'), findsNothing);

        // 2. Scroll down by 200px
        await tester.drag(scrollableFinder, const Offset(0, -200));
        await tester.pumpAndSettle();
        final offsetBefore = scrollState.position.pixels;
        expect(offsetBefore, greaterThan(5.0));

        // Tap translate button to open selector while scrolled down
        await tester.tap(find.byIcon(Icons.translate_outlined));
        await tester.pumpAndSettle();

        // Language selector space created at top, scroll offset increased to preserve viewport contents
        final offsetAfter = scrollState.position.pixels;
        expect(offsetAfter, greaterThan(offsetBefore));

        // Scroll back to top (0.0) -> language selector is sitting at top of page
        await tester.drag(scrollableFinder, const Offset(0, 500));
        await tester.pumpAndSettle();
        expect(scrollState.position.pixels, equals(0.0));
        expect(find.text('Primary Language'), findsOneWidget);
      },
    );

    testWidgets('persists primary/compare languages and version selections', (
      tester,
    ) async {
      final initialSettings = UserSettings(
        primaryLanguageCode: 'english',
        compareLanguageCode: 'latin',
        preferredVersions: [],
      );
      PrayerDatabase.mockSettings = initialSettings;

      await tester.pumpWidget(
        buildTestableWidget(
          child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap title bar translate button to expand language selector
      await tester.tap(find.byIcon(Icons.translate_outlined));
      await tester.pumpAndSettle();

      // 1. Verify dropdown selects Traditional Chinese and saves to mockSettings
      final dropdownFinder = find.byType(DropdownButton<PrayerLanguage>).first;
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      final chineseItemFinder = find.text('繁體中文').last;
      await tester.tap(chineseItemFinder);
      await tester.pumpAndSettle();

      expect(
        PrayerDatabase.mockSettings?.primaryLanguageCode,
        'traditionalChinese',
      );

      // 2. Load settings with an existing version preference and verify it is rendered
      final persistedSettings = UserSettings(
        primaryLanguageCode: 'english',
        compareLanguageCode: 'latin',
        preferredVersions: [PrayerVersionPreference('our_father_english', 1)],
      );
      PrayerDatabase.mockSettings = persistedSettings;

      await tester.pumpWidget(
        buildTestableWidget(
          child: HomeScreen(
            key: const Key('persisted'),
            initialDate: DateTime(2026, 7, 6),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Our Father (Modern)'), findsOneWidget);

      // 3. Swipe left to change version back to index 0, and verify it updates the persisted preference
      await tester.fling(
        find.text('Our Father (Modern)'),
        const Offset(-400.0, 0.0),
        1000.0,
      );
      await tester.pumpAndSettle();

      final pref = PrayerDatabase.mockSettings?.preferredVersions?.firstWhere(
        (p) => p.key == 'our_father_english',
      );
      expect(pref?.versionIndex, 0);

      // Reset mockSettings to avoid cross-test pollution
      PrayerDatabase.mockSettings = null;
    });

    testWidgets(
      'clears secondary language via X clear button and None dropdown option',
      (tester) async {
        final initialSettings = UserSettings(
          primaryLanguageCode: 'english',
          compareLanguageCode: 'latin',
        );
        PrayerDatabase.mockSettings = initialSettings;

        await tester.pumpWidget(
          buildTestableWidget(
            child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
          ),
        );
        await tester.pumpAndSettle();

        // Tap title bar translate button to expand language selector
        await tester.tap(find.byIcon(Icons.translate_outlined));
        await tester.pumpAndSettle();

        // Verify clear button is visible
        final clearButtonFinder = find.byKey(
          const ValueKey('clear_secondary_language'),
        );
        expect(clearButtonFinder, findsOneWidget);

        // Tap clear button
        await tester.tap(clearButtonFinder);
        await tester.pumpAndSettle();

        expect(PrayerDatabase.mockSettings?.compareLanguageCode, 'none');

        // Select Spanish in secondary dropdown
        final secondaryDropdownFinder = find
            .byType(DropdownButton<PrayerLanguage?>)
            .last;
        await tester.tap(secondaryDropdownFinder);
        await tester.pumpAndSettle();

        final spanishItemFinder = find.text('Español').last;
        await tester.tap(spanishItemFinder);
        await tester.pumpAndSettle();

        expect(PrayerDatabase.mockSettings?.compareLanguageCode, 'spanish');

        // Reset mockSettings
        PrayerDatabase.mockSettings = null;
      },
    );

    testWidgets('swaps primary and secondary languages via swap button', (
      tester,
    ) async {
      final initialSettings = UserSettings(
        primaryLanguageCode: 'english',
        compareLanguageCode: 'latin',
      );
      PrayerDatabase.mockSettings = initialSettings;

      await tester.pumpWidget(
        buildTestableWidget(
          child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap title bar translate button to expand language selector
      await tester.tap(find.byIcon(Icons.translate_outlined));
      await tester.pumpAndSettle();

      // Tap swap button
      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();

      expect(PrayerDatabase.mockSettings?.primaryLanguageCode, 'latin');
      expect(PrayerDatabase.mockSettings?.compareLanguageCode, 'english');

      PrayerDatabase.mockSettings = null;
    });

    testGoldens(
      'HomeScreen language selector floating card maintains constant size when secondary language is set vs None',
      (tester) async {
        TimeHelper.setCustomTime(DateTime(2026, 7, 6));

        await tester.pumpWidgetBuilder(
          HomeScreen(initialDate: DateTime(2026, 7, 6)),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(400, 800),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // Tap title bar translate button to expand language selector card
        await tester.tap(find.byIcon(Icons.translate_outlined));
        await tester.pumpAndSettle();

        // Golden 1: Language selector card expanded with Secondary Language (Latin)
        await screenMatchesGolden(
          tester,
          'home_screen_language_selector_expanded_golden',
        );

        // Tap clear button to clear Secondary Language
        await tester.tap(
          find.byKey(const ValueKey('clear_secondary_language')),
        );
        await tester.pumpAndSettle();

        // Golden 2: Language selector card expanded with Secondary Language set to None (verifies constant card size!)
        await screenMatchesGolden(
          tester,
          'home_screen_language_selector_none_golden',
        );
      },
    );

    testGoldens('HomeScreen renders correctly in all tabs', (tester) async {
      TimeHelper.setCustomTime(DateTime(2026, 7, 6));
      // 1. Initial/Prayers tab golden (with Start Rosary FAB!)
      await tester.pumpWidgetBuilder(
        HomeScreen(initialDate: DateTime(2026, 7, 6)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(400, 800),
      );
      await tester.pump(); // Start database loading
      await tester.pumpAndSettle(); // Let database load
      await screenMatchesGolden(tester, 'home_screen_prayers_tab_golden');

      // 2. Missal tab golden
      await tester.tap(find.text('Missal').last);
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'home_screen_missal_tab_golden');

      // 3. Missal tab with Language Selector expanded golden
      await tester.tap(find.byIcon(Icons.translate_outlined));
      await tester.pumpAndSettle();
      await screenMatchesGolden(
        tester,
        'home_screen_missal_tab_language_selector_golden',
      );
      // Close language selector for subsequent steps
      await tester.tap(find.byIcon(Icons.translate));
      await tester.pumpAndSettle();

      // 4. Search active golden
      // Switch back to Prayers tab
      await tester.tap(find.text('Prayers').last);
      await tester.pumpAndSettle();
      // Tap search button to open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'home_screen_search_active_golden');

      // 5. Search empty state golden
      // Enter search query with no results
      await tester.enterText(find.byType(TextField), 'nonexistentprayer');
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'home_screen_search_empty_golden');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });

    testGoldens('HomeScreen drawer menu renders correctly', (tester) async {
      TimeHelper.setCustomTime(DateTime(2026, 7, 6));
      await tester.pumpWidgetBuilder(
        HomeScreen(initialDate: DateTime(2026, 7, 6)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(400, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Open drawer using the menu icon
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify drawer is open with expected items
      expect(find.byType(Drawer), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Menu')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('drawer_saints_tile')), findsOneWidget);
      expect(find.byKey(const Key('drawer_settings_tile')), findsOneWidget);
      expect(find.byKey(const Key('drawer_version_tile')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('drawer_version_tile')),
          matching: find.text('v0.0.0-dev'),
        ),
        findsOneWidget,
      );

      // Golden: Drawer / Hamburger menu open state
      await screenMatchesGolden(tester, 'home_screen_drawer_golden');
    });

    testWidgets('HomeScreen opens font size options modal and adjusts slider', (
      tester,
    ) async {
      TimeHelper.setCustomTime(DateTime(2026, 7, 6));
      await tester.pumpWidget(
        buildTestableWidget(
          child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap text_fields icon in title bar
      await tester.tap(find.byIcon(Icons.text_fields));
      await tester.pumpAndSettle();

      // Modal should display 'Reading Options' and 'Font Size: 16 pt'
      expect(find.text('Reading Options'), findsOneWidget);
      expect(find.text('Font Size: 16 pt'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Close modal
      Navigator.of(tester.element(find.text('Reading Options'))).pop();
      await tester.pumpAndSettle();
    });

    testGoldens(
      'widescreen layout renders NavigationRail and double-column prayer masonry list',
      (tester) async {
        TimeHelper.setCustomTime(DateTime(2026, 7, 6));
        await tester.pumpWidgetBuilder(
          HomeScreen(initialDate: DateTime(2026, 7, 6)),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(1024, 768),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // On widescreen (width >= 600):
        // 1. NavigationRail should be present, NavigationBar at bottom should not be present
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byType(SliverCrossAxisGroup), findsOneWidget);

        // 2. Double column prayer list should be present with correct column placement
        expect(find.text('Sign of the Cross'), findsOneWidget);
        expect(find.text('Our Father'), findsOneWidget);
        expect(find.text('Hail Mary', skipOffstage: false), findsOneWidget);

        // Verify left column items have a smaller X offset than right column items
        final signCrossOffset = tester.getTopLeft(
          find.text('Sign of the Cross'),
        );
        final ourFatherOffset = tester.getTopLeft(find.text('Our Father'));
        expect(signCrossOffset.dx, lessThan(ourFatherOffset.dx));

        // Golden: widescreen Prayers tab with NavigationRail and double-column layout
        await screenMatchesGolden(
          tester,
          'home_screen_widescreen_prayers_tab_golden',
        );

        // 3. NavigationRail navigation works
        await tester.tap(find.text('Missal').last);
        await tester.pumpAndSettle();
        expect(find.text('Mass Missal'), findsOneWidget);

        // Golden: widescreen Missal tab via NavigationRail
        await screenMatchesGolden(
          tester,
          'home_screen_widescreen_missal_tab_golden',
        );

        await tester.tap(find.text('Prayers').last);
        await tester.pumpAndSettle();
        expect(find.text('Our Father'), findsOneWidget);
      },
    );

    testWidgets(
      'HomeScreen dynamically adapts between narrow and widescreen layouts on resize',
      (tester) async {
        TimeHelper.setCustomTime(DateTime(2026, 7, 6));

        // 1. Start with wide layout (>= 600px)
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byType(SliverCrossAxisGroup), findsOneWidget);

        // 2. Resize dynamically to narrow layout (< 600px)
        tester.view.physicalSize = const Size(400, 800);
        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsNothing);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(SliverCrossAxisGroup), findsNothing);

        // 3. Resize back to wide layout (>= 600px)
        tester.view.physicalSize = const Size(1024, 768);
        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byType(SliverCrossAxisGroup), findsOneWidget);
      },
    );
  });
}
