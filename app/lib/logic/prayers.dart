enum PrayerLanguage {
  english(name: 'English', nativeName: 'English', flag: '🇺🇸'),
  spanish(name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
  french(name: 'French', nativeName: 'Français', flag: '🇫🇷'),
  italian(name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
  latin(name: 'Latin', nativeName: 'Latina', flag: '🇻🇦'),
  vietnamese(name: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳'),
  tagalog(name: 'Tagalog', nativeName: 'Tagalog', flag: '🇵🇭'),
  traditionalChinese(
    name: 'Traditional Chinese',
    nativeName: '繁體中文',
    flag: '🇹🇼',
  );

  final String name;
  final String nativeName;
  final String flag;

  const PrayerLanguage({
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

class ChineseChar {
  final String char;
  final String pinyin;

  const ChineseChar(this.char, [this.pinyin = '']);
}

class PrayerTranslation {
  final String title;
  final String subtitle;
  final String text;
  final String sourceName;
  final String sourceUrl;
  final List<List<ChineseChar>>? chineseLines;

  const PrayerTranslation({
    required this.title,
    required this.subtitle,
    required this.text,
    required this.sourceName,
    required this.sourceUrl,
    this.chineseLines,
  });
}

class Prayer {
  final String id;
  final String defaultTitle;
  final Map<PrayerLanguage, List<PrayerTranslation>> translations;

  const Prayer({
    required this.id,
    required this.defaultTitle,
    required this.translations,
  });
}
