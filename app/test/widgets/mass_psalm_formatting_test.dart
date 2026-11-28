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
