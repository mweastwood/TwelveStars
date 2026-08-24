import 'package:flutter/foundation.dart';
import 'package:twelve_stars/logic/prayers.dart';

/// Represents a single liturgical dialogue exchange between a minister and the congregation.
@immutable
class LiturgicalDialogue {
  final String ministerCue;
  final String ministerText;
  final String peopleCue;
  final String peopleText;

  const LiturgicalDialogue({
    required this.ministerCue,
    required this.ministerText,
    required this.peopleCue,
    required this.peopleText,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiturgicalDialogue &&
          runtimeType == other.runtimeType &&
          ministerCue == other.ministerCue &&
          ministerText == other.ministerText &&
          peopleCue == other.peopleCue &&
          peopleText == other.peopleText;

  @override
  int get hashCode =>
      ministerCue.hashCode ^
      ministerText.hashCode ^
      peopleCue.hashCode ^
      peopleText.hashCode;
}

/// The four Evangelists with helpers to resolve from book numbers or names.
enum Evangelist {
  matthew,
  mark,
  luke,
  john;

  /// Resolve from Bible book number (Matthew: 49, Mark: 50, Luke: 51, John: 52 in Catholic numbering).
  static Evangelist? fromBookNumber(int bookNumber) {
    switch (bookNumber) {
      case 49:
        return Evangelist.matthew;
      case 50:
        return Evangelist.mark;
      case 51:
        return Evangelist.luke;
      case 52:
        return Evangelist.john;
      default:
        return null;
    }
  }

  /// Resolve from book name / abbreviation.
  static Evangelist? fromBookName(String? name) {
    if (name == null) return null;
    final lower = name.toLowerCase().trim();
    if (lower.contains('matthew') ||
        lower.contains('matth') ||
        lower.contains('mateo') ||
        lower.contains('mat') ||
        lower.contains('mt')) {
      return Evangelist.matthew;
    }
    if (lower.contains('mark') ||
        lower.contains('marc') ||
        lower.contains('marcos') ||
        lower.contains('mk')) {
      return Evangelist.mark;
    }
    if (lower.contains('luke') ||
        lower.contains('luc') ||
        lower.contains('lucas') ||
        lower.contains('lk')) {
      return Evangelist.luke;
    }
    if (lower.contains('john') ||
        lower.contains('jean') ||
        lower.contains('juan') ||
        lower.contains('giovanni') ||
        lower.contains('gioan') ||
        lower.contains('jn')) {
      return Evangelist.john;
    }
    return null;
  }

  /// Localized Evangelist name according to the liturgical prayer language.
  String localizedName(PrayerLanguage language) {
    switch (language) {
      case PrayerLanguage.latin:
        switch (this) {
          case Evangelist.matthew:
            return 'Matthǽum';
          case Evangelist.mark:
            return 'Marcum';
          case Evangelist.luke:
            return 'Lucam';
          case Evangelist.john:
            return 'Joánnem';
        }
      case PrayerLanguage.spanish:
        switch (this) {
          case Evangelist.matthew:
            return 'Mateo';
          case Evangelist.mark:
            return 'Marcos';
          case Evangelist.luke:
            return 'Lucas';
          case Evangelist.john:
            return 'Juan';
        }
      case PrayerLanguage.vietnamese:
        switch (this) {
          case Evangelist.matthew:
            return 'Mátthêu';
          case Evangelist.mark:
            return 'Mác-cô';
          case Evangelist.luke:
            return 'Luca';
          case Evangelist.john:
            return 'Gioan';
        }
      case PrayerLanguage.french:
        switch (this) {
          case Evangelist.matthew:
            return 'Matthieu';
          case Evangelist.mark:
            return 'Marc';
          case Evangelist.luke:
            return 'Luc';
          case Evangelist.john:
            return 'Jean';
        }
      case PrayerLanguage.italian:
        switch (this) {
          case Evangelist.matthew:
            return 'Matteo';
          case Evangelist.mark:
            return 'Marco';
          case Evangelist.luke:
            return 'Luca';
          case Evangelist.john:
            return 'Giovanni';
        }
      case PrayerLanguage.tagalog:
        switch (this) {
          case Evangelist.matthew:
            return 'Mateo';
          case Evangelist.mark:
            return 'Marcos';
          case Evangelist.luke:
            return 'Lucas';
          case Evangelist.john:
            return 'Juan';
        }
      case PrayerLanguage.traditionalChinese:
        switch (this) {
          case Evangelist.matthew:
            return '瑪竇';
          case Evangelist.mark:
            return '馬爾谷';
          case Evangelist.luke:
            return '路加';
          case Evangelist.john:
            return '若望';
        }
      case PrayerLanguage.english:
        switch (this) {
          case Evangelist.matthew:
            return 'Matthew';
          case Evangelist.mark:
            return 'Mark';
          case Evangelist.luke:
            return 'Luke';
          case Evangelist.john:
            return 'John';
        }
    }
  }
}

/// Provides standard liturgical dialogues and responses for Lectionary readings.
class LectionaryResponses {
  const LectionaryResponses._();

  /// Concluding dialogue for First and Second readings (and other non-Gospel readings).
  static LiturgicalDialogue getReadingConcludingDialogue(
    PrayerLanguage language,
  ) {
    switch (language) {
      case PrayerLanguage.latin:
        return const LiturgicalDialogue(
          ministerCue: 'Lector',
          ministerText: 'Verbum Dómini.',
          peopleCue: 'Populus',
          peopleText: 'Deo grátias.',
        );
      case PrayerLanguage.spanish:
        return const LiturgicalDialogue(
          ministerCue: 'Lector',
          ministerText: 'Palabra de Dios.',
          peopleCue: 'Pueblo',
          peopleText: 'Te alabamos, Señor.',
        );
      case PrayerLanguage.vietnamese:
        return const LiturgicalDialogue(
          ministerCue: 'Người đọc',
          ministerText: 'Đó là Lời Chúa.',
          peopleCue: 'Cộng đoàn',
          peopleText: 'Tạ ơn Chúa.',
        );
      case PrayerLanguage.french:
        return const LiturgicalDialogue(
          ministerCue: 'Lecteur',
          ministerText: 'Parole du Seigneur.',
          peopleCue: 'Peuple',
          peopleText: 'Nous rendons grâce à Dieu.',
        );
      case PrayerLanguage.italian:
        return const LiturgicalDialogue(
          ministerCue: 'Lettore',
          ministerText: 'Parola di Dio.',
          peopleCue: 'Popolo',
          peopleText: 'Rendiamo grazie a Dio.',
        );
      case PrayerLanguage.tagalog:
        return const LiturgicalDialogue(
          ministerCue: 'Tagabasa',
          ministerText: 'Salita ng Diyos.',
          peopleCue: 'Bayan',
          peopleText: 'Salamat sa Diyos.',
        );
      case PrayerLanguage.traditionalChinese:
        return const LiturgicalDialogue(
          ministerCue: '讀經員',
          ministerText: '上主的聖言。',
          peopleCue: '信友',
          peopleText: '感謝天主。',
        );
      case PrayerLanguage.english:
        return const LiturgicalDialogue(
          ministerCue: 'Lector',
          ministerText: 'The word of the Lord.',
          peopleCue: 'People',
          peopleText: 'Thanks be to God.',
        );
    }
  }

  /// Initial greeting before the Gospel ("The Lord be with you...").
  static LiturgicalDialogue getGospelIntroGreeting(PrayerLanguage language) {
    switch (language) {
      case PrayerLanguage.latin:
        return const LiturgicalDialogue(
          ministerCue: 'Sacerdos',
          ministerText: 'Dóminus vobíscum.',
          peopleCue: 'Populus',
          peopleText: 'Et cum spíritu tuo.',
        );
      case PrayerLanguage.spanish:
        return const LiturgicalDialogue(
          ministerCue: 'Sacerdote',
          ministerText: 'El Señor esté con ustedes.',
          peopleCue: 'Pueblo',
          peopleText: 'Y con tu espíritu.',
        );
      case PrayerLanguage.vietnamese:
        return const LiturgicalDialogue(
          ministerCue: 'Linh mục',
          ministerText: 'Chúa ở cùng anh chị em.',
          peopleCue: 'Cộng đoàn',
          peopleText: 'Và ở cùng cha.',
        );
      case PrayerLanguage.french:
        return const LiturgicalDialogue(
          ministerCue: 'Prêtre',
          ministerText: 'Le Seigneur soit avec vous.',
          peopleCue: 'Peuple',
          peopleText: 'Et avec votre esprit.',
        );
      case PrayerLanguage.italian:
        return const LiturgicalDialogue(
          ministerCue: 'Sacerdote',
          ministerText: 'Il Signore sia con voi.',
          peopleCue: 'Popolo',
          peopleText: 'E con il tuo spirito.',
        );
      case PrayerLanguage.tagalog:
        return const LiturgicalDialogue(
          ministerCue: 'Pari',
          ministerText: 'Sumainyo ang Panginoon.',
          peopleCue: 'Bayan',
          peopleText: 'At sumaiyo rin.',
        );
      case PrayerLanguage.traditionalChinese:
        return const LiturgicalDialogue(
          ministerCue: '主祭',
          ministerText: '願主與你們同在。',
          peopleCue: '信友',
          peopleText: '也與你的心靈同在。',
        );
      case PrayerLanguage.english:
        return const LiturgicalDialogue(
          ministerCue: 'Priest',
          ministerText: 'The Lord be with you.',
          peopleCue: 'People',
          peopleText: 'And with your spirit.',
        );
    }
  }

  /// Gospel announcement dialogue ("A reading from the holy Gospel according to {Evangelist}...").
  static LiturgicalDialogue getGospelIntroAnnouncement(
    PrayerLanguage language,
    Evangelist? evangelist,
  ) {
    final evangelistName = evangelist?.localizedName(language) ?? 'N.';

    switch (language) {
      case PrayerLanguage.latin:
        return LiturgicalDialogue(
          ministerCue: 'Sacerdos',
          ministerText: 'Léctio sancti Evangélii secúndum $evangelistName.',
          peopleCue: 'Populus',
          peopleText: 'Glória tibi, Dómine.',
        );
      case PrayerLanguage.spanish:
        return LiturgicalDialogue(
          ministerCue: 'Sacerdote',
          ministerText:
              'Lectura del santo Evangelio según san $evangelistName.',
          peopleCue: 'Pueblo',
          peopleText: 'Gloria a ti, Señor.',
        );
      case PrayerLanguage.vietnamese:
        return LiturgicalDialogue(
          ministerCue: 'Linh mục',
          ministerText: 'Tin Mừng Chúa Giêsu Kitô theo thánh $evangelistName.',
          peopleCue: 'Cộng đoàn',
          peopleText: 'Lạy Chúa, vinh danh Chúa.',
        );
      case PrayerLanguage.french:
        return LiturgicalDialogue(
          ministerCue: 'Prêtre',
          ministerText: 'Évangile de Jésus Christ selon saint $evangelistName.',
          peopleCue: 'Peuple',
          peopleText: 'Gloire à toi, Seigneur.',
        );
      case PrayerLanguage.italian:
        return LiturgicalDialogue(
          ministerCue: 'Sacerdote',
          ministerText: 'Dal Vangelo secondo $evangelistName.',
          peopleCue: 'Popolo',
          peopleText: 'Gloria a te, o Signore.',
        );
      case PrayerLanguage.tagalog:
        return LiturgicalDialogue(
          ministerCue: 'Pari',
          ministerText:
              'Ang Mabuting Balita ng Panginoon ayon kay San $evangelistName.',
          peopleCue: 'Bayan',
          peopleText: 'Papuri sa Iyo, Panginoon.',
        );
      case PrayerLanguage.traditionalChinese:
        return LiturgicalDialogue(
          ministerCue: '主祭',
          ministerText: '恭讀聖$evangelistName福音。',
          peopleCue: '信友',
          peopleText: '主，願光榮歸於祢。',
        );
      case PrayerLanguage.english:
        return LiturgicalDialogue(
          ministerCue: 'Priest',
          ministerText:
              'A reading from the holy Gospel according to $evangelistName.',
          peopleCue: 'People',
          peopleText: 'Glory to you, O Lord.',
        );
    }
  }

  /// Concluding acclamation following the Gospel reading.
  static LiturgicalDialogue getGospelConcludingDialogue(
    PrayerLanguage language,
  ) {
    switch (language) {
      case PrayerLanguage.latin:
        return const LiturgicalDialogue(
          ministerCue: 'Sacerdos',
          ministerText: 'Verbum Dómini.',
          peopleCue: 'Populus',
          peopleText: 'Laus tibi, Christe.',
        );
      case PrayerLanguage.spanish:
        return const LiturgicalDialogue(
          ministerCue: 'Sacerdote',
          ministerText: 'Palabra del Señor.',
          peopleCue: 'Pueblo',
          peopleText: 'Gloria a ti, Señor Jesús.',
        );
      case PrayerLanguage.vietnamese:
        return const LiturgicalDialogue(
          ministerCue: 'Linh mục',
          ministerText: 'Đó là Lời Chúa.',
          peopleCue: 'Cộng đoàn',
          peopleText: 'Lạy Chúa Kitô, ngợi khen Chúa.',
        );
      case PrayerLanguage.french:
        return const LiturgicalDialogue(
          ministerCue: 'Prêtre',
          ministerText: 'Acclamons la Parole de Dieu.',
          peopleCue: 'Peuple',
          peopleText: 'Louange à toi, Seigneur Jésus.',
        );
      case PrayerLanguage.italian:
        return const LiturgicalDialogue(
          ministerCue: 'Sacerdote',
          ministerText: 'Parola del Signore.',
          peopleCue: 'Popolo',
          peopleText: 'Lode a te, o Cristo.',
        );
      case PrayerLanguage.tagalog:
        return const LiturgicalDialogue(
          ministerCue: 'Pari',
          ministerText: 'Ang Mabuting Balita ng Panginoon.',
          peopleCue: 'Bayan',
          peopleText: 'Pinupuri ka namin, Panginoong Hesukristo.',
        );
      case PrayerLanguage.traditionalChinese:
        return const LiturgicalDialogue(
          ministerCue: '主祭',
          ministerText: '主基督的聖言。',
          peopleCue: '信友',
          peopleText: '基督，我們讚美祢。',
        );
      case PrayerLanguage.english:
        return const LiturgicalDialogue(
          ministerCue: 'Priest',
          ministerText: 'The Gospel of the Lord.',
          peopleCue: 'People',
          peopleText: 'Praise to you, Lord Jesus Christ.',
        );
    }
  }
}
