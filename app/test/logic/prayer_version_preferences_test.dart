import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/rosary_helper.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/screens/prayers_tab.dart';
import 'package:twelve_stars/screens/rosary_screen.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/widgets/rosary_bead_chain.dart';
import '../test_helper.dart';

List<Prayer> _buildMultiVersionRosaryPrayers() {
  List<PrayerTranslation> versionsFor(String baseTitle) => [
    PrayerTranslation(
      title: '$baseTitle (v1)',
      subtitle: 'Traditional',
      text: '$baseTitle text version 1.',
    ),
    PrayerTranslation(
      title: '$baseTitle (v2)',
      subtitle: 'Modern',
      text: '$baseTitle text version 2.',
    ),
  ];

  return [
    Prayer.mock(
      id: 'sign_of_the_cross',
      defaultTitle: 'Sign of the Cross',
      translations: {
        PrayerLanguage.english: versionsFor('Sign of the Cross'),
        PrayerLanguage.latin: versionsFor('Signum Crucis'),
      },
    ),
    Prayer.mock(
      id: 'apostles_creed',
      defaultTitle: 'Apostles\' Creed',
      translations: {PrayerLanguage.english: versionsFor('Apostles\' Creed')},
    ),
    Prayer.mock(
      id: 'our_father',
      defaultTitle: 'Our Father',
      translations: {PrayerLanguage.english: versionsFor('Our Father')},
    ),
    Prayer.mock(
      id: 'hail_mary',
      defaultTitle: 'Hail Mary',
      translations: {PrayerLanguage.english: versionsFor('Hail Mary')},
    ),
    Prayer.mock(
      id: 'glory_be',
      defaultTitle: 'Glory Be',
      translations: {PrayerLanguage.english: versionsFor('Glory Be')},
    ),
    Prayer.mock(
      id: 'fatima_prayer',
      defaultTitle: 'Fatima Prayer',
      translations: {PrayerLanguage.english: versionsFor('Fatima Prayer')},
    ),
    Prayer.mock(
      id: 'hail_holy_queen',
      defaultTitle: 'Hail Holy Queen',
      translations: {PrayerLanguage.english: versionsFor('Hail Holy Queen')},
    ),
    Prayer.mock(
      id: 'final_prayer_rosary',
      defaultTitle: 'Final Prayer',
      translations: {PrayerLanguage.english: versionsFor('Final Prayer')},
    ),
  ];
}

