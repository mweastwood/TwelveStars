import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/screens/bible_tab.dart';
import 'package:twelve_stars/screens/missal_tab.dart';
import 'package:twelve_stars/widgets/anima_christi_sheet.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_card.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import '../test_helper.dart';

void main() {
  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    PrayerDatabase.mockPrayers = null;
    PrayerDatabase.mockSettings = null;
    PrayerDatabase.resetCache();
    SaintDatabase.mockSaints = const [];
    SaintDatabase.resetCache();
    UserSettingsController.instance.resetForTesting();
  });

  tearDown(() async {
    PrayerDatabase.mockPrayers = null;
    PrayerDatabase.mockSettings = null;
    PrayerDatabase.resetCache();
    SaintDatabase.mockSaints = null;
    SaintDatabase.resetCache();
    UserSettingsController.instance.resetForTesting();
    await testDb.close();
    BibleDatabaseHelper.db = null;
  });

  group('UserSettingsStateMixin adoption', () {
    testWidgets(
      'BibleTab reactively updates on UserSettingsController mutation and unsubscribes on dispose',
      (tester) async {
        PrayerDatabase.mockSettings = UserSettings(
          showBibleTranslationSelectors: false,
          primaryBibleTranslation: 'CPDV',
        );

        await testDb
            .into(testDb.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText:
                    'In the beginning God created the heaven, and the earth.',
                translationCode: 'CPDV',
              ),
            );

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: BibleTab())),
        );
        await tester.pumpAndSettle();

        final state = tester.state<BibleTabState>(find.byType(BibleTab));
        expect(state.showTranslationSelectors, isFalse);

        // Mutate settings to expand the translation selector bar
        await UserSettingsController.instance.mutate((s) {
          s.showBibleTranslationSelectors = true;
          s.bibleNumberingSystem = BibleNumberingSystem.modern;
        });
        await tester.pumpAndSettle();

        expect(state.showTranslationSelectors, isTrue);
        expect(find.byType(BibleTranslationSelectorCard), findsOneWidget);

        // Unmount and verify subsequent mutations do not throw or trigger disposed state
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        await UserSettingsController.instance.mutate((s) {
          s.showBibleTranslationSelectors = false;
        });
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'MissalTab reactively updates on UserSettingsController mutation and unsubscribes on dispose',
      (tester) async {
        await tester.runAsync(() async {
          await testDb.ensurePopulated();
        });
        PrayerDatabase.mockSettings = UserSettings(
          primaryLanguageCode: 'english',
          missalReadingsOnly: false,
        );
        PrayerDatabase.mockPrayers = [
          Prayer.mock(
            id: 'confiteor',
            defaultTitle: 'Confiteor',
            translations: {
              PrayerLanguage.english: [
                PrayerTranslation.mock(
                  title: 'Confiteor',
                  text: 'I confess to almighty God...',
                  sourceName: 'Vatican',
                  sourceUrl: 'https://vatican.va',
                ),
              ],
            },
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: MissalTab(
                primaryLanguage: PrayerLanguage.english,
                initialDate: DateTime(2026, 5, 10),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially readings-only is false, so Confiteor prayer card is visible
        expect(
          find.textContaining('I confess to almighty God'),
          findsOneWidget,
        );

        // Mutate settings to readings-only mode
        await UserSettingsController.instance.mutate((s) {
          s.missalReadingsOnly = true;
        });
        await tester.pumpAndSettle();

        expect(find.textContaining('I confess to almighty God'), findsNothing);

        // Unmount and verify subsequent mutations do not throw
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        await UserSettingsController.instance.mutate((s) {
          s.missalReadingsOnly = false;
        });
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AnimaChristiSheet reactively updates on UserSettingsController mutation and unsubscribes on dispose',
      (tester) async {
        PrayerDatabase.mockSettings = UserSettings();

        final animaChristiPrayer = Prayer.mock(
          id: 'anima_christi',
          defaultTitle: 'Anima Christi',
          category: 'devotion',
          hasAmen: true,
          translations: {
            PrayerLanguage.english: [
              PrayerTranslation.mock(
                title: 'Anima Christi',
                subtitle: 'Soul of Christ',
                text: '{Soul of Christ, sanctify me.|anima_christi_1}',
                sourceName: 'Traditional',
                sourceUrl: 'https://vatican.va',
              ),
              PrayerTranslation.mock(
                title: 'Anima Christi (Alternative)',
                subtitle: 'Soul of Christ (Alt)',
                text: '{Soul of Christ, make me holy.|anima_christi_1}',
                sourceName: 'Traditional Alt',
                sourceUrl: 'https://vatican.va',
              ),
            ],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimaChristiSheet(
                prayer: animaChristiPrayer,
                primaryLanguage: PrayerLanguage.english,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        PrayerCard card = tester.widget<PrayerCard>(find.byType(PrayerCard));
        expect(card.initialVersionIndex, equals(0));

        // Mutate preferred version via UserSettingsController
        await UserSettingsController.instance.mutate((s) {
          s.setPreferredVersionIndex('anima_christi_english', 1);
        });
        await tester.pumpAndSettle();

        card = tester.widget<PrayerCard>(find.byType(PrayerCard));
        expect(card.initialVersionIndex, equals(1));

        // Unmount and verify subsequent mutations do not throw
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        await UserSettingsController.instance.mutate((s) {
          s.setPreferredVersionIndex('anima_christi_english', 0);
        });
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
