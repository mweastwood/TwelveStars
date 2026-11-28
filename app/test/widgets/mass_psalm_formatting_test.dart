import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/psalm_response_service.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/mass_reading_card.dart';
import 'package:twelve_stars/widgets/reader/mass_psalm_widgets.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';
import '../test_helper.dart' hide materialAppWrapper;

WidgetWrapper materialAppWrapper({
  TargetPlatform platform = TargetPlatform.android,
  ThemeData? theme,
}) {
  return (Widget child) => MaterialApp(
    theme: (theme ?? ThemeData()).copyWith(platform: platform),
    debugShowCheckedModeBanner: false,
    home: Material(child: child),
  );
}

void main() {
  late BibleDatabase testDb;

  setUp(() async {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;

    PrayerDatabase.mockPrayers = null;
    PrayerDatabase.mockSettings = null;
    UserSettingsController.instance.resetForTesting();
    PsalmResponseService.clear();

    await testDb.saveUserSettings(
      UserSettings(
        primaryBibleTranslation: 'CPDV',
        compareBibleTranslation: 'none',
        bibleNumberingSystemCode: 'modern',
      ),
    );
  });

  tearDown(() async {
    UserSettingsController.instance.resetForTesting();
    ReverseCitationService.clear();
    PsalmResponseService.clear();
    await testDb.close();
  });

  Future<void> insertPsalm95Verses() async {
    // Modern Psalm 95 maps to Vulgate Psalm 94
    const verses = [
      (
        1,
        'Come, let us exult in the Lord. Let us shout joyfully to God, our Savior.',
      ),
      (
        2,
        'Let us anticipate his presence with confession, and let us sing joyfully to him with psalms.',
      ),
      (3, 'For the Lord is a great God and a great King over all gods.'),
      (
        4,
        'For in his hand are all the ends of the earth, and the heights of the mountains are his.',
      ),
      (
        5,
        'For the sea is his, and he made it, and his hands formed the dry land.',
      ),
      (
        6,
        'Come, let us adore and fall down, and weep before the Lord who made us.',
      ),
      (
        7,
        'For he is the Lord our God, and we are the people of his pasture and the sheep of his hand.',
      ),
      (8, 'If today you hear his voice, harden not your hearts:'),
    ];
    for (final (num, text) in verses) {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            BibleVerse(
              id: 100 + num,
              bookNumber: 21,
              bookName: 'Psalms',
              chapter: 94,
              verseNumber: num,
              verseText: text,
              translationCode: 'CPDV',
            ),
          );
    }
  }

  testWidgets(
    'Responsorial Psalm renders highlighted R. banner, grouped stanzas, and compact R. cues',
    (WidgetTester tester) async {
      await insertPsalm95Verses();
      PsalmResponseService.setEntriesForTesting({
        'season_ordinary_time_34_saturday_2': const PsalmResponseSpec(
          verseRef: '8',
        ),
      });

      const reading = LectionaryReading(
        id: 10,
        readingKey: 'season_ordinary_time_34_saturday_2',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 95,
        verseRange: '1-2, 3-5, 6-7ab',
        citation: 'Psalm 95:1-2, 3-5, 6-7ab',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MassReadingCard(reading: reading),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Highlighted R. banner at top showing verse 8 (outside stanza range 1-7)
      expect(find.byType(MassPsalmResponseBanner), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MassPsalmResponseBanner),
          matching: find.textContaining(
            'If today you hear his voice, harden not your hearts:',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(MassPsalmResponseBanner),
          matching: find.text('Psalms 95:8'),
        ),
        findsOneWidget,
      );

      // 7 interactive verse rows grouped into 3 stanzas with 3 compact R. cues
      expect(find.byType(BibleVerseRow), findsNWidgets(7));
      expect(find.byType(MassPsalmRefrainCue), findsNWidgets(3));

      // Verify stanza ordering: cue 0 appears between verse 2 and verse 3,
      // cue 1 between verse 5 and verse 6, and cue 2 after verse 7.
      final v2Y = tester.getTopLeft(find.byType(BibleVerseRow).at(1)).dy;
      final cue0Y = tester
          .getTopLeft(find.byType(MassPsalmRefrainCue).at(0))
          .dy;
      final v3Y = tester.getTopLeft(find.byType(BibleVerseRow).at(2)).dy;
      final v5Y = tester.getTopLeft(find.byType(BibleVerseRow).at(4)).dy;
      final cue1Y = tester
          .getTopLeft(find.byType(MassPsalmRefrainCue).at(1))
          .dy;
      final v6Y = tester.getTopLeft(find.byType(BibleVerseRow).at(5)).dy;
      final v7Y = tester.getTopLeft(find.byType(BibleVerseRow).at(6)).dy;
      final cue2Y = tester
          .getTopLeft(find.byType(MassPsalmRefrainCue).at(2))
          .dy;

      expect(cue0Y, greaterThan(v2Y));
      expect(cue0Y, lessThan(v3Y));
      expect(cue1Y, greaterThan(v5Y));
      expect(cue1Y, lessThan(v6Y));
      expect(cue2Y, greaterThan(v7Y));
    },
  );

  testWidgets(
    'Response overlapping stanza stays in stanza, shared boundary half-verse repeats in both stanzas, and selection deduplicates on copy',
    (WidgetTester tester) async {
      final List<Map<String, dynamic>> clipboardLog = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardLog.add(
              Map<String, dynamic>.from(methodCall.arguments as Map),
            );
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return {
              'text': clipboardLog.isNotEmpty ? clipboardLog.last['text'] : '',
            };
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      // Modern Psalm 23 -> Vulgate Psalm 22
      const verses = [
        (1, 'The Lord directs me, and nothing will be lacking to me.'),
        (2, 'He has placed me in a place of pasture.'),
        (
          3,
          'He has converted my soul. He has led me along the paths of justice.',
        ),
        (
          4,
          'For even if I should walk in the midst of the shadow of death, I will not fear evils.',
        ),
      ];
      for (final (num, text) in verses) {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVerse(
                id: 200 + num,
                bookNumber: 21,
                bookName: 'Psalms',
                chapter: 22,
                verseNumber: num,
                verseText: text,
                translationCode: 'CPDV',
              ),
            );
      }

      PsalmResponseService.setEntriesForTesting({
        'psalm_23_overlap_test': const PsalmResponseSpec(verseRef: '1'),
      });

      const reading = LectionaryReading(
        id: 11,
        readingKey: 'psalm_23_overlap_test',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 23,
        verseRange: '1-3a, 3b-4',
        citation: 'Psalm 23:1-3a, 3b-4',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MassReadingCard(reading: reading),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top R. banner has verse 1
      expect(find.byType(MassPsalmResponseBanner), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MassPsalmResponseBanner),
          matching: find.textContaining(
            'The Lord directs me, and nothing will be lacking to me.',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );

      // Stanza 1 has [1, 2, 3], Stanza 2 has [3, 4] -> 5 BibleVerseRow widgets total
      expect(find.byType(BibleVerseRow), findsNWidgets(5));
      expect(find.byType(MassPsalmRefrainCue), findsNWidgets(2));

      // Verse 1 is still intact in Stanza 1
      expect(
        find.descendant(
          of: find.byType(BibleVerseRow).at(0),
          matching: find.text(
            'The Lord directs me, and nothing will be lacking to me.',
          ),
        ),
        findsOneWidget,
      );
      // Shared boundary verse 3 appears in Stanza 1 (index 2) AND Stanza 2 (index 3)
      expect(
        find.descendant(
          of: find.byType(BibleVerseRow).at(2),
          matching: find.text(
            'He has converted my soul. He has led me along the paths of justice.',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BibleVerseRow).at(3),
          matching: find.text(
            'He has converted my soul. He has led me along the paths of justice.',
          ),
        ),
        findsOneWidget,
      );

      // Select across the repeated boundary verse (index 2 through index 4 -> verses 3 & 4)
      await tester.longPress(find.byType(BibleVerseRow).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BibleVerseRow).at(4));
      await tester.pumpAndSettle();

      // Action bar reports deduplicated citation and count (2 verses: 3 and 4)
      expect(
        find.descendant(
          of: find.byType(ReaderSelectionActionBar),
          matching: find.text('Psalms 23:3-4'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Copy selection'));
      await tester.pumpAndSettle();
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      expect(
        clip?.text,
        'Psalms 23:3-4\n'
        '3 He has converted my soul. He has led me along the paths of justice.\n'
        '4 For even if I should walk in the midst of the shadow of death, I will not fear evils.',
      );
    },
  );

  testWidgets(
    'Eastertide psalm shows optional localized Alleluia and Easter Vigil shows pure Alleluia',
    (WidgetTester tester) async {
      // Modern Psalm 118 -> Vulgate Psalm 117
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 301,
              bookNumber: 21,
              bookName: 'Psalms',
              chapter: 117,
              verseNumber: 1,
              verseText: 'Confess to the Lord, for he is good.',
              translationCode: 'CPDV',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 324,
              bookNumber: 21,
              bookName: 'Psalms',
              chapter: 117,
              verseNumber: 24,
              verseText: 'This is the day that the Lord has made.',
              translationCode: 'CPDV',
            ),
          );

      PsalmResponseService.setEntriesForTesting({
        'season_easter_sunday': const PsalmResponseSpec(
          verseRef: '24',
          allowAlleluia: true,
        ),
        'triduum_holy_saturday': const PsalmResponseSpec(isAlleluia: true),
      });

      // 1. Easter Sunday with bilingual compareLanguage (Latin)
      const easterSunday = LectionaryReading(
        id: 12,
        readingKey: 'season_easter_sunday',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 118,
        verseRange: '1',
        citation: 'Psalm 118:1',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: MassReadingCard(
              reading: easterSunday,
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'This is the day that the Lord has made.',
          findRichText: true,
        ),
        findsWidgets,
      );
      expect(
        find.textContaining('or: Alleluia.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('vel: Allelúia.', findRichText: true),
        findsOneWidget,
      );

      // 2. Easter Vigil (pure Alleluia)
      const easterVigil = LectionaryReading(
        id: 13,
        readingKey: 'triduum_holy_saturday',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 118,
        verseRange: '1',
        citation: 'Psalm 118:1',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: MassReadingCard(
              reading: easterVigil,
              primaryLanguage: PrayerLanguage.english,
              compareLanguage: PrayerLanguage.latin,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(MassPsalmResponseBanner),
          matching: find.textContaining('Alleluia.', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(MassPsalmResponseBanner),
          matching: find.textContaining('Allelúia.', findRichText: true),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Cross-book response (1 Cor 10:16) resolves cleanly and falls back to CPDV when translation is OT-only (LXX)',
    (WidgetTester tester) async {
      await testDb.saveUserSettings(
        UserSettings(
          primaryBibleTranslation: 'LXX',
          compareBibleTranslation: 'none',
          bibleNumberingSystemCode: 'modern',
        ),
      );
      // Modern Psalm 116:12 -> Vulgate Psalm 115:3 in LXX
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 401,
              bookNumber: 21,
              bookName: 'Psalms',
              chapter: 115,
              verseNumber: 3,
              verseText: 'Τί ἀνταποδώσω τῷ Κυρίῳ',
              translationCode: 'LXX',
            ),
          );
      // 1 Corinthians 10:16 in CPDV (fallback for OT-only LXX)
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 402,
              bookNumber: 55,
              bookName: '1 Corinthians',
              chapter: 10,
              verseNumber: 16,
              verseText:
                  'The cup of benediction that we bless, is it not a communion in the Blood of Christ?',
              translationCode: 'CPDV',
            ),
          );

      PsalmResponseService.setEntriesForTesting({
        'triduum_holy_thursday': const PsalmResponseSpec(
          bookNumber: 55,
          chapter: 10,
          verseRef: '16',
        ),
      });

      const reading = LectionaryReading(
        id: 14,
        readingKey: 'triduum_holy_thursday',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 116,
        verseRange: '12',
        citation: 'Psalm 116:12',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(body: MassReadingCard(reading: reading)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MassPsalmResponseBanner), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MassPsalmResponseBanner),
          matching: find.textContaining(
            'The cup of benediction that we bless',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(MassPsalmResponseBanner),
          matching: find.text('1 Corinthians 10:16'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Non-monotonic psalm (Ps 136:1 and 23-24, 10-12) produces non-inverted citation and contiguous FavoritePassages without unselected gaps',
    (WidgetTester tester) async {
      final List<Map<String, dynamic>> clipboardLog = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardLog.add(
              Map<String, dynamic>.from(methodCall.arguments as Map),
            );
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return {
              'text': clipboardLog.isNotEmpty ? clipboardLog.last['text'] : '',
            };
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      // Modern Psalm 136 -> Vulgate Psalm 135
      const verses = [
        (1, 'Confess to the Lord, for he is good: for his mercy is eternal.'),
        (
          10,
          'Who struck Egypt with their firstborn: for his mercy is eternal.',
        ),
        (11, 'Who led Israel out from their midst: for his mercy is eternal.'),
        (
          12,
          'With a mighty hand and an outstretched arm: for his mercy is eternal.',
        ),
        (
          23,
          'For he was mindful of us in our humiliation: for his mercy is eternal.',
        ),
        (24, 'And he redeemed us from our enemies: for his mercy is eternal.'),
      ];
      for (final (num, text) in verses) {
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVerse(
                id: 500 + num,
                bookNumber: 21,
                bookName: 'Psalms',
                chapter: 135,
                verseNumber: num,
                verseText: text,
                translationCode: 'CPDV',
              ),
            );
      }

      PsalmResponseService.setEntriesForTesting({
        'season_ordinary_time_15_saturday_1': const PsalmResponseSpec(
          verseRef: '1',
        ),
      });

      const reading = LectionaryReading(
        id: 15,
        readingKey: 'season_ordinary_time_15_saturday_1',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 136,
        verseRange: '1 and 23-24, 10-12',
        citation: 'Psalm 136:1 and 23-24, 10-12',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MassReadingCard(reading: reading),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Liturgical order: index 0=v1, 1=v23, 2=v24, 3=v10, 4=v11, 5=v12
      expect(find.byType(BibleVerseRow), findsNWidgets(6));

      // Select from v23 (index 1) through v10 (index 3) -> {v10, v23, v24}
      await tester.longPress(find.byType(BibleVerseRow).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BibleVerseRow).at(3));
      await tester.pumpAndSettle();

      // Citation must NOT be inverted ("23-10"); it sorts and formats disjoint runs
      expect(
        find.descendant(
          of: find.byType(ReaderSelectionActionBar),
          matching: find.text('Psalms 136:10, 23-24'),
        ),
        findsOneWidget,
      );

      // Save favorite: must create 2 valid contiguous rows (10-10 and 23-24), never startVerse > endVerse or gaps
      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      final favs = await testDb.getFavorites();
      expect(favs, hasLength(2));
      expect(favs[0].startVerse, 10);
      expect(favs[0].endVerse, 10);
      expect(favs[1].startVerse, 23);
      expect(favs[1].endVerse, 24);
    },
  );

  testWidgets(
    'Eastertide psalm falls back to pure Alleluia when response verse is absent in active translation (e.g. VUL Ps 15:11)',
    (WidgetTester tester) async {
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 601,
              bookNumber: 21,
              bookName: 'Psalms',
              chapter: 15,
              verseNumber: 1,
              verseText: 'Conserva me, Domine, quoniam speravi in te.',
              translationCode: 'CPDV',
            ),
          );

      // Response ref v.11 is intentionally absent from testDb
      PsalmResponseService.setEntriesForTesting({
        'season_easter_3_sunday_a': const PsalmResponseSpec(
          verseRef: '11',
          allowAlleluia: true,
        ),
      });

      const reading = LectionaryReading(
        id: 16,
        readingKey: 'season_easter_3_sunday_a',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 16,
        verseRange: '1',
        citation: 'Psalm 16:1',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: MassReadingCard(
              reading: reading,
              primaryLanguage: PrayerLanguage.latin,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MassPsalmResponseBanner), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MassPsalmResponseBanner),
          matching: find.textContaining('Allelúia.', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(find.byType(MassPsalmRefrainCue), findsOneWidget);
    },
  );

  testWidgets(
    'Response banner reacts to numbering system changes, disjoint response refs, translation switches, and reading transitions',
    (WidgetTester tester) async {
      await insertPsalm95Verses();
      // Add DRC verse 8 and verse 1 for translation switch test
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 701,
              bookNumber: 21,
              bookName: 'Psalms',
              chapter: 94,
              verseNumber: 1,
              verseText: 'Come let us praise the Lord with joy.',
              translationCode: 'DRC',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 708,
              bookNumber: 21,
              bookName: 'Psalms',
              chapter: 94,
              verseNumber: 8,
              verseText:
                  'To day if you shall hear his voice, harden not your hearts.',
              translationCode: 'DRC',
            ),
          );
      await testDb
          .into(testDb.bibleVerses)
          .insert(
            const BibleVerse(
              id: 750,
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              verseNumber: 1,
              verseText: 'In the beginning God created heaven and earth.',
              translationCode: 'DRC',
            ),
          );

      // Disjoint response ref ("2, 8") should render "Psalms 95:2, 8" (not "95:2-8")
      PsalmResponseService.setEntriesForTesting({
        'psalm_95_disjoint_test': const PsalmResponseSpec(verseRef: '2, 8'),
        'psalm_95_single_test': const PsalmResponseSpec(verseRef: '8'),
      });

      const disjointPsalm = LectionaryReading(
        id: 17,
        readingKey: 'psalm_95_disjoint_test',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 95,
        verseRange: '1-2, 3-5',
        citation: 'Psalm 95:1-2, 3-5',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MassReadingCard(reading: disjointPsalm),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Modern numbering with disjoint refs
      expect(
        find.descendant(
          of: find.byType(MassPsalmResponseBanner),
          matching: find.text('Psalms 95:2, 8'),
        ),
        findsOneWidget,
      );

      // Switch to single-verse psalm & cycle numbering: modern -> vulgate -> dual
      const singlePsalm = LectionaryReading(
        id: 18,
        readingKey: 'psalm_95_single_test',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 95,
        verseRange: '1',
        citation: 'Psalm 95:1',
      );
      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MassReadingCard(reading: singlePsalm),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Psalms 95:8'), findsOneWidget);

      await UserSettingsController.instance.mutate((s) {
        s.bibleNumberingSystem = BibleNumberingSystem.vulgate;
      });
      await tester.pumpAndSettle();
      expect(find.text('Psalms 94:8'), findsOneWidget);

      await UserSettingsController.instance.mutate((s) {
        s.bibleNumberingSystem = BibleNumberingSystem.dual;
      });
      await tester.pumpAndSettle();
      expect(find.text('Psalms 94:8 (Modern 95:8)'), findsOneWidget);

      // Switch Bible translation CPDV -> DRC: response banner updates to DRC wording
      await UserSettingsController.instance.mutate((s) {
        s.primaryBibleTranslation = 'DRC';
      });
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(MassPsalmResponseBanner),
          matching: find.textContaining(
            'To day if you shall hear his voice, harden not your hearts.',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );

      // Transition via didUpdateWidget from Psalm to a non-Psalm reading: banner clears
      const firstReading = LectionaryReading(
        id: 19,
        readingKey: 'non_psalm_transition_test',
        readingType: 'first',
        bookNumber: 1,
        bookName: 'Genesis',
        chapter: 1,
        verseRange: '1',
        citation: 'Genesis 1:1',
      );
      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MassReadingCard(reading: firstReading),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MassPsalmResponseBanner), findsNothing);
      expect(find.byType(MassPsalmRefrainCue), findsNothing);
    },
  );

  testWidgets(
    'Psalm without a response spec still renders grouped stanzas cleanly without banner or R. cues',
    (WidgetTester tester) async {
      await insertPsalm95Verses();
      PsalmResponseService.setEmptyForTesting();

      const reading = LectionaryReading(
        id: 20,
        readingKey: 'unknown_psalm_no_spec',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 95,
        verseRange: '1-2, 3-5',
        citation: 'Psalm 95:1-2, 3-5',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MassReadingCard(reading: reading),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MassPsalmResponseBanner), findsNothing);
      expect(find.byType(MassPsalmRefrainCue), findsNothing);
      expect(find.byType(BibleVerseRow), findsNWidgets(5));

      // Verify stanza gap exists between v2 (index 1) and v3 (index 2)
      final v1Bottom = tester
          .getBottomLeft(find.byType(BibleVerseRow).at(0))
          .dy;
      final v2Top = tester.getTopLeft(find.byType(BibleVerseRow).at(1)).dy;
      final v2Bottom = tester
          .getBottomLeft(find.byType(BibleVerseRow).at(1))
          .dy;
      final v3Top = tester.getTopLeft(find.byType(BibleVerseRow).at(2)).dy;
      expect(v3Top - v2Bottom, greaterThan(v2Top - v1Bottom));
    },
  );

  testGoldens(
    'Responsorial Psalm card renders highlighted R. banner and grouped stanzas golden',
    (tester) async {
      await insertPsalm95Verses();
      PsalmResponseService.setEntriesForTesting({
        'season_ordinary_time_34_saturday_2': const PsalmResponseSpec(
          verseRef: '8',
        ),
      });

      const reading = LectionaryReading(
        id: 10,
        readingKey: 'season_ordinary_time_34_saturday_2',
        readingType: 'psalm',
        bookNumber: 21,
        bookName: 'Psalms',
        chapter: 95,
        verseRange: '1-2, 3-5, 6-7ab',
        citation: 'Psalm 95:1-2, 3-5, 6-7ab',
      );

      final builder = GoldenBuilder.column()
        ..addScenario(
          'Responsorial Psalm with R. Banner & Stanzas',
          const MassReadingCard(reading: reading),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(450, 960),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'mass_reading_card_responsorial_psalm_golden',
      );
    },
  );
}