void main() {
  setUp(() {
    PrayerDatabase.mockSettings = null;
    UserSettingsController.instance.resetForTesting();
  });

  tearDown(() {
    PrayerDatabase.mockSettings = null;
    UserSettingsController.instance.resetForTesting();
  });

  group('UserSettings prayer version helpers', () {
    test(
      'prayerVersionKey formats prayerId and language code consistently',
      () {
        expect(
          UserSettings.prayerVersionKey(
            'sign_of_the_cross',
            PrayerLanguage.english,
          ),
          equals('sign_of_the_cross_english'),
        );
        expect(
          UserSettings.prayerVersionKey('hail_mary', PrayerLanguage.latin),
          equals('hail_mary_latin'),
        );
        expect(
          UserSettings.prayerVersionKey(
            'our_father',
            PrayerLanguage.traditionalChinese,
          ),
          equals('our_father_traditionalChinese'),
        );
      },
    );

    test(
      'getPrayerVersionIndex and setPrayerVersionIndex read and update per-language preferences',
      () {
        final settings = UserSettings();

        expect(
          settings.getPrayerVersionIndex(
            'act_of_contrition',
            PrayerLanguage.english,
          ),
          equals(0),
        );

        settings.setPrayerVersionIndex(
          'act_of_contrition',
          PrayerLanguage.english,
          1,
        );
        settings.setPrayerVersionIndex(
          'act_of_contrition',
          PrayerLanguage.latin,
          2,
        );

        expect(
          settings.getPrayerVersionIndex(
            'act_of_contrition',
            PrayerLanguage.english,
          ),
          equals(1),
        );
        expect(
          settings.getPrayerVersionIndex(
            'act_of_contrition',
            PrayerLanguage.latin,
          ),
          equals(2),
        );
        expect(
          settings.getPreferredVersionIndex('act_of_contrition_english'),
          equals(1),
        );

        // Overwrite existing entry in place without duplicating keys
        settings.setPrayerVersionIndex(
          'act_of_contrition',
          PrayerLanguage.english,
          3,
        );
        expect(
          settings.getPrayerVersionIndex(
            'act_of_contrition',
            PrayerLanguage.english,
          ),
          equals(3),
        );
        expect(
          settings.preferredVersions
              ?.where((p) => p.key == 'act_of_contrition_english')
              .length,
          equals(1),
        );
      },
    );

    test(
      'UserSettingsController.savePrayerVersionIndex mutates and persists preference',
      () async {
        final initialSettings = UserSettings();
        PrayerDatabase.mockSettings = initialSettings;

        int notificationCount = 0;
        void listener() => notificationCount++;
        UserSettingsController.instance.addListener(listener);
        addTearDown(
          () => UserSettingsController.instance.removeListener(listener),
        );

        await UserSettingsController.instance.savePrayerVersionIndex(
          'hail_holy_queen',
          PrayerLanguage.english,
          1,
        );

        expect(notificationCount, greaterThanOrEqualTo(1));
        expect(
          UserSettingsController.instance.value.getPrayerVersionIndex(
            'hail_holy_queen',
            PrayerLanguage.english,
          ),
          equals(1),
        );
        expect(
          PrayerDatabase.mockSettings?.getPrayerVersionIndex(
            'hail_holy_queen',
            PrayerLanguage.english,
          ),
          equals(1),
        );
      },
    );
  });

  group('RosaryScreen & PrayersTab prayer version persistence', () {
    testWidgets(
      'RosaryScreen loads and persists version changes across primary, secondary, and tertiary step prayers',
      (tester) async {
        final prayers = _buildMultiVersionRosaryPrayers();
        final settings = UserSettings()
          ..setPrayerVersionIndex('hail_holy_queen', PrayerLanguage.english, 1);
        PrayerDatabase.mockSettings = settings;
        await UserSettingsController.instance.update(settings);

        await tester.pumpWidget(
          buildTestableWidget(
            child: RosaryScreen(
              prayers: prayers,
              primaryLanguage: PrayerLanguage.english,
              initialDate: DateTime(2026, 7, 6), // Monday (Joyful)
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Step 0 has primary (sign_of_the_cross) and secondary (apostles_creed)
        var cards = tester
            .widgetList<PrayerCard>(find.byType(PrayerCard))
            .toList();
        expect(cards, hasLength(2));
        expect(cards[0].prayer.prayerId, equals('sign_of_the_cross'));
        expect(cards[0].initialVersionIndex, equals(0));
        expect(cards[1].prayer.prayerId, equals('apostles_creed'));
        expect(cards[1].initialVersionIndex, equals(0));

        // Update secondary prayer version on Step 0 via onVersionChanged
        cards[1].onVersionChanged(1);
        await tester.pumpAndSettle();

        expect(
          UserSettingsController.instance.value.getPrayerVersionIndex(
            'apostles_creed',
            PrayerLanguage.english,
          ),
          equals(1),
        );

        // Jump to final step (Closing Prayers) which has primary, secondary, and tertiary prayers:
        // 1: hail_holy_queen, 2: final_prayer_rosary, 3: sign_of_the_cross
        final steps = RosaryHelper.generateSteps(RosaryMysteryType.joyful);
        final beadChain = tester.widget<RosaryBeadChain>(
          find.byType(RosaryBeadChain),
        );
        beadChain.onStepSelected(steps.length - 1);
        await tester.pumpAndSettle();

        cards = tester.widgetList<PrayerCard>(find.byType(PrayerCard)).toList();
        expect(cards, hasLength(3));
        expect(cards[0].prayer.prayerId, equals('hail_holy_queen'));
        expect(cards[0].initialVersionIndex, equals(1)); // pre-seeded
        expect(cards[1].prayer.prayerId, equals('final_prayer_rosary'));
        expect(cards[1].initialVersionIndex, equals(0));
        expect(cards[2].prayer.prayerId, equals('sign_of_the_cross'));
        expect(cards[2].initialVersionIndex, equals(0));

        // Change primary, secondary, and tertiary versions on the closing step
        cards[0].onVersionChanged(0);
        cards[1].onVersionChanged(1);
        cards[2].onVersionChanged(1);
        await tester.pumpAndSettle();

        final persisted = UserSettingsController.instance.value;
        expect(
          persisted.getPrayerVersionIndex(
            'hail_holy_queen',
            PrayerLanguage.english,
          ),
          equals(0),
        );
        expect(
          persisted.getPrayerVersionIndex(
            'final_prayer_rosary',
            PrayerLanguage.english,
          ),
          equals(1),
        );
        expect(
          persisted.getPrayerVersionIndex(
            'sign_of_the_cross',
            PrayerLanguage.english,
          ),
          equals(1),
        );

        // Navigate back to Step 0 and verify sign_of_the_cross reflects the updated version 1
        beadChain.onStepSelected(0);
        await tester.pumpAndSettle();

        cards = tester.widgetList<PrayerCard>(find.byType(PrayerCard)).toList();
        expect(cards[0].prayer.prayerId, equals('sign_of_the_cross'));
        expect(cards[0].initialVersionIndex, equals(1));
        expect(cards[1].prayer.prayerId, equals('apostles_creed'));
        expect(cards[1].initialVersionIndex, equals(1));
      },
    );

    testWidgets(
      'PrayersTab reads initialVersionIndex via getPrayerVersionIndex and persists changes via savePrayerVersionIndex',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        final prayers = _buildMultiVersionRosaryPrayers();
        final settings = UserSettings()
          ..setPrayerVersionIndex(
            'sign_of_the_cross',
            PrayerLanguage.english,
            1,
          );
        PrayerDatabase.mockSettings = settings;
        await UserSettingsController.instance.update(settings);

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: PrayersTab(
                prayers: prayers,
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: null,
                settings: settings,
                fontSize: 16.0,
                searchQuery: '',
                onClearSearch: () {},
                scrollController: controller,
                languageSelectorAnimation: const AlwaysStoppedAnimation(0.0),
                isWide: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final signCard = tester
            .widgetList<PrayerCard>(find.byType(PrayerCard))
            .firstWhere((c) => c.prayer.prayerId == 'sign_of_the_cross');
        expect(signCard.initialVersionIndex, equals(1));

        signCard.onVersionChanged(0);
        await tester.pumpAndSettle();

        expect(
          UserSettingsController.instance.value.getPrayerVersionIndex(
            'sign_of_the_cross',
            PrayerLanguage.english,
          ),
          equals(0),
        );
      },
    );
  });
}
