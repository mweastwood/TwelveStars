import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_numbering_mapper.dart';
import 'package:twelve_stars/logic/catalog/library_catalog.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';
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

    test(
      'provides exact localized evangelist names across all 8 languages',
      () {
        final expectedNames = <PrayerLanguage, Map<Evangelist, String>>{
          PrayerLanguage.latin: {
            Evangelist.matthew: 'Matthǽum',
            Evangelist.mark: 'Marcum',
            Evangelist.luke: 'Lucam',
            Evangelist.john: 'Joánnem',
          },
          PrayerLanguage.spanish: {
            Evangelist.matthew: 'Mateo',
            Evangelist.mark: 'Marcos',
            Evangelist.luke: 'Lucas',
            Evangelist.john: 'Juan',
          },
          PrayerLanguage.vietnamese: {
            Evangelist.matthew: 'Mátthêu',
            Evangelist.mark: 'Mác-cô',
            Evangelist.luke: 'Luca',
            Evangelist.john: 'Gioan',
          },
          PrayerLanguage.french: {
            Evangelist.matthew: 'Matthieu',
            Evangelist.mark: 'Marc',
            Evangelist.luke: 'Luc',
            Evangelist.john: 'Jean',
          },
          PrayerLanguage.italian: {
            Evangelist.matthew: 'Matteo',
            Evangelist.mark: 'Marco',
            Evangelist.luke: 'Luca',
            Evangelist.john: 'Giovanni',
          },
          PrayerLanguage.tagalog: {
            Evangelist.matthew: 'Mateo',
            Evangelist.mark: 'Marcos',
            Evangelist.luke: 'Lucas',
            Evangelist.john: 'Juan',
          },
          PrayerLanguage.traditionalChinese: {
            Evangelist.matthew: '瑪竇',
            Evangelist.mark: '馬爾谷',
            Evangelist.luke: '路加',
            Evangelist.john: '若望',
          },
          PrayerLanguage.english: {
            Evangelist.matthew: 'Matthew',
            Evangelist.mark: 'Mark',
            Evangelist.luke: 'Luke',
            Evangelist.john: 'John',
          },
        };

        for (final lang in PrayerLanguage.values) {
          for (final evangelist in Evangelist.values) {
            expect(
              evangelist.localizedName(lang),
              equals(expectedNames[lang]![evangelist]),
            );
          }
        }
      },
    );
  });

  group('LectionaryResponses Dialogue Tests', () {
    test('non-Gospel reading concluding dialogue across all 8 languages', () {
      final en = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.english,
      );
      expect(en.ministerCue, equals('Lector'));
      expect(en.ministerText, equals('The word of the Lord.'));
      expect(en.peopleCue, equals('People'));
      expect(en.peopleText, equals('Thanks be to God.'));

      final la = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.latin,
      );
      expect(la.ministerCue, equals('Lector'));
      expect(la.ministerText, equals('Verbum Dómini.'));
      expect(la.peopleCue, equals('Populus'));
      expect(la.peopleText, equals('Deo grátias.'));

      final es = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.spanish,
      );
      expect(es.ministerCue, equals('Lector'));
      expect(es.ministerText, equals('Palabra de Dios.'));
      expect(es.peopleCue, equals('Pueblo'));
      expect(es.peopleText, equals('Te alabamos, Señor.'));

      final vi = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.vietnamese,
      );
      expect(vi.ministerCue, equals('Người đọc'));
      expect(vi.ministerText, equals('Đó là Lời Chúa.'));
      expect(vi.peopleCue, equals('Cộng đoàn'));
      expect(vi.peopleText, equals('Tạ ơn Chúa.'));

      final fr = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.french,
      );
      expect(fr.ministerCue, equals('Lecteur'));
      expect(fr.ministerText, equals('Parole du Seigneur.'));
      expect(fr.peopleCue, equals('Peuple'));
      expect(fr.peopleText, equals('Nous rendons grâce à Dieu.'));

      final it = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.italian,
      );
      expect(it.ministerCue, equals('Lettore'));
      expect(it.ministerText, equals('Parola di Dio.'));
      expect(it.peopleCue, equals('Popolo'));
      expect(it.peopleText, equals('Rendiamo grazie a Dio.'));

      final tl = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.tagalog,
      );
      expect(tl.ministerCue, equals('Tagabasa'));
      expect(tl.ministerText, equals('Salita ng Diyos.'));
      expect(tl.peopleCue, equals('Bayan'));
      expect(tl.peopleText, equals('Salamat sa Diyos.'));

      final zh = LectionaryResponses.getReadingConcludingDialogue(
        PrayerLanguage.traditionalChinese,
      );
      expect(zh.ministerCue, equals('讀經員'));
      expect(zh.ministerText, equals('上主的聖言。'));
      expect(zh.peopleCue, equals('信友'));
      expect(zh.peopleText, equals('感謝天主。'));
    });

    test('Gospel introductory greeting across all 8 languages', () {
      final en = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.english,
      );
      expect(en.ministerCue, equals('Priest'));
      expect(en.ministerText, equals('The Lord be with you.'));
      expect(en.peopleCue, equals('People'));
      expect(en.peopleText, equals('And with your spirit.'));

      final la = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.latin,
      );
      expect(la.ministerCue, equals('Sacerdos'));
      expect(la.ministerText, equals('Dóminus vobíscum.'));
      expect(la.peopleCue, equals('Populus'));
      expect(la.peopleText, equals('Et cum spíritu tuo.'));

      final es = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.spanish,
      );
      expect(es.ministerCue, equals('Sacerdote'));
      expect(es.ministerText, equals('El Señor esté con ustedes.'));
      expect(es.peopleCue, equals('Pueblo'));
      expect(es.peopleText, equals('Y con tu espíritu.'));

      final vi = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.vietnamese,
      );
      expect(vi.ministerCue, equals('Linh mục'));
      expect(vi.ministerText, equals('Chúa ở cùng anh chị em.'));
      expect(vi.peopleCue, equals('Cộng đoàn'));
      expect(vi.peopleText, equals('Và ở cùng cha.'));

      final fr = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.french,
      );
      expect(fr.ministerCue, equals('Prêtre'));
      expect(fr.ministerText, equals('Le Seigneur soit avec vous.'));
      expect(fr.peopleCue, equals('Peuple'));
      expect(fr.peopleText, equals('Et avec votre esprit.'));

      final it = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.italian,
      );
      expect(it.ministerCue, equals('Sacerdote'));
      expect(it.ministerText, equals('Il Signore sia con voi.'));
      expect(it.peopleCue, equals('Popolo'));
      expect(it.peopleText, equals('E con il tuo spirito.'));

      final tl = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.tagalog,
      );
      expect(tl.ministerCue, equals('Pari'));
      expect(tl.ministerText, equals('Sumainyo ang Panginoon.'));
      expect(tl.peopleCue, equals('Bayan'));
      expect(tl.peopleText, equals('At sumaiyo rin.'));

      final zh = LectionaryResponses.getGospelIntroGreeting(
        PrayerLanguage.traditionalChinese,
      );
      expect(zh.ministerCue, equals('主祭'));
      expect(zh.ministerText, equals('願主與你們同在。'));
      expect(zh.peopleCue, equals('信友'));
      expect(zh.peopleText, equals('也與你的心靈同在。'));
    });

    test(
      'Gospel announcement dialogue across all 8 languages and null fallback',
      () {
        final enLuke = LectionaryResponses.getGospelIntroAnnouncement(
          PrayerLanguage.english,
          Evangelist.luke,
        );
        expect(enLuke.ministerCue, equals('Priest'));
        expect(
          enLuke.ministerText,
          equals('A reading from the holy Gospel according to Luke.'),
        );
        expect(enLuke.peopleCue, equals('People'));
        expect(enLuke.peopleText, equals('Glory to you, O Lord.'));

        final laMatthew = LectionaryResponses.getGospelIntroAnnouncement(
          PrayerLanguage.latin,
          Evangelist.matthew,
        );
        expect(laMatthew.ministerCue, equals('Sacerdos'));
        expect(
          laMatthew.ministerText,
          equals('Léctio sancti Evangélii secúndum Matthǽum.'),
        );
        expect(laMatthew.peopleCue, equals('Populus'));
        expect(laMatthew.peopleText, equals('Glória tibi, Dómine.'));

        final esJohn = LectionaryResponses.getGospelIntroAnnouncement(
          PrayerLanguage.spanish,
          Evangelist.john,
        );
        expect(esJohn.ministerCue, equals('Sacerdote'));
        expect(
          esJohn.ministerText,
          equals('Lectura del santo Evangelio según san Juan.'),
        );
        expect(esJohn.peopleCue, equals('Pueblo'));
        expect(esJohn.peopleText, equals('Gloria a ti, Señor.'));

        final viMark = LectionaryResponses.getGospelIntroAnnouncement(
          PrayerLanguage.vietnamese,
          Evangelist.mark,
        );
        expect(viMark.ministerCue, equals('Linh mục'));
        expect(
          viMark.ministerText,
          equals('Tin Mừng Chúa Giêsu Kitô theo thánh Mác-cô.'),
        );
        expect(viMark.peopleCue, equals('Cộng đoàn'));
        expect(viMark.peopleText, equals('Lạy Chúa, vinh danh Chúa.'));

        final frJohn = LectionaryResponses.getGospelIntroAnnouncement(
          PrayerLanguage.french,
          Evangelist.john,
        );
        expect(frJohn.ministerCue, equals('Prêtre'));
        expect(
          frJohn.ministerText,
          equals('Évangile de Jésus Christ selon saint Jean.'),
        );
        expect(frJohn.peopleCue, equals('Peuple'));
        expect(frJohn.peopleText, equals('Gloire à toi, Seigneur.'));

        final itLuke = LectionaryResponses.getGospelIntroAnnouncement(
          PrayerLanguage.italian,
          Evangelist.luke,
        );
        expect(itLuke.ministerCue, equals('Sacerdote'));
        expect(itLuke.ministerText, equals('Dal Vangelo secondo Luca.'));
        expect(itLuke.peopleCue, equals('Popolo'));
        expect(itLuke.peopleText, equals('Gloria a te, o Signore.'));

        final tlMatthew = LectionaryResponses.getGospelIntroAnnouncement(
          PrayerLanguage.tagalog,
          Evangelist.matthew,
        );
        expect(tlMatthew.ministerCue, equals('Pari'));
        expect(
          tlMatthew.ministerText,
          equals('Ang Mabuting Balita ng Panginoon ayon kay San Mateo.'),
        );
        expect(tlMatthew.peopleCue, equals('Bayan'));
        expect(tlMatthew.peopleText, equals('Papuri sa Iyo, Panginoon.'));

        final zhMark = LectionaryResponses.getGospelIntroAnnouncement(
          PrayerLanguage.traditionalChinese,
          Evangelist.mark,
        );
        expect(zhMark.ministerCue, equals('主祭'));
        expect(zhMark.ministerText, equals('恭讀聖馬爾谷福音。'));
        expect(zhMark.peopleCue, equals('信友'));
        expect(zhMark.peopleText, equals('主，願光榮歸於祢。'));

        final nullEvangelist = LectionaryResponses.getGospelIntroAnnouncement(
          PrayerLanguage.english,
          null,
        );
        expect(
          nullEvangelist.ministerText,
          equals('A reading from the holy Gospel according to N..'),
        );
      },
    );

    test('Gospel concluding dialogue across all 8 languages', () {
      final en = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.english,
      );
      expect(en.ministerCue, equals('Priest'));
      expect(en.ministerText, equals('The Gospel of the Lord.'));
      expect(en.peopleCue, equals('People'));
      expect(en.peopleText, equals('Praise to you, Lord Jesus Christ.'));

      final la = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.latin,
      );
      expect(la.ministerCue, equals('Sacerdos'));
      expect(la.ministerText, equals('Verbum Dómini.'));
      expect(la.peopleCue, equals('Populus'));
      expect(la.peopleText, equals('Laus tibi, Christe.'));

      final es = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.spanish,
      );
      expect(es.ministerCue, equals('Sacerdote'));
      expect(es.ministerText, equals('Palabra del Señor.'));
      expect(es.peopleCue, equals('Pueblo'));
      expect(es.peopleText, equals('Gloria a ti, Señor Jesús.'));

      final vi = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.vietnamese,
      );
      expect(vi.ministerCue, equals('Linh mục'));
      expect(vi.ministerText, equals('Đó là Lời Chúa.'));
      expect(vi.peopleCue, equals('Cộng đoàn'));
      expect(vi.peopleText, equals('Lạy Chúa Kitô, ngợi khen Chúa.'));

      final fr = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.french,
      );
      expect(fr.ministerCue, equals('Prêtre'));
      expect(fr.ministerText, equals('Acclamons la Parole de Dieu.'));
      expect(fr.peopleCue, equals('Peuple'));
      expect(fr.peopleText, equals('Louange à toi, Seigneur Jésus.'));

      final it = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.italian,
      );
      expect(it.ministerCue, equals('Sacerdote'));
      expect(it.ministerText, equals('Parola del Signore.'));
      expect(it.peopleCue, equals('Popolo'));
      expect(it.peopleText, equals('Lode a te, o Cristo.'));

      final tl = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.tagalog,
      );
      expect(tl.ministerCue, equals('Pari'));
      expect(tl.ministerText, equals('Ang Mabuting Balita ng Panginoon.'));
      expect(tl.peopleCue, equals('Bayan'));
      expect(
        tl.peopleText,
        equals('Pinupuri ka namin, Panginoong Hesukristo.'),
      );

      final zh = LectionaryResponses.getGospelConcludingDialogue(
        PrayerLanguage.traditionalChinese,
      );
      expect(zh.ministerCue, equals('主祭'));
      expect(zh.ministerText, equals('主基督的聖言。'));
      expect(zh.peopleCue, equals('信友'));
      expect(zh.peopleText, equals('基督，我們讚美祢。'));
    });
  });

  group('Acts 7:55-60 Verse Shift Rule & Catalog Separation Tests', () {
    test(
      'BibleVerseResolver maps Modern Acts 7:55-60 to Vulgate Acts 7:55-59',
      () {
        // Acts 7:54 is unshifted
        expect(
          BibleVerseResolver.masoreticToVulgateVerse(
            bookNumber: 53,
            chapter: 7,
            verse: 54,
          ),
          equals((chapter: 7, verse: 54)),
        );
        // Acts 7:55 and 7:56 both merge into Vulgate 7:55
        expect(
          BibleVerseResolver.masoreticToVulgateVerse(
            bookNumber: 53,
            chapter: 7,
            verse: 55,
          ),
          equals((chapter: 7, verse: 55)),
        );
        expect(
          BibleVerseResolver.masoreticToVulgateVerse(
            bookNumber: 53,
            chapter: 7,
            verse: 56,
          ),
          equals((chapter: 7, verse: 55)),
        );
        // Acts 7:57-60 shift by -1 to Vulgate 7:56-59
        for (int v = 57; v <= 60; v++) {
          expect(
            BibleVerseResolver.masoreticToVulgateVerse(
              bookNumber: 53,
              chapter: 7,
              verse: v,
            ),
            equals((chapter: 7, verse: v - 1)),
          );
          expect(
            BibleVerseResolver.vulgateToMasoreticVerse(
              bookNumber: 53,
              chapter: 7,
              verse: v - 1,
            ),
            equals((chapter: 7, verse: v)),
          );
        }

        // Lectionary resolution for Acts 7:55-60 (e.g. 7th Sunday of Easter Year C)
        final ranges = resolveReadingRanges(
          bookNumber: 53,
          defaultChapter: 7,
          defaultVerseRange: '55-60',
          citation: 'Acts 7:55-60',
        );
        expect(ranges, [
          const ChapterVerseRange(chapter: 7, verses: [55, 55, 56, 57, 58, 59]),
        ]);
      },
    );

    test(
      'LibraryCatalog exposes extracted static data and resolves targets',
      () {
        expect(LibraryCatalog.getCatalog(), same(kLibraryCatalog));
        expect(LibraryCatalog.baltimoreVolumes, same(kBaltimoreVolumes));
        expect(
          LibraryCatalog.findBookById('baltimore_catechism')?.title,
          equals('Baltimore Catechism'),
        );
        expect(
          LibraryCatalog.resolveAuthorSaintId('benedict_rule'),
          equals('benedict-of-nursia'),
        );
      },
    );
  });
}
