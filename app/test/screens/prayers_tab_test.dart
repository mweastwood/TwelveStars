import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/screens/prayers_tab.dart';
import '../test_helper.dart';

void main() {
  group('PrayersTab Search', () {
    final testPrayers = <Prayer>[
      Prayer.mock(
        id: 'act_of_contrition',
        defaultTitle: 'Act of Contrition',
        category: 'basic',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation(
              title: 'Act of Contrition (Traditional)',
              subtitle: 'Traditional Form',
              text: 'O my God, I am heartily sorry for having offended Thee.',
            ),
            PrayerTranslation(
              title: 'Act of Contrition (Modern)',
              subtitle: 'Penitential Rite',
              text:
                  'My God, I am sorry for my sins with all my heart. In choosing to do wrong and failing to do good, I have sinned against you.',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation(
              title: 'Actus Contritionis',
              subtitle: 'Oratio Poenitentiae',
              text:
                  'Deus meus, ex toto corde paenitet me omnium meorum peccatorum.',
            ),
          ],
        },
      ),
      Prayer.mock(
        id: 'hail_mary',
        defaultTitle: 'Angelical Salutation',
        category: 'marian',
        translations: {
          PrayerLanguage.english: [
            PrayerTranslation(
              title: 'Hail Mary',
              subtitle: 'Ave Maria',
              text: 'Hail Mary, full of grace, the Lord is with thee.',
            ),
          ],
          PrayerLanguage.latin: [
            PrayerTranslation(
              title: 'Ave Maria',
              subtitle: 'Salutatio Angelica',
              text: 'Ave Maria, gratia plena, Dominus tecum.',
            ),
          ],
        },
      ),
    ];

    testWidgets(
      'matches search query against alternate prayer versions (v2) in primaryLanguage',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        final settings = UserSettings()
          ..setPreferredVersionIndex(
            'act_of_contrition_${PrayerLanguage.english.code}',
            1,
          );

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: PrayersTab(
                prayers: testPrayers,
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: null,
                settings: settings,
                fontSize: 16.0,
                searchQuery: 'choosing wrong',
                onClearSearch: () {},
                scrollController: controller,
                languageSelectorAnimation: const AlwaysStoppedAnimation(0.0),
                isWide: false,
              ),
            ),
          ),
        );

        expect(find.text('Act of Contrition (Modern)'), findsOneWidget);
        expect(find.text('Hail Mary'), findsNothing);
      },
    );

    testWidgets(
      'matches search query against active compareLanguage and defaultTitle',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        // 1. When compareLanguage is null, Latin-only word 'paenitet' does not match
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: PrayersTab(
                prayers: testPrayers,
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: null,
                settings: null,
                fontSize: 16.0,
                searchQuery: 'paenitet',
                onClearSearch: () {},
                scrollController: controller,
                languageSelectorAnimation: const AlwaysStoppedAnimation(0.0),
                isWide: false,
              ),
            ),
          ),
        );

        expect(find.textContaining('No prayers matching'), findsOneWidget);

        // 2. When compareLanguage is Latin, 'paenitet' matches Act of Contrition
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: PrayersTab(
                prayers: testPrayers,
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
                settings: null,
                fontSize: 16.0,
                searchQuery: 'paenitet',
                onClearSearch: () {},
                scrollController: controller,
                languageSelectorAnimation: const AlwaysStoppedAnimation(0.0),
                isWide: false,
              ),
            ),
          ),
        );

        expect(find.text('Act of Contrition (Traditional)'), findsOneWidget);
        expect(find.text('Actus Contritionis'), findsOneWidget);

        // 3. Searching by defaultTitle ('Angelical Salutation') matches Hail Mary
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: PrayersTab(
                prayers: testPrayers,
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: null,
                settings: null,
                fontSize: 16.0,
                searchQuery: 'angelical salutation',
                onClearSearch: () {},
                scrollController: controller,
                languageSelectorAnimation: const AlwaysStoppedAnimation(0.0),
                isWide: false,
              ),
            ),
          ),
        );

        expect(find.text('Hail Mary'), findsOneWidget);
      },
    );
  });
}
