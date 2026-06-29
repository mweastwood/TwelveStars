import 'package:isar_plus/isar_plus.dart';

part 'prayers.g.dart';

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

@embedded
class ChineseChar {
  String char;
  String pinyin;
  String? phraseId;

  ChineseChar([this.char = '', this.pinyin = '', this.phraseId]);
}

@embedded
class ChineseLine {
  List<ChineseChar>? chars;

  ChineseLine({this.chars});
}

@embedded
class PrayerToken {
  String text;
  String? id;

  PrayerToken([this.text = '', this.id]);
}

@embedded
class PrayerTranslation {
  String title;
  String subtitle;
  String text;
  String sourceName;
  String sourceUrl;
  List<ChineseLine>? chineseLines;
  List<PrayerToken>? tokens;

  PrayerTranslation({
    this.title = '',
    this.subtitle = '',
    this.text = '',
    this.sourceName = '',
    this.sourceUrl = '',
    this.chineseLines,
    this.tokens,
  });

  factory PrayerTranslation.mock({
    String title = '',
    String subtitle = '',
    String text = '',
    String sourceName = '',
    String sourceUrl = '',
    List<List<ChineseChar>>? chineseLines,
    List<PrayerToken>? tokens,
  }) {
    return PrayerTranslation(
      title: title,
      subtitle: subtitle,
      text: text,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      chineseLines: chineseLines
          ?.map((line) => ChineseLine(chars: line))
          .toList(),
      tokens: tokens,
    );
  }
}

@embedded
class LocalizedTranslations {
  String languageCode;
  List<PrayerTranslation>? list;

  LocalizedTranslations({this.languageCode = '', this.list});
}

@collection
class Prayer {
  @Id()
  int isarId = 0;

  @Index(unique: true)
  String prayerId;

  String defaultTitle;
  String category;
  int defaultOrder;

  List<LocalizedTranslations>? localizedTranslations;

  Prayer({
    this.isarId = 0,
    this.prayerId = '',
    this.defaultTitle = '',
    this.category = '',
    this.defaultOrder = 0,
    this.localizedTranslations,
  });

  factory Prayer.mock({
    required String id,
    required String defaultTitle,
    required Map<PrayerLanguage, List<PrayerTranslation>> translations,
    String category = 'starter',
    int defaultOrder = 0,
  }) {
    return Prayer(
      prayerId: id,
      defaultTitle: defaultTitle,
      category: category,
      defaultOrder: defaultOrder,
      localizedTranslations: translations.entries.map((entry) {
        return LocalizedTranslations(
          languageCode: entry.key.toString().split('.').last,
          list: entry.value,
        );
      }).toList(),
    );
  }

  @ignore
  String get idString => prayerId;

  @ignore
  Map<PrayerLanguage, List<PrayerTranslation>> get translations {
    final map = <PrayerLanguage, List<PrayerTranslation>>{};
    if (localizedTranslations != null) {
      for (final item in localizedTranslations!) {
        final lang = PrayerLanguage.values.firstWhere(
          (e) => e.toString().split('.').last == item.languageCode,
          orElse: () => PrayerLanguage.english,
        );
        map[lang] = item.list ?? [];
      }
    }
    return map;
  }
}
