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

  static const Map<PrayerLanguage, List<String>> _localizedNames = {
    PrayerLanguage.latin: ['Matthǽum', 'Marcum', 'Lucam', 'Joánnem'],
    PrayerLanguage.spanish: ['Mateo', 'Marcos', 'Lucas', 'Juan'],
    PrayerLanguage.vietnamese: ['Mátthêu', 'Mác-cô', 'Luca', 'Gioan'],
    PrayerLanguage.french: ['Matthieu', 'Marc', 'Luc', 'Jean'],
    PrayerLanguage.italian: ['Matteo', 'Marco', 'Luca', 'Giovanni'],
    PrayerLanguage.tagalog: ['Mateo', 'Marcos', 'Lucas', 'Juan'],
    PrayerLanguage.traditionalChinese: ['瑪竇', '馬爾谷', '路加', '若望'],
    PrayerLanguage.english: ['Matthew', 'Mark', 'Luke', 'John'],
  };

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
    return (_localizedNames[language] ??
        _localizedNames[PrayerLanguage.english]!)[index];
  }
}

/// Provides standard liturgical dialogues and responses for Lectionary readings.
class LectionaryResponses {
  const LectionaryResponses._();

  // [lectorCue, priestCue, peopleCue,
  //  readingMinister, readingPeople,
  //  greetingMinister, greetingPeople,
  //  gospelAnnouncementTemplate, gospelAnnouncementPeople,
  //  gospelConcludingMinister, gospelConcludingPeople]
  static const Map<PrayerLanguage, List<String>> _dialoguesByLanguage = {
    PrayerLanguage.latin: [
      'Lector',
      'Sacerdos',
      'Populus',
      'Verbum Dómini.',
      'Deo grátias.',
      'Dóminus vobíscum.',
      'Et cum spíritu tuo.',
      'Léctio sancti Evangélii secúndum {evangelist}.',
      'Glória tibi, Dómine.',
      'Verbum Dómini.',
      'Laus tibi, Christe.',
    ],
    PrayerLanguage.spanish: [
      'Lector',
      'Sacerdote',
      'Pueblo',
      'Palabra de Dios.',
      'Te alabamos, Señor.',
      'El Señor esté con ustedes.',
      'Y con tu espíritu.',
      'Lectura del santo Evangelio según san {evangelist}.',
      'Gloria a ti, Señor.',
      'Palabra del Señor.',
      'Gloria a ti, Señor Jesús.',
    ],
    PrayerLanguage.vietnamese: [
      'Người đọc',
      'Linh mục',
      'Cộng đoàn',
      'Đó là Lời Chúa.',
      'Tạ ơn Chúa.',
      'Chúa ở cùng anh chị em.',
      'Và ở cùng cha.',
      'Tin Mừng Chúa Giêsu Kitô theo thánh {evangelist}.',
      'Lạy Chúa, vinh danh Chúa.',
      'Đó là Lời Chúa.',
      'Lạy Chúa Kitô, ngợi khen Chúa.',
    ],
    PrayerLanguage.french: [
      'Lecteur',
      'Prêtre',
      'Peuple',
      'Parole du Seigneur.',
      'Nous rendons grâce à Dieu.',
      'Le Seigneur soit avec vous.',
      'Et avec votre esprit.',
      'Évangile de Jésus Christ selon saint {evangelist}.',
      'Gloire à toi, Seigneur.',
      'Acclamons la Parole de Dieu.',
      'Louange à toi, Seigneur Jésus.',
    ],
    PrayerLanguage.italian: [
      'Lettore',
      'Sacerdote',
      'Popolo',
      'Parola di Dio.',
      'Rendiamo grazie a Dio.',
      'Il Signore sia con voi.',
      'E con il tuo spirito.',
      'Dal Vangelo secondo {evangelist}.',
      'Gloria a te, o Signore.',
      'Parola del Signore.',
      'Lode a te, o Cristo.',
    ],
    PrayerLanguage.tagalog: [
      'Tagabasa',
      'Pari',
      'Bayan',
      'Salita ng Diyos.',
      'Salamat sa Diyos.',
      'Sumainyo ang Panginoon.',
      'At sumaiyo rin.',
      'Ang Mabuting Balita ng Panginoon ayon kay San {evangelist}.',
      'Papuri sa Iyo, Panginoon.',
      'Ang Mabuting Balita ng Panginoon.',
      'Pinupuri ka namin, Panginoong Hesukristo.',
    ],
    PrayerLanguage.traditionalChinese: [
      '讀經員',
      '主祭',
      '信友',
      '上主的聖言。',
      '感謝天主。',
      '願主與你們同在。',
      '也與你的心靈同在。',
      '恭讀聖{evangelist}福音。',
      '主，願光榮歸於祢。',
      '主基督的聖言。',
      '基督，我們讚美祢。',
    ],
    PrayerLanguage.english: [
      'Lector',
      'Priest',
      'People',
      'The word of the Lord.',
      'Thanks be to God.',
      'The Lord be with you.',
      'And with your spirit.',
      'A reading from the holy Gospel according to {evangelist}.',
      'Glory to you, O Lord.',
      'The Gospel of the Lord.',
      'Praise to you, Lord Jesus Christ.',
    ],
  };

  static List<String> _entry(PrayerLanguage language) =>
      _dialoguesByLanguage[language] ??
      _dialoguesByLanguage[PrayerLanguage.english]!;

  /// Concluding dialogue for First and Second readings (and other non-Gospel readings).
  static LiturgicalDialogue getReadingConcludingDialogue(
    PrayerLanguage language,
  ) {
    final d = _entry(language);
    return LiturgicalDialogue(
      ministerCue: d[0],
      ministerText: d[3],
      peopleCue: d[2],
      peopleText: d[4],
    );
  }

  /// Initial greeting before the Gospel ("The Lord be with you...").
  static LiturgicalDialogue getGospelIntroGreeting(PrayerLanguage language) {
    final d = _entry(language);
    return LiturgicalDialogue(
      ministerCue: d[1],
      ministerText: d[5],
      peopleCue: d[2],
      peopleText: d[6],
    );
  }

  /// Gospel announcement dialogue ("A reading from the holy Gospel according to {Evangelist}...").
  static LiturgicalDialogue getGospelIntroAnnouncement(
    PrayerLanguage language,
    Evangelist? evangelist,
  ) {
    final evangelistName = evangelist?.localizedName(language) ?? 'N.';
    final d = _entry(language);
    return LiturgicalDialogue(
      ministerCue: d[1],
      ministerText: d[7].replaceFirst('{evangelist}', evangelistName),
      peopleCue: d[2],
      peopleText: d[8],
    );
  }

  /// Concluding acclamation following the Gospel reading.
  static LiturgicalDialogue getGospelConcludingDialogue(
    PrayerLanguage language,
  ) {
    final d = _entry(language);
    return LiturgicalDialogue(
      ministerCue: d[1],
      ministerText: d[9],
      peopleCue: d[2],
      peopleText: d[10],
    );
  }
}
