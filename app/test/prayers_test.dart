import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/prayers.dart';

void main() {
  group('Prayers Data', () {
    test('contains exactly three starter prayers', () {
      expect(defaultPrayers.length, 3);
      expect(defaultPrayers[0].id, 'our_father');
      expect(defaultPrayers[1].id, 'hail_mary');
      expect(defaultPrayers[2].id, 'glory_be');
    });

    test('each prayer has translations for all four target languages', () {
      for (var prayer in defaultPrayers) {
        expect(prayer.translations.containsKey(PrayerLanguage.english), true);
        expect(prayer.translations.containsKey(PrayerLanguage.spanish), true);
        expect(prayer.translations.containsKey(PrayerLanguage.latin), true);
        expect(
          prayer.translations.containsKey(PrayerLanguage.vietnamese),
          true,
        );
      }
    });

    test('translations contain valid data and sources', () {
      for (var prayer in defaultPrayers) {
        prayer.translations.forEach((lang, trans) {
          expect(trans.title.isNotEmpty, true);
          expect(trans.text.isNotEmpty, true);
          expect(trans.sourceName.isNotEmpty, true);
          expect(trans.sourceUrl.startsWith('https://'), true);
        });
      }
    });
  });
}
