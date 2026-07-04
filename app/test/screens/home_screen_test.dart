import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/home_screen.dart';
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
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Sign of the Cross',
              subtitle: 'Signum Crucis',
              text:
                  'In the name of the Father, and of the Son, and of the Holy Spirit. Amen.',
              sourceName: 'Vatican',
              sourceUrl: 'https://vatican.va',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'our_father',
        defaultTitle: 'Our Father',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation.mock(
              title: 'Our Father',
              subtitle: "The Lord's Prayer (Traditional)",
              text:
                  'Our Father, who art in heaven,\nhallowed be thy name;\nthy kingdom come;\nthy will be done\non earth as it is in heaven.\n\nGive us this day our daily bread;\nand forgive us our trespasses\nas we forgive those who trespass against us;\nand lead us not into temptation,\nbut deliver us from evil.\n\nAmen.',
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
                  '我們的天父，願祢的名受顯揚；願祢的國來臨；願祢的旨意奉行在人間，如同在天上。求祢今天賞給我們日用的食糧；求祢寬恕我們的罪過，如同我們寬恕別人一樣；不要讓我們陷於誘惑；但救我們免於凶惡。亞孟。',
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
        expect(find.text('Hail Mary'), findsOneWidget);

        // Verify navigation items
        expect(find.text('Prayers'), findsWidgets);
        expect(find.text('Calendar'), findsWidgets);
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

        // Switch to the Calendar tab
        await tester.tap(find.text('Calendar').last);
        await tester.pumpAndSettle();
        expect(find.text('Color: Green'), findsOneWidget);

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
      expect(find.text('Hail Mary'), findsOneWidget);
      expect(find.text('Glory Be'), findsOneWidget);

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
      expect(find.text('Hail Mary'), findsOneWidget);
      expect(find.text('Glory Be'), findsOneWidget);

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

      // 2. Calendar tab golden
      await tester.tap(find.text('Calendar').last);
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'home_screen_calendar_tab_golden');

      // 3. Missal tab golden
      await tester.tap(find.text('Missal').last);
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'home_screen_missal_tab_golden');

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
    });
  });
}
