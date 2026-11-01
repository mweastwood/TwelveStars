import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/reader/bible_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/widgets/mass_reading_card.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

import '../test_helper.dart';

void main() {
  late BibleDatabase testDb;

  setUp(() async {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;

    PrayerDatabase.mockPrayers = null;
    PrayerDatabase.mockSettings = null;
    UserSettingsController.instance.resetForTesting();

    await testDb.saveUserSettings(
      UserSettings(
        primaryBibleTranslation: 'CPDV',
        compareBibleTranslation: 'none',
      ),
    );
  });

  tearDown(() async {
    UserSettingsController.instance.resetForTesting();
    ReverseCitationService.clear();
    await testDb.close();
  });

  group('BibleReaderAdapter.formatPassageCitation', () {
    test(
      'formats single-verse and multi-verse citations across Vulgate, Modern, and Dual',
      () {
        // Single verse with divergent numbering (Vg Psalm 22:1 -> Modern 23:1)
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 22,
            startVerse: 1,
            endChapter: 22,
            endVerse: 1,
            numberingSystem: BibleNumberingSystem.vulgate,
          ),
          'Psalms 22:1',
        );
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 22,
            startVerse: 1,
            endChapter: 22,
            endVerse: 1,
            numberingSystem: BibleNumberingSystem.modern,
          ),
          'Psalms 23:1',
        );
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 22,
            startVerse: 1,
            endChapter: 22,
            endVerse: 1,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          'Psalms 22:1 (Modern 23:1)',
        );

        // Multi-verse range in single chapter
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 115,
            startVerse: 1,
            endChapter: 115,
            endVerse: 2,
            numberingSystem: BibleNumberingSystem.vulgate,
          ),
          'Psalms 115:1-2',
        );
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 115,
            startVerse: 1,
            endChapter: 115,
            endVerse: 2,
            numberingSystem: BibleNumberingSystem.modern,
          ),
          'Psalms 116:10-11',
        );
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 115,
            startVerse: 1,
            endChapter: 115,
            endVerse: 2,
            numberingSystem: BibleNumberingSystem.dual,
          ),
          'Psalms 115:1-2 (Modern 116:10-11)',
        );
      },
    );

    test(
      'formats cross-chapter citations with default and custom crossChapterSeparator across Vulgate, Modern, and Dual',
      () {
        // Identical numbering cross-chapter (Genesis 1:31 - 2:2)
        for (final system in BibleNumberingSystem.values) {
          expect(
            BibleReaderAdapter.formatPassageCitation(
              bookNumber: 1,
              bookName: 'Genesis',
              startChapter: 1,
              startVerse: 31,
              endChapter: 2,
              endVerse: 2,
              numberingSystem: system,
            ),
            'Genesis 1:31-2:2',
          );
          expect(
            BibleReaderAdapter.formatPassageCitation(
              bookNumber: 1,
              bookName: 'Genesis',
              startChapter: 1,
              startVerse: 31,
              endChapter: 2,
              endVerse: 2,
              numberingSystem: system,
              crossChapterSeparator: ' - ',
            ),
            'Genesis 1:31 - 2:2',
          );
        }

        // Divergent numbering cross-chapter (Vg Psalms 21:32 - 22:2 -> Modern 22:32 - 23:2)
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 21,
            startVerse: 32,
            endChapter: 22,
            endVerse: 2,
            numberingSystem: BibleNumberingSystem.vulgate,
            crossChapterSeparator: ' - ',
          ),
          'Psalms 21:32 - 22:2',
        );
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 21,
            startVerse: 32,
            endChapter: 22,
            endVerse: 2,
            numberingSystem: BibleNumberingSystem.modern,
            crossChapterSeparator: ' - ',
          ),
          'Psalms 22:32 - 23:2',
        );
        expect(
          BibleReaderAdapter.formatPassageCitation(
            bookNumber: 21,
            bookName: 'Psalms',
            startChapter: 21,
            startVerse: 32,
            endChapter: 22,
            endVerse: 2,
            numberingSystem: BibleNumberingSystem.dual,
            crossChapterSeparator: ' - ',
          ),
          'Psalms 21:32 - 22:2 (Modern 22:32 - 23:2)',
        );
      },
    );
  });

  group('BibleReaderAdapter.formatVersesForClipboard', () {
    const v1 = BibleVerse(
      id: 1,
      bookNumber: 21,
      bookName: 'Psalms',
      chapter: 115,
      verseNumber: 1,
      verseText: 'I have believed, therefore have I spoken.',
      translationCode: 'CPDV',
    );
    const v2 = BibleVerse(
      id: 2,
      bookNumber: 21,
      bookName: 'Psalms',
      chapter: 115,
      verseNumber: 2,
      verseText: 'I said in my excess: Every man is a liar.',
      translationCode: 'CPDV',
    );

    test('formats single-verse and multi-verse clipboard content', () {
      expect(
        BibleReaderAdapter.formatVersesForClipboard(
          citation: 'Psalms 115:1',
          verses: const [v1],
          numberingSystem: BibleNumberingSystem.vulgate,
        ),
        'Psalms 115:1\nI have believed, therefore have I spoken.',
      );

      expect(
        BibleReaderAdapter.formatVersesForClipboard(
          citation: 'Psalms 115:1-2',
          verses: const [v1, v2],
          numberingSystem: BibleNumberingSystem.vulgate,
        ),
        'Psalms 115:1-2\n'
        '1 I have believed, therefore have I spoken.\n'
        '2 I said in my excess: Every man is a liar.',
      );

      expect(
        BibleReaderAdapter.formatVersesForClipboard(
          citation: 'Psalms 116:10-11',
          verses: const [v1, v2],
          numberingSystem: BibleNumberingSystem.modern,
        ),
        'Psalms 116:10-11\n'
        '10 I have believed, therefore have I spoken.\n'
        '11 I said in my excess: Every man is a liar.',
      );

      expect(
        BibleReaderAdapter.formatVersesForClipboard(
          citation: 'Psalms 115:1-2 (Modern 116:10-11)',
          verses: const [v1, v2],
          numberingSystem: BibleNumberingSystem.dual,
        ),
        'Psalms 115:1-2 (Modern 116:10-11)\n'
        '1 (10) I have believed, therefore have I spoken.\n'
        '2 (11) I said in my excess: Every man is a liar.',
      );
    });
  });

  group(
    'BibleReaderAdapter multi-chapter favorite and comment loading helpers',
    () {
      test(
        'fetchFavoritesByNodeIdForChapters indexes favorites across multiple chapters and deduplicates chapter input',
        () async {
          await testDb.saveFavorite(
            FavoritePassagesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 1,
              startVerse: 30,
              endVerse: 31,
              textPreview: 'Genesis 1:30-31 preview',
            ),
          );
          await testDb.saveFavorite(
            FavoritePassagesCompanion.insert(
              bookNumber: 1,
              bookName: 'Genesis',
              chapter: 2,
              startVerse: 1,
              endVerse: 1,
              textPreview: 'Genesis 2:1 preview',
            ),
          );

          final byNodeId =
              await BibleReaderAdapter.fetchFavoritesByNodeIdForChapters(1, [
                1,
                2,
                1,
              ], dbHelper: testDb);

          expect(
            byNodeId.keys,
            unorderedEquals([
              ReaderNodeId.bibleVerse(1, 1, 30),
              ReaderNodeId.bibleVerse(1, 1, 31),
              ReaderNodeId.bibleVerse(1, 2, 1),
            ]),
          );
          expect(byNodeId['1_1_30'], hasLength(1));
          expect(byNodeId['1_1_31'], hasLength(1));
          expect(byNodeId['1_2_1'], hasLength(1));
          expect(byNodeId['1_2_1']!.first.textPreview, 'Genesis 2:1 preview');

          final emptyResult =
              await BibleReaderAdapter.fetchFavoritesByNodeIdForChapters(
                1,
                const [],
                dbHelper: testDb,
              );
          expect(emptyResult, isEmpty);
        },
      );

      test(
        'fetchCommentsByNodeIdForChapters loads comments for single, multiple, and empty chapters',
        () async {
          await testDb.saveComment(
            UserCommentsCompanion.insert(
              documentId: 'GEN',
              sectionIndex: 1,
              nodeId: '1_1_31',
              commentText: 'First comment on Gen 1:31',
              createdAt: DateTime(2026, 1, 1),
            ),
          );
          await testDb.saveComment(
            UserCommentsCompanion.insert(
              documentId: 'GEN',
              sectionIndex: 1,
              nodeId: '1_1_31',
              commentText: 'Second comment on Gen 1:31',
              createdAt: DateTime(2026, 1, 2),
            ),
          );
          await testDb.saveComment(
            UserCommentsCompanion.insert(
              documentId: 'GEN',
              sectionIndex: 2,
              nodeId: '1_2_1',
              commentText: 'Comment on Gen 2:1',
              createdAt: DateTime(2026, 1, 3),
            ),
          );

          // Single chapter path
          final singleCh =
              await BibleReaderAdapter.fetchCommentsByNodeIdForChapters('GEN', [
                1,
              ], dbHelper: testDb);
          expect(singleCh.keys, equals(['1_1_31']));
          expect(singleCh['1_1_31'], hasLength(2));

          // Multi-chapter path (with duplicate chapter to verify deduplication)
          final multiCh =
              await BibleReaderAdapter.fetchCommentsByNodeIdForChapters('GEN', [
                1,
                2,
                2,
              ], dbHelper: testDb);
          expect(multiCh.keys, unorderedEquals(['1_1_31', '1_2_1']));
          expect(multiCh['1_1_31'], hasLength(2));
          expect(multiCh['1_2_1'], hasLength(1));
          expect(multiCh['1_2_1']!.first.commentText, 'Comment on Gen 2:1');

          // Empty chapters path
          final emptyCh =
              await BibleReaderAdapter.fetchCommentsByNodeIdForChapters(
                'GEN',
                const [],
                dbHelper: testDb,
              );
          expect(emptyCh, isEmpty);
        },
      );
    },
  );

  group('MassReadingCard cross-chapter citation & clipboard delegation', () {
    testWidgets(
      'formats single-verse, multi-verse, and cross-chapter selections and copies to clipboard across Vulgate, Modern, and Dual',
      (WidgetTester tester) async {
        final List<Map<String, dynamic>> clipboardLog = [];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              clipboardLog.add(methodCall.arguments as Map<String, dynamic>);
              return null;
            }
            if (methodCall.method == 'Clipboard.getData') {
              return {
                'text': clipboardLog.isNotEmpty
                    ? clipboardLog.last['text']
                    : '',
              };
            }
            return null;
          },
        );

        const reading = LectionaryReading(
          id: 101,
          readingKey: 'cross_chapter_psalm_test',
          readingType: 'psalm',
          bookNumber: 21, // Psalms
          bookName: 'Psalms',
          chapter: 22,
          verseRange: '32; 23:1-2',
          citation: 'Psalms 22:32; 23:1-2',
        );

        // Seed Vulgate Psalms 21:32, 22:1, 22:2
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              const BibleVerse(
                id: 1,
                bookNumber: 21,
                bookName: 'Psalms',
                chapter: 21,
                verseNumber: 32,
                verseText: 'They shall come and declare his justice.',
                translationCode: 'CPDV',
              ),
            );
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              const BibleVerse(
                id: 2,
                bookNumber: 21,
                bookName: 'Psalms',
                chapter: 22,
                verseNumber: 1,
                verseText: 'The Lord ruleth me.',
                translationCode: 'CPDV',
              ),
            );
        await testDb
            .into(testDb.bibleVerses)
            .insert(
              const BibleVerse(
                id: 3,
                bookNumber: 21,
                bookName: 'Psalms',
                chapter: 22,
                verseNumber: 2,
                verseText: 'He hath set me in a place of pasture.',
                translationCode: 'CPDV',
              ),
            );

        // Also seed a favorite on 21:32 and a comment on 22:2 to verify multi-chapter annotations
        await testDb.saveFavorite(
          FavoritePassagesCompanion.insert(
            bookNumber: 21,
            bookName: 'Psalms',
            chapter: 21,
            startVerse: 32,
            endVerse: 32,
            textPreview: 'They shall come and declare his justice.',
          ),
        );
        await testDb.saveComment(
          UserCommentsCompanion.insert(
            documentId: 'PSA',
            sectionIndex: 22,
            nodeId: '21_22_2',
            commentText: 'Place of pasture note',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(body: MassReadingCard(reading: reading)),
          ),
        );
        await tester.pumpAndSettle();

        // Verify multi-chapter favorite & comment badges loaded via shared helpers
        expect(find.byIcon(Icons.star_rounded), findsOneWidget);
        expect(find.byIcon(Icons.comment_rounded), findsOneWidget);

        // 1. Vulgate numbering: cross-chapter selection (21:32 to 22:2)
        await tester.longPress(
          find.text('They shall come and declare his justice.'),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(ReaderSelectionActionBar),
            matching: find.text('Psalms 21:32'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('He hath set me in a place of pasture.'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(ReaderSelectionActionBar),
            matching: find.text('Psalms 21:32 - 22:2'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Copy selection'));
        await tester.pumpAndSettle();

        var clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        expect(
          clipboardData?.text,
          'Psalms 21:32 - 22:2\n'
          '32 They shall come and declare his justice.\n'
          '1 The Lord ruleth me.\n'
          '2 He hath set me in a place of pasture.',
        );

        // 2. Modern numbering: cross-chapter selection
        await UserSettingsController.instance.mutate((s) {
          s.bibleNumberingSystem = BibleNumberingSystem.modern;
        });
        await tester.pumpAndSettle();

        await tester.longPress(
          find.text('They shall come and declare his justice.'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('He hath set me in a place of pasture.'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(ReaderSelectionActionBar),
            matching: find.text('Psalms 22:32 - 23:2'),
          ),
          findsOneWidget,
        );

        // 3. Dual numbering: cross-chapter selection & copy
        await UserSettingsController.instance.mutate((s) {
          s.bibleNumberingSystem = BibleNumberingSystem.dual;
        });
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(ReaderSelectionActionBar),
            matching: find.text('Psalms 21:32 - 22:2 (Modern 22:32 - 23:2)'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Copy selection'));
        await tester.pumpAndSettle();

        clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        expect(
          clipboardData?.text,
          'Psalms 21:32 - 22:2 (Modern 22:32 - 23:2)\n'
          '32 They shall come and declare his justice.\n'
          '1 The Lord ruleth me.\n'
          '2 He hath set me in a place of pasture.',
        );
      },
    );
  });
}
