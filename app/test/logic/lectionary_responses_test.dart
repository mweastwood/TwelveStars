import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/lectionary_responses.dart';
import 'package:twelve_stars/logic/prayers.dart';

void main() {
  group('Evangelist Enum Tests', () {
    test('resolves Evangelist from Catholic book number', () {
      expect(Evangelist.fromBookNumber(49), equals(Evangelist.matthew));
      expect(Evangelist.fromBookNumber(50), equals(Evangelist.mark));
      expect(Evangelist.fromBookNumber(51), equals(Evangelist.luke));
      expect(Evangelist.fromBookNumber(52), equals(Evangelist.john));
      expect(Evangelist.fromBookNumber(1), isNull);
      expect(Evangelist.fromBookNumber(58), isNull);
    });

    test('resolves Evangelist from book name strings', () {
      expect(Evangelist.fromBookName('Matthew'), equals(Evangelist.matthew));
      expect(Evangelist.fromBookName('Mateo'), equals(Evangelist.matthew));
      expect(Evangelist.fromBookName('Mark'), equals(Evangelist.mark));
      expect(Evangelist.fromBookName('Marcos'), equals(Evangelist.mark));
      expect(Evangelist.fromBookName('Luke'), equals(Evangelist.luke));
      expect(Evangelist.fromBookName('Lucas'), equals(Evangelist.luke));
      expect(Evangelist.fromBookName('John'), equals(Evangelist.john));
      expect(Evangelist.fromBookName('Jean'), equals(Evangelist.john));
      expect(Evangelist.fromBookName('Gioan'), equals(Evangelist.john));
      expect(Evangelist.fromBookName('Genesis'), isNull);
      expect(Evangelist.fromBookName(null), isNull);
    });

    test('provides localized evangelist names across all 8 languages', () {
      for (final lang in PrayerLanguage.values) {
        for (final evangelist in Evangelist.values) {
          final name = evangelist.localizedName(lang);
          expect(name, isNotEmpty);
        }
      }
    });
  });

  group('LectionaryResponses Dialogue Tests', () {
    test('non-Gospel reading concluding dialogue across all 8 languages', () {
      final en = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.english,
      );
      expect(en.ministerText, equals('The word of the Lord.'));
      expect(en.peopleText, equals('Thanks be to God.'));

      final la = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.latin,
      );
      expect(la.ministerText, equals('Verbum Dómini.'));
      expect(la.peopleText, equals('Deo grátias.'));

      final es = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.spanish,
      );
      expect(es.ministerText, equals('Palabra de Dios.'));
      expect(es.peopleText, equals('Te alabamos, Señor.'));

      final vi = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.vietnamese,
      );
      expect(vi.ministerText, equals('Đó là Lời Chúa.'));
      expect(vi.peopleText, equals('Tạ ơn Chúa.'));

      final fr = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.french,
      );
      expect(fr.ministerText, equals('Parole du Seigneur.'));
      expect(fr.peopleText, equals('Nous rendons grâce à Dieu.'));

      final it = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.italian,
      );
      expect(it.ministerText, equals('Parola di Dio.'));
      expect(it.peopleText, equals('Rendiamo grazie a Dio.'));

      final tl = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.tagalog,
      );
      expect(tl.ministerText, equals('Salita ng Diyos.'));
      expect(tl.peopleText, equals('Salamat sa Diyos.'));

      final zh = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.traditionalChinese,
      );
      expect(zh.ministerText, equals('上主的聖言。'));
      expect(zh.peopleText, equals('感謝天主。'));
    });

    test('Gospel introductory greeting across all 8 languages', () {
      final en = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.english,
      );
      expect(en.ministerText, equals('The Lord be with you.'));
      expect(en.peopleText, equals('And with your spirit.'));

      final la = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.latin,
      );
      expect(la.ministerText, equals('Dóminus vobíscum.'));
      expect(la.peopleText, equals('Et cum spíritu tuo.'));

      final es = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.spanish,
      );
      expect(es.ministerText, equals('El Señor esté con ustedes.'));
      expect(es.peopleText, equals('Y con tu espíritu.'));

      final vi = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.vietnamese,
      );
      expect(vi.ministerText, equals('Chúa ở cùng anh chị em.'));
      expect(vi.peopleText, equals('Và ở cùng cha.'));

      final fr = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.french,
      );
      expect(fr.ministerText, equals('Le Seigneur soit avec vous.'));
      expect(fr.peopleText, equals('Et avec votre esprit.'));

      final it = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.italian,
      );
      expect(it.ministerText, equals('Il Signore sia con voi.'));
      expect(it.peopleText, equals('E con il tuo spirito.'));

      final tl = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.tagalog,
      );
      expect(tl.ministerText, equals('Sumainyo ang Panginoon.'));
      expect(tl.peopleText, equals('At sumaiyo rin.'));

      final zh = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.traditionalChinese,
      );
      expect(zh.ministerText, equals('願主與你們同在。'));
      expect(zh.peopleText, equals('也與你的心靈同在。'));
    });

    test('Gospel announcement dialogue includes localized evangelist', () {
      final enLuke = LectionaryResponses.getGospelIntroAnnouncement(
        PrayerLanguage.english,
        Evangelist.luke,
      );
      expect(
        enLuke.ministerText,
        equals('A reading from the holy Gospel according to Luke.'),
      );
      expect(enLuke.peopleText, equals('Glory to you, O Lord.'));

      final laMatthew = LectionaryResponses.getGospelIntroAnnouncement(
        PrayerLanguage.latin,
        Evangelist.matthew,
      );
      expect(
        laMatthew.ministerText,
        equals('Léctio sancti Evangélii secúndum Matthǽum.'),
      );
      expect(laMatthew.peopleText, equals('Glória tibi, Dómine.'));

      final esJohn = LectionaryResponses.getGospelIntroAnnouncement(
        PrayerLanguage.spanish,
        Evangelist.john,
      );
      expect(
        esJohn.ministerText,
        equals('Lectura del santo Evangelio según san Juan.'),
      );
      expect(esJohn.peopleText, equals('Gloria a ti, Señor.'));
    });

    test('Gospel concluding dialogue across all 8 languages', () {
      final en = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.english,
      );
      expect(en.ministerText, equals('The Gospel of the Lord.'));
      expect(en.peopleText, equals('Praise to you, Lord Jesus Christ.'));

      final la = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.latin,
      );
      expect(la.ministerText, equals('Verbum Dómini.'));
      expect(la.peopleText, equals('Laus tibi, Christe.'));

      final es = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.spanish,
      );
      expect(es.ministerText, equals('Palabra del Señor.'));
      expect(es.peopleText, equals('Gloria a ti, Señor Jesús.'));

      final vi = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.vietnamese,
      );
      expect(vi.ministerText, equals('Đó là Lời Chúa.'));
      expect(vi.peopleText, equals('Lạy Chúa Kitô, ngợi khen Chúa.'));

      final fr = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.french,
      );
      expect(fr.ministerText, equals('Acclamons la Parole de Dieu.'));
      expect(fr.peopleText, equals('Louange à toi, Seigneur Jésus.'));

      final it = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.italian,
      );
      expect(it.ministerText, equals('Parola del Signore.'));
      expect(it.peopleText, equals('Lode a te, o Cristo.'));

      final tl = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.tagalog,
      );
      expect(tl.ministerText, equals('Ang Mabuting Balita ng Panginoon.'));
      expect(
        tl.peopleText,
        equals('Pinupuri ka namin, Panginoong Hesukristo.'),
      );

      final zh = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.traditionalChinese,
      );
      expect(zh.ministerText, equals('主基督的聖言。'));
      expect(zh.peopleText, equals('基督，我們讚美祢。'));
    });
  });
}
