import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';

void main() {
  setUp(() {
    PrayerDatabase.mockSettings = null;
    PrayerDatabase.mockPrayers = null;
  });

  tearDown(() {
    PrayerDatabase.mockSettings = null;
    PrayerDatabase.mockPrayers = null;
    UserSettingsController.instance.value = UserSettings();
  });

  group('UserSettingsController', () {
    test(
      'initial state holds default UserSettings and tracks isInitialized',
      () {
        final controller = UserSettingsController.instance;

        expect(controller.isInitialized, isFalse);
        expect(controller.value, isNotNull);
        expect(controller.value.primaryLanguageCode, equals('english'));
        expect(controller.value.compareLanguageCode, equals('latin'));
        expect(controller.value.primaryBibleTranslation, equals('CPDV'));
        expect(controller.value.compareBibleTranslation, equals('none'));
        expect(controller.value.hapticsEnabled, isTrue);
        expect(controller.value.appThemeModeCode, equals('marian_blue'));
        expect(controller.value.sundayNotificationsEnabled, isTrue);
        expect(controller.value.showBibleTranslationSelectors, isFalse);
        expect(controller.value.bibleNumberingSystemCode, equals('vulgate'));
      },
    );

    test(
      'load() retrieves settings from PrayerDatabase, sets isInitialized, and notifies listeners',
      () async {
        final controller = UserSettingsController.instance;
        final customSettings = UserSettings(
          primaryLanguageCode: 'spanish',
          compareLanguageCode: 'latin',
          primaryBibleTranslation: 'VULGATE',
          compareBibleTranslation: 'KJV',
          hapticsEnabled: false,
          appThemeModeCode: 'purple',
          sundayNotificationsEnabled: false,
          showBibleTranslationSelectors: true,
          bibleNumberingSystemCode: 'hebrew',
          missalReadingsOnly: true,
        );
        PrayerDatabase.mockSettings = customSettings;

        int notificationCount = 0;
        void listener() {
          notificationCount++;
        }

        controller.addListener(listener);
        try {
          await controller.load();

          expect(controller.isInitialized, isTrue);
          expect(controller.value.primaryLanguageCode, equals('spanish'));
          expect(controller.value.compareLanguageCode, equals('latin'));
          expect(controller.value.primaryBibleTranslation, equals('VULGATE'));
          expect(controller.value.compareBibleTranslation, equals('KJV'));
          expect(controller.value.hapticsEnabled, isFalse);
          expect(controller.value.appThemeModeCode, equals('purple'));
          expect(controller.value.sundayNotificationsEnabled, isFalse);
          expect(controller.value.showBibleTranslationSelectors, isTrue);
          expect(controller.value.bibleNumberingSystemCode, equals('hebrew'));
          expect(controller.value.missalReadingsOnly, isTrue);
          expect(notificationCount, greaterThan(0));
        } finally {
          controller.removeListener(listener);
        }
      },
    );

    test(
      'load() retrieves default settings when mockPrayers is set without mockSettings',
      () async {
        final controller = UserSettingsController.instance;
        PrayerDatabase.mockPrayers = [];
        PrayerDatabase.mockSettings = null;

        int notificationCount = 0;
        void listener() {
          notificationCount++;
        }

        controller.addListener(listener);
        try {
          await controller.load();

          expect(controller.isInitialized, isTrue);
          expect(controller.value.primaryLanguageCode, equals('english'));
          expect(controller.value.compareLanguageCode, equals('latin'));
          expect(notificationCount, greaterThan(0));
        } finally {
          controller.removeListener(listener);
        }
      },
    );

    test(
      'update() updates value, persists to PrayerDatabase, and notifies listeners',
      () async {
        final controller = UserSettingsController.instance;
        final initialSettings = UserSettings(
          primaryLanguageCode: 'english',
          hapticsEnabled: true,
        );
        PrayerDatabase.mockSettings = initialSettings;
        await controller.load();

        final updatedSettings = UserSettings(
          primaryLanguageCode: 'french',
          compareLanguageCode: 'italian',
          primaryBibleTranslation: 'NAV',
          compareBibleTranslation: 'CPDV',
          hapticsEnabled: false,
          appThemeModeCode: 'gold',
          sundayNotificationsEnabled: false,
          showBibleTranslationSelectors: true,
          bibleNumberingSystemCode: 'vulgate',
          missalReadingsOnly: true,
        );

        int notificationCount = 0;
        void listener() {
          notificationCount++;
        }

        controller.addListener(listener);
        try {
          await controller.update(updatedSettings);

          expect(controller.value.primaryLanguageCode, equals('french'));
          expect(controller.value.compareLanguageCode, equals('italian'));
          expect(controller.value.primaryBibleTranslation, equals('NAV'));
          expect(controller.value.compareBibleTranslation, equals('CPDV'));
          expect(controller.value.hapticsEnabled, isFalse);
          expect(controller.value.appThemeModeCode, equals('gold'));
          expect(controller.value.sundayNotificationsEnabled, isFalse);
          expect(controller.value.showBibleTranslationSelectors, isTrue);
          expect(controller.value.bibleNumberingSystemCode, equals('vulgate'));
          expect(controller.value.missalReadingsOnly, isTrue);

          expect(PrayerDatabase.mockSettings, equals(updatedSettings));
          expect(
            PrayerDatabase.mockSettings?.primaryLanguageCode,
            equals('french'),
          );
          expect(notificationCount, greaterThan(0));
        } finally {
          controller.removeListener(listener);
        }
      },
    );

    test(
      'update() with the same instance still notifies listeners via explicit notifyListeners',
      () async {
        final controller = UserSettingsController.instance;
        final currentSettings = UserSettings(
          primaryLanguageCode: 'latin',
          hapticsEnabled: true,
        );
        PrayerDatabase.mockSettings = currentSettings;
        await controller.load();

        // Mutate property on the same instance
        currentSettings.hapticsEnabled = false;

        int notificationCount = 0;
        void listener() {
          notificationCount++;
        }

        controller.addListener(listener);
        try {
          await controller.update(currentSettings);

          expect(controller.value.hapticsEnabled, isFalse);
          expect(notificationCount, equals(1));
        } finally {
          controller.removeListener(listener);
        }
      },
    );

    test(
      'multiple listeners all receive notifications on load and update',
      () async {
        final controller = UserSettingsController.instance;
        int listener1Count = 0;
        int listener2Count = 0;

        void listener1() {
          listener1Count++;
        }

        void listener2() {
          listener2Count++;
        }

        controller.addListener(listener1);
        controller.addListener(listener2);

        try {
          PrayerDatabase.mockSettings = UserSettings(
            primaryLanguageCode: 'tagalog',
          );
          await controller.load();

          expect(listener1Count, greaterThan(0));
          expect(listener2Count, greaterThan(0));
          expect(listener1Count, equals(listener2Count));

          final countAfterLoad = listener1Count;

          final nextSettings = UserSettings(primaryLanguageCode: 'vietnamese');
          await controller.update(nextSettings);

          expect(listener1Count, greaterThan(countAfterLoad));
          expect(listener2Count, greaterThan(countAfterLoad));
          expect(listener1Count, equals(listener2Count));

          final countAfterFirstUpdate = listener1Count;
          controller.removeListener(listener1);

          final finalSettings = UserSettings(primaryLanguageCode: 'latin');
          await controller.update(finalSettings);

          expect(
            listener1Count,
            equals(countAfterFirstUpdate),
          ); // removed listener should not increment
          expect(
            listener2Count,
            greaterThan(countAfterFirstUpdate),
          ); // remaining listener should increment
        } finally {
          controller.removeListener(listener1);
          controller.removeListener(listener2);
        }
      },
    );
  });
}
