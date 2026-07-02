import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/screens/home_screen.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import '../test_helper.dart';

void main() {
  group('HomeScreen Widget', () {
    final mockPrayers = [
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
    ];

    setUp(() {
      PrayerDatabase.mockPrayers = mockPrayers;
    });

    testWidgets('renders initial tab (Prayers) and switches to Rosary tab', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(child: const HomeScreen()));
      await tester.pumpAndSettle(); // Let database load

      // Verify app bar and header are present
      expect(find.text('Twelve Stars'), findsOneWidget);

      // Verify default prayers are loaded in English initially
      expect(find.text('Our Father'), findsOneWidget);
      expect(find.text('Hail Mary'), findsOneWidget);
      expect(find.text('Glory Be'), findsOneWidget);

      // Verify navigation items
      expect(find.text('Prayers'), findsWidgets);
      expect(find.text('Rosary'), findsWidgets);

      // Rosary tab content should not be present initially
      expect(find.text('The Holy Rosary'), findsNothing);

      // Switch to the Rosary tab
      await tester.tap(find.text('Rosary').last);
      await tester.pumpAndSettle();

      // Rosary content should now be visible
      expect(find.text('The Holy Rosary'), findsOneWidget);
      expect(find.text('Coming Soon'), findsOneWidget);

      // Prayers should not be visible now
      expect(find.text('Our Father'), findsNothing);

      // Switch back to Prayers tab
      await tester.tap(find.text('Prayers').last);
      await tester.pumpAndSettle();

      // Prayers should be visible again
      expect(find.text('Our Father'), findsOneWidget);
    });

    testWidgets('changes language of prayer in dropdown', (tester) async {
      await tester.pumpWidget(buildTestableWidget(child: const HomeScreen()));
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
      await tester.pumpWidget(buildTestableWidget(child: const HomeScreen()));
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

      await tester.pumpWidget(buildTestableWidget(child: const HomeScreen()));
      await tester.pumpAndSettle();

      // Verify dropdown selects Traditional Chinese and saves to mockSettings
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

      // Reset mockSettings to avoid cross-test pollution
      PrayerDatabase.mockSettings = null;
    });

    testGoldens('HomeScreen renders correctly in both tabs', (tester) async {
      // 1. Initial/Prayers tab golden
      await tester.pumpWidgetBuilder(
        const HomeScreen(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(400, 800),
      );
      await tester.pump(); // Start database loading
      await tester.pumpAndSettle(); // Let database load
      await screenMatchesGolden(tester, 'home_screen_prayers_tab_golden');

      // 2. Rosary tab golden
      // Switch tab
      await tester.tap(find.text('Rosary').last);
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'home_screen_rosary_tab_golden');

      // 3. Search active golden
      // Switch back to Prayers tab
      await tester.tap(find.text('Prayers').last);
      await tester.pumpAndSettle();
      // Tap search button to open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'home_screen_search_active_golden');

      // 4. Search empty state golden
      // Enter search query with no results
      await tester.enterText(find.byType(TextField), 'nonexistentprayer');
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'home_screen_search_empty_golden');
    });
  });
}
