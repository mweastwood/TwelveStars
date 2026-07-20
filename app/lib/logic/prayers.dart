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

  String get amenText {
    switch (this) {
      case PrayerLanguage.spanish:
        return 'Amén';
      case PrayerLanguage.traditionalChinese:
        return '亞孟';
      default:
        return 'Amen';
    }
  }
}

class ChineseChar {
  String char;
  String pinyin;
  String? phraseId;

  ChineseChar([this.char = '', this.pinyin = '', this.phraseId]);
}

class ChineseLine {
  List<ChineseChar>? chars;

  ChineseLine({this.chars});
}

class PrayerToken {
  String text;
  String? id;

  PrayerToken([this.text = '', this.id]);
}

class PrayerTranslation {
  String title;
  String subtitle;
  String text;
  String sourceName;
  String sourceUrl;
  String historyAuthor;
  String historyOrigin;
  String historyDescription;
  String copyright;
  List<ChineseLine>? chineseLines;
  List<PrayerToken>? tokens;

  PrayerTranslation({
    this.title = '',
    this.subtitle = '',
    this.text = '',
    this.sourceName = '',
    this.sourceUrl = '',
    this.historyAuthor = '',
    this.historyOrigin = '',
    this.historyDescription = '',
    this.copyright = '',
    this.chineseLines,
    this.tokens,
  });

  factory PrayerTranslation.mock({
    String title = '',
    String subtitle = '',
    String text = '',
    String sourceName = '',
    String sourceUrl = '',
    String historyAuthor = '',
    String historyOrigin = '',
    String historyDescription = '',
    String copyright = '',
    List<List<ChineseChar>>? chineseLines,
    List<PrayerToken>? tokens,
  }) {
    return PrayerTranslation(
      title: title,
      subtitle: subtitle,
      text: text,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      historyAuthor: historyAuthor,
      historyOrigin: historyOrigin,
      historyDescription: historyDescription,
      copyright: copyright,
      chineseLines: chineseLines
          ?.map((line) => ChineseLine(chars: line))
          .toList(),
      tokens: tokens,
    );
  }
}

class LocalizedTranslations {
  String languageCode;
  List<PrayerTranslation>? list;

  LocalizedTranslations({this.languageCode = '', this.list});
}

class Prayer {
  int isarId = 0;
  String prayerId;
  String defaultTitle;
  String category;
  int defaultOrder;
  bool hasAmen;
  String hash;
  List<LocalizedTranslations>? localizedTranslations;

  Prayer({
    this.isarId = 0,
    this.prayerId = '',
    this.defaultTitle = '',
    this.category = '',
    this.defaultOrder = 0,
    this.hasAmen = false,
    this.hash = '',
    this.localizedTranslations,
  });

  factory Prayer.mock({
    required String id,
    required String defaultTitle,
    required Map<PrayerLanguage, List<PrayerTranslation>> translations,
    String category = 'starter',
    int defaultOrder = 0,
    bool hasAmen = false,
  }) {
    return Prayer(
      prayerId: id,
      defaultTitle: defaultTitle,
      category: category,
      defaultOrder: defaultOrder,
      hasAmen: hasAmen,
      localizedTranslations: translations.entries.map((entry) {
        return LocalizedTranslations(
          languageCode: entry.key.name,
          list: entry.value,
        );
      }).toList(),
    );
  }

  String get idString => prayerId;

  Map<PrayerLanguage, List<PrayerTranslation>> get translations {
    final map = <PrayerLanguage, List<PrayerTranslation>>{};
    if (localizedTranslations != null) {
      for (final item in localizedTranslations!) {
        final lang = PrayerLanguage.values.firstWhere(
          (e) => e.name == item.languageCode,
          orElse: () => PrayerLanguage.english,
        );
        map[lang] = item.list ?? [];
      }
    }
    return map;
  }
}

class PrayerVersionPreference {
  String key;
  int versionIndex;

  PrayerVersionPreference([this.key = '', this.versionIndex = 0]);
}

class UserSettings {
  int id = 1;
  String primaryLanguageCode;
  String compareLanguageCode;
  String primaryBibleTranslation;
  String compareBibleTranslation;
  List<PrayerVersionPreference>? preferredVersions;

  UserSettings({
    this.id = 1,
    this.primaryLanguageCode = 'english',
    this.compareLanguageCode = 'latin',
    this.primaryBibleTranslation = 'CPDV',
    this.compareBibleTranslation = 'none',
    this.preferredVersions,
  });

  PrayerLanguage get primaryLanguage => PrayerLanguage.values.firstWhere(
    (e) => e.name == primaryLanguageCode,
    orElse: () => PrayerLanguage.english,
  );

  PrayerLanguage get compareLanguage => PrayerLanguage.values.firstWhere(
    (e) => e.name == compareLanguageCode,
    orElse: () => PrayerLanguage.latin,
  );
}
