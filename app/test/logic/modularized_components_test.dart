import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/screens/prayers_tab.dart';
import 'package:twelve_stars/widgets/reader/missal_ordinary_sections.dart';
import 'package:twelve_stars/widgets/two_column_sliver_list.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Database Converters (database_converters.dart)', () {
    test(
      'LocalizedTranslationsConverter round-trips and handles malformed SQL',
      () {
        const converter = LocalizedTranslationsConverter();
        expect(converter.fromSql(''), isEmpty);
        expect(converter.fromSql('not-json'), isEmpty);
        expect(converter.fromSql('{"not": "a list"}'), isEmpty);
        expect(converter.fromSql('[123, "skip-me"]'), isEmpty);

        final items = [
          LocalizedTranslations(
            languageCode: 'en',
            list: [
              PrayerTranslation(
                title: 'Hail Mary',
                subtitle: 'Ave Maria',
                text: 'Hail Mary, full of grace...',
              ),
            ],
          ),
        ];

        final sql = converter.toSql(items);
        final restored = converter.fromSql(sql);
        expect(restored, hasLength(1));
        expect(restored.first.languageCode, 'en');
        expect(restored.first.list?.first.title, 'Hail Mary');
      },
    );

    test(
      'PreferredVersionsConverter round-trips and handles malformed SQL',
      () {
        const converter = PreferredVersionsConverter();
        expect(converter.fromSql(''), isEmpty);
        expect(converter.fromSql('invalid'), isEmpty);
        expect(converter.fromSql('{}'), isEmpty);

        final prefs = [PrayerVersionPreference('ave_maria_en', 1)];

        final sql = converter.toSql(prefs);
        final restored = converter.fromSql(sql);
        expect(restored, hasLength(1));
        expect(restored.first.key, 'ave_maria_en');
        expect(restored.first.versionIndex, 1);
      },
    );

    test('StringListConverter round-trips and handles malformed SQL', () {
      const converter = StringListConverter();
      expect(converter.fromSql(''), isEmpty);
      expect(converter.fromSql('invalid'), isEmpty);
      expect(converter.fromSql('{}'), isEmpty);

      const list = ['mass_greeting', 'gloria'];
      final sql = converter.toSql(list);
      expect(converter.fromSql(sql), equals(list));
    });

    test('BibleRibbonsConverter round-trips and handles malformed SQL', () {
      const converter = BibleRibbonsConverter();
      expect(converter.fromSql(''), isEmpty);
      expect(converter.fromSql('invalid'), isEmpty);
      expect(converter.fromSql('{}'), isEmpty);

      const ribbons = [
        BibleRibbonBookmark(ribbonIndex: 0, bookNumber: 50, chapter: 1),
      ];
      final sql = converter.toSql(ribbons);
      final restored = converter.fromSql(sql);
      expect(restored, hasLength(1));
      expect(restored.first.ribbonIndex, 0);
      expect(restored.first.bookNumber, 50);
      expect(restored.first.chapter, 1);
    });
  });

  group('BibleDatabase.getVersesForRanges', () {
    late BibleDatabase db;

    setUp(() async {
      db = BibleDatabase(NativeDatabase.memory());
      await db.batch((b) {
        b.insertAll(db.bibleVerses, [
          for (int v = 1; v <= 4; v++)
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: v,
              verseText: 'Gen 1:$v',
              translationCode: 'CPDV',
            ),
          for (int v = 1; v <= 3; v++)
            BibleVersesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 2,
              verseNumber: v,
              verseText: 'Gen 2:$v',
              translationCode: 'CPDV',
            ),
        ]);
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('returns empty list when ranges is empty', () async {
      final result = await db.getVersesForRanges(
        translationCode: 'CPDV',
        bookNumber: 1,
        ranges: const [],
      );
      expect(result, isEmpty);
    });

    test(
      'queries discrete verses, startVerseLimit, and endVerseLimit across chapters',
      () async {
        final verses = await db.getVersesForRanges(
          translationCode: 'CPDV',
          bookNumber: 1,
          ranges: [
            ChapterVerseRange(chapter: 1, verses: [1], startVerseLimit: 3),
            ChapterVerseRange(chapter: 2, endVerseLimit: 2),
          ],
        );

        expect(
          verses.map((v) => '${v.chapter}:${v.verseNumber}').toList(),
          equals(['1:1', '1:3', '1:4', '2:1', '2:2']),
        );
      },
    );

    test(
      'queries verses combined with endVerseLimit and startVerseLimit combined with endVerseLimit',
      () async {
        final verses = await db.getVersesForRanges(
          translationCode: 'CPDV',
          bookNumber: 1,
          ranges: [
            ChapterVerseRange(chapter: 1, verses: [4], endVerseLimit: 2),
            ChapterVerseRange(chapter: 2, startVerseLimit: 2, endVerseLimit: 2),
          ],
        );

        expect(
          verses.map((v) => '${v.chapter}:${v.verseNumber}').toList(),
          equals(['1:1', '1:2', '1:4', '2:2']),
        );
      },
    );
  });

  group('SaintCategoryClassifier', () {
    test('classifies saints identically to Saint.computeCategories', () {
      final categories = SaintCategoryClassifier.computeCategories(
        id: 'thomas-aquinas',
        name: 'St. Thomas Aquinas',
        nationality: 'Italian',
        profession: 'Dominican Priest, Theologian',
        isDoctor: true,
      );
      expect(categories, contains(SaintCategory.doctor));
      expect(categories, contains(SaintCategory.priest));
      expect(categories, contains(SaintCategory.mystic));
      expect(
        categories,
        equals(
          Saint.computeCategories(
            id: 'thomas-aquinas',
            name: 'St. Thomas Aquinas',
            nationality: 'Italian',
            profession: 'Dominican Priest, Theologian',
            isDoctor: true,
          ),
        ),
      );
    });
  });

  group('PrayersTab widget', () {
    Prayer makePrayer({
      required String id,
      required String title,
      String category = 'basic',
    }) {
      return Prayer.mock(
        id: id,
        defaultTitle: title,
        category: category,
        defaultOrder: 1,
        hasAmen: true,
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation(
              title: title,
              subtitle: 'Subtitle for $title',
              text: 'Prayer text for $title',
            ),
          ],
        },
      );
    }

    testWidgets(
      'filters liturgy prayers, supports search, and renders widescreen two-column list',
      (tester) async {
        bool cleared = false;
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final prayers = [
          makePrayer(id: 'our_father', title: 'Our Father'),
          makePrayer(id: 'hail_mary', title: 'Hail Mary'),
          makePrayer(
            id: 'mass_greeting',
            title: 'Mass Greeting',
            category: 'liturgy',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PrayersTab(
                prayers: prayers,
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: null,
                settings: null,
                fontSize: 16.0,
                searchQuery: '',
                onClearSearch: () => cleared = true,
                scrollController: controller,
                languageSelectorAnimation: const AlwaysStoppedAnimation(0.0),
                isWide: true,
              ),
            ),
          ),
        );

        expect(find.byType(TwoColumnSliverList), findsOneWidget);
        expect(find.text('Our Father'), findsOneWidget);
        expect(find.text('Hail Mary'), findsOneWidget);
        expect(find.text('Mass Greeting'), findsNothing);

        // Test empty search result and clear callback
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PrayersTab(
                prayers: prayers,
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: null,
                settings: null,
                fontSize: 16.0,
                searchQuery: 'nonexistent',
                onClearSearch: () => cleared = true,
                scrollController: controller,
                languageSelectorAnimation: const AlwaysStoppedAnimation(0.0),
                isWide: false,
              ),
            ),
          ),
        );

        expect(find.text('No prayers matching "nonexistent"'), findsOneWidget);
        await tester.tap(find.text('Clear search'));
        expect(cleared, isTrue);
      },
    );
  });

  group('Missal Ordinary Sections widgets', () {
    Prayer makeLiturgyPrayer(String id, String title) {
      return Prayer(
        prayerId: id,
        defaultTitle: title,
        category: 'liturgy',
        defaultOrder: 1,
        hasAmen: true,
      );
    }

    testWidgets(
      'MissalIntroductoryRitesSection, MissalLiturgyOfTheEucharistSection, and MissalConcludingRitesSection respect visibility',
      (tester) async {
        final greeting = makeLiturgyPrayer(
          'mass_greeting',
          'The Lord be with you',
        );
        final gloria = makeLiturgyPrayer('gloria', 'Gloria in Excelsis');
        final ourFather = makeLiturgyPrayer('our_father', 'Pater Noster');
        final dismissal = makeLiturgyPrayer('dismissal', 'Ite, missa est');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    MissalIntroductoryRitesSection(
                      isPrayerVisible: (id) => id != 'gloria',
                      buildPrayerCard: (p) => Text(p.defaultTitle),
                      massGreeting: greeting,
                      gloria: gloria,
                    ),
                    MissalLiturgyOfTheEucharistSection(
                      isPrayerVisible: (id) => true,
                      buildPrayerCard: (p) => Text(p.defaultTitle),
                      ourFather: ourFather,
                      onOpenAnimaChristi: (_, _) {},
                    ),
                    MissalConcludingRitesSection(
                      buildPrayerCard: (p) => Text(p.defaultTitle),
                      dismissal: dismissal,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('INTRODUCTORY RITES'), findsOneWidget);
        expect(find.text('The Lord be with you'), findsOneWidget);
        expect(find.text('Gloria in Excelsis'), findsNothing);
        expect(find.text('LITURGY OF THE EUCHARIST'), findsOneWidget);
        expect(find.text('Pater Noster'), findsOneWidget);
        expect(find.text('CONCLUDING RITES'), findsOneWidget);
        expect(find.text('Ite, missa est'), findsOneWidget);
      },
    );
  });
}
