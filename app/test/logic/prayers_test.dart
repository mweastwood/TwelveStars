import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayers.dart';

void main() {
  group('Prayers Data', () {
    test('contains exactly three starter prayers', () {
      expect(defaultPrayers.length, 3);
      expect(defaultPrayers[0].id, 'our_father');
      expect(defaultPrayers[1].id, 'hail_mary');
      expect(defaultPrayers[2].id, 'glory_be');
    });

    test('each prayer has translations for all target languages', () {
      for (var prayer in defaultPrayers) {
        expect(prayer.translations.containsKey(PrayerLanguage.english), true);
        expect(prayer.translations.containsKey(PrayerLanguage.spanish), true);
        expect(prayer.translations.containsKey(PrayerLanguage.french), true);
        expect(prayer.translations.containsKey(PrayerLanguage.italian), true);
        expect(prayer.translations.containsKey(PrayerLanguage.latin), true);
        expect(
          prayer.translations.containsKey(PrayerLanguage.vietnamese),
          true,
        );
        expect(prayer.translations.containsKey(PrayerLanguage.tagalog), true);
        expect(
          prayer.translations.containsKey(PrayerLanguage.traditionalChinese),
          true,
        );
      }
    });

    test('translations contain valid data and sources', () {
      for (var prayer in defaultPrayers) {
        prayer.translations.forEach((lang, transList) {
          expect(transList.isNotEmpty, true);
          for (var trans in transList) {
            expect(trans.title.isNotEmpty, true);
            expect(trans.text.isNotEmpty, true);
            expect(trans.sourceName.isNotEmpty, true);
            expect(trans.sourceUrl.startsWith('https://'), true);
          }
        });
      }
    });

    test('traditionalChinese translations contain valid pinyin lines', () {
      for (var prayer in defaultPrayers) {
        final transList =
            prayer.translations[PrayerLanguage.traditionalChinese]!;
        expect(transList.isNotEmpty, true);
        for (var trans in transList) {
          expect(trans.chineseLines, isNotNull);
          expect(trans.chineseLines!.isNotEmpty, true);
          for (var line in trans.chineseLines!) {
            expect(line.isNotEmpty, true);
            for (var charItem in line) {
              expect(charItem.char.isNotEmpty, true);
            }
          }
        }
      }
    });
  });
}
