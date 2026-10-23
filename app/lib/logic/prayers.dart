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

  String get code {
    switch (this) {
      case PrayerLanguage.english:
        return 'english';
      case PrayerLanguage.spanish:
        return 'spanish';
      case PrayerLanguage.french:
        return 'french';
      case PrayerLanguage.italian:
        return 'italian';
      case PrayerLanguage.latin:
        return 'latin';
      case PrayerLanguage.vietnamese:
        return 'vietnamese';
      case PrayerLanguage.tagalog:
        return 'tagalog';
      case PrayerLanguage.traditionalChinese:
        return 'traditionalChinese';
    }
  }
}

class ChineseChar {
  String char;
  String pinyin;
  String? phraseId;

  ChineseChar([this.char = '', this.pinyin = '', this.phraseId]);

  factory ChineseChar.fromJson(Map<String, dynamic> map) {
    return ChineseChar(
      map['char'] as String? ?? '',
      map['pinyin'] as String? ?? '',
      map['phraseId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'char': char,
    'pinyin': pinyin,
    'phraseId': phraseId,
  };
}

class ChineseLine {
  List<ChineseChar>? chars;

  ChineseLine({this.chars});

  static ChineseLine? tryFromJson(
    dynamic rawLine, {
    bool requireCharsListWhenMap = false,
  }) {
    if (rawLine is List) {
      final List<ChineseChar> chars = [];
      for (final c in rawLine) {
        if (c is Map) {
          final cMap = c is Map<String, dynamic>
              ? c
              : Map<String, dynamic>.from(c);
          chars.add(ChineseChar.fromJson(cMap));
        }
      }
      return ChineseLine(chars: chars);
    }
    if (rawLine is Map) {
      final lineMap = rawLine is Map<String, dynamic>
          ? rawLine
          : Map<String, dynamic>.from(rawLine);
      final rawChars = lineMap['chars'];
      if (requireCharsListWhenMap && rawChars is! List) {
        return null;
      }
      final List<ChineseChar> chars = [];
      if (rawChars is List) {
        for (final c in rawChars) {
          if (c is Map) {
            final cMap = c is Map<String, dynamic>
                ? c
                : Map<String, dynamic>.from(c);
            chars.add(ChineseChar.fromJson(cMap));
          }
        }
      }
      return ChineseLine(chars: chars);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'chars': chars?.map((c) => c.toJson()).toList(),
  };
}

class PrayerToken {
  String text;
  String? id;

  PrayerToken([this.text = '', this.id]);

  factory PrayerToken.fromJson(Map<String, dynamic> map) {
    return PrayerToken(map['text'] as String? ?? '', map['id'] as String?);
  }

  Map<String, dynamic> toJson() => {'text': text, 'id': id};
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

  factory PrayerTranslation.fromJson(
    Map<String, dynamic> tMap, {
    bool strictChineseLineMap = false,
  }) {
    final rawChineseLines = tMap['chineseLines'] ?? tMap['chinese_lines'];
    List<ChineseLine>? chineseLines;
    if (rawChineseLines is List) {
      chineseLines = [];
      for (final line in rawChineseLines) {
        final parsed = ChineseLine.tryFromJson(
          line,
          requireCharsListWhenMap: strictChineseLineMap,
        );
        if (parsed != null) {
          chineseLines.add(parsed);
        }
      }
    }

    final rawTokens = tMap['tokens'];
    List<PrayerToken>? tokens;
    if (rawTokens is List) {
      tokens = [];
      for (final tok in rawTokens) {
        if (tok is Map) {
          final tokMap = tok is Map<String, dynamic>
              ? tok
              : Map<String, dynamic>.from(tok);
          tokens.add(PrayerToken.fromJson(tokMap));
        }
      }
    }

    return PrayerTranslation(
      title: tMap['title'] as String? ?? '',
      subtitle: tMap['subtitle'] as String? ?? '',
      text: tMap['text'] as String? ?? '',
      sourceName: (tMap['sourceName'] ?? tMap['source_name']) as String? ?? '',
      sourceUrl: (tMap['sourceUrl'] ?? tMap['source_url']) as String? ?? '',
      historyAuthor:
          (tMap['historyAuthor'] ?? tMap['history_author']) as String? ?? '',
      historyOrigin:
          (tMap['historyOrigin'] ?? tMap['history_origin']) as String? ?? '',
      historyDescription:
          (tMap['historyDescription'] ?? tMap['history_description'])
              as String? ??
          '',
      copyright: tMap['copyright'] as String? ?? '',
      chineseLines: chineseLines,
      tokens: tokens,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'text': text,
    'sourceName': sourceName,
    'sourceUrl': sourceUrl,
    'historyAuthor': historyAuthor,
    'historyOrigin': historyOrigin,
    'historyDescription': historyDescription,
    'copyright': copyright,
    'chineseLines': chineseLines?.map((line) => line.toJson()).toList(),
    'tokens': tokens?.map((tok) => tok.toJson()).toList(),
  };

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

  factory LocalizedTranslations.fromJson(Map<String, dynamic> map) {
    final langStr = map['languageCode'] as String? ?? 'english';
    final rawTransList = map['list'];
    List<PrayerTranslation>? translationList;
    if (rawTransList is List) {
      translationList = [];
      for (final tItem in rawTransList) {
        if (tItem is! Map) continue;
        final tMap = tItem is Map<String, dynamic>
            ? tItem
            : Map<String, dynamic>.from(tItem);
        translationList.add(PrayerTranslation.fromJson(tMap));
      }
    }
    return LocalizedTranslations(languageCode: langStr, list: translationList);
  }

  Map<String, dynamic> toJson() => {
    'languageCode': languageCode,
    'list': list?.map((trans) => trans.toJson()).toList(),
  };
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

  static Prayer? tryFromAssetJson(Map<String, dynamic> pMap) {
    final prayerId = pMap['id'] as String? ?? '';
    if (prayerId.isEmpty) return null;

    final defaultTitle = pMap['default_title'] as String? ?? '';
    final category = pMap['category'] as String? ?? '';
    final defaultOrder = pMap['default_order'] as int? ?? 0;

    final List<LocalizedTranslations> localizedTranslations = [];
    final rawTrans = pMap['translations'];
    if (rawTrans is Map) {
      final transMap = rawTrans is Map<String, dynamic>
          ? rawTrans
          : Map<String, dynamic>.from(rawTrans);

      for (final entry in transMap.entries) {
        final langStr = entry.key.toString();
        final rawTransList = entry.value;
        if (rawTransList is! List) continue;

        final List<PrayerTranslation> translationList = [];
        for (final tItem in rawTransList) {
          if (tItem is! Map) continue;
          final tMap = tItem is Map<String, dynamic>
              ? tItem
              : Map<String, dynamic>.from(tItem);
          translationList.add(
            PrayerTranslation.fromJson(tMap, strictChineseLineMap: true),
          );
        }

        localizedTranslations.add(
          LocalizedTranslations(languageCode: langStr, list: translationList),
        );
      }
    }

    return Prayer(
      prayerId: prayerId,
      defaultTitle: defaultTitle,
      category: category,
      defaultOrder: defaultOrder,
      hasAmen: pMap['has_amen'] as bool? ?? false,
      hash: pMap['hash'] as String? ?? '',
      localizedTranslations: localizedTranslations,
    );
  }

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
          languageCode: entry.key.code,
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
          (e) => e.code == item.languageCode,
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

  factory PrayerVersionPreference.fromJson(Map<String, dynamic> map) {
    return PrayerVersionPreference(
      map['key'] as String? ?? '',
      map['versionIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'versionIndex': versionIndex};

  PrayerVersionPreference copyWith({String? key, int? versionIndex}) {
    return PrayerVersionPreference(
      key ?? this.key,
      versionIndex ?? this.versionIndex,
    );
  }
}

enum AppThemeMode {
  marianBlue('marian_blue', 'Marian Blue'),
  liturgical('liturgical', 'Liturgical Season'),
  system('system', 'System Theme');

  final String code;
  final String label;
  const AppThemeMode(this.code, this.label);

  static AppThemeMode fromCode(String? code) {
    return AppThemeMode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AppThemeMode.marianBlue,
    );
  }
}

enum BibleNumberingSystem {
  vulgate(
    'vulgate',
    'Latin Vulgate (Traditional)',
    'Traditional Vulgate / Douay-Rheims / LXX numbering',
  ),
  modern(
    'modern',
    'Modern (Masoretic)',
    'Masoretic / Modern English numbering',
  ),
  dual(
    'dual',
    'Dual Numbering',
    'Shows primary numbering with alternate in parentheses',
  );

  final String code;
  final String label;
  final String description;
  const BibleNumberingSystem(this.code, this.label, this.description);

  static BibleNumberingSystem fromCode(String? code) {
    return BibleNumberingSystem.values.firstWhere(
      (e) => e.code == code,
      orElse: () => BibleNumberingSystem.vulgate,
    );
  }
}

class BibleRibbonBookmark {
  final int ribbonIndex; // 0 to 3
  final int bookNumber;
  final int chapter;

  const BibleRibbonBookmark({
    required this.ribbonIndex,
    required this.bookNumber,
    required this.chapter,
  });

  Map<String, dynamic> toJson() => {
    'ribbonIndex': ribbonIndex,
    'bookNumber': bookNumber,
    'chapter': chapter,
  };

  factory BibleRibbonBookmark.fromJson(Map<String, dynamic> json) =>
      BibleRibbonBookmark(
        ribbonIndex: json['ribbonIndex'] as int? ?? 0,
        bookNumber: json['bookNumber'] as int? ?? 1,
        chapter: json['chapter'] as int? ?? 1,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleRibbonBookmark &&
          runtimeType == other.runtimeType &&
          ribbonIndex == other.ribbonIndex &&
          bookNumber == other.bookNumber &&
          chapter == other.chapter;

  @override
  int get hashCode =>
      ribbonIndex.hashCode ^ bookNumber.hashCode ^ chapter.hashCode;
}

class UserSettings {
  int id = 1;
  String primaryLanguageCode;
  String compareLanguageCode;
  String primaryBibleTranslation;
  String compareBibleTranslation;
  List<PrayerVersionPreference>? preferredVersions;
  bool hapticsEnabled;
  String appThemeModeCode;
  bool sundayNotificationsEnabled;
  bool showBibleTranslationSelectors;
  String bibleNumberingSystemCode;
  int prayerCatalogVersion;
  int lastBibleBookNumber;
  int lastBibleChapter;
  bool missalReadingsOnly;
  List<String>? missalHiddenPrayers;
  bool angelusReminderEnabled;
  bool angelusMorningEnabled;
  bool angelusMiddayEnabled;
  bool angelusEveningEnabled;
  bool rosaryReminderEnabled;
  int rosaryReminderHour;
  int rosaryReminderMinute;
  bool morningPrayerReminderEnabled;
  int morningPrayerReminderHour;
  int morningPrayerReminderMinute;
  bool nightPrayerReminderEnabled;
  int nightPrayerReminderHour;
  int nightPrayerReminderMinute;
  List<BibleRibbonBookmark>? bibleRibbons;

  UserSettings({
    this.id = 1,
    this.primaryLanguageCode = 'english',
    this.compareLanguageCode = 'latin',
    this.primaryBibleTranslation = 'CPDV',
    this.compareBibleTranslation = 'none',
    this.preferredVersions,
    this.hapticsEnabled = true,
    this.appThemeModeCode = 'marian_blue',
    this.sundayNotificationsEnabled = true,
    this.showBibleTranslationSelectors = false,
    this.bibleNumberingSystemCode = 'vulgate',
    this.prayerCatalogVersion = 0,
    this.lastBibleBookNumber = 1,
    this.lastBibleChapter = 1,
    this.missalReadingsOnly = false,
    this.missalHiddenPrayers,
    this.angelusReminderEnabled = false,
    this.angelusMorningEnabled = false,
    this.angelusMiddayEnabled = true,
    this.angelusEveningEnabled = false,
    this.rosaryReminderEnabled = false,
    this.rosaryReminderHour = 20,
    this.rosaryReminderMinute = 0,
    this.morningPrayerReminderEnabled = false,
    this.morningPrayerReminderHour = 7,
    this.morningPrayerReminderMinute = 0,
    this.nightPrayerReminderEnabled = false,
    this.nightPrayerReminderHour = 21,
    this.nightPrayerReminderMinute = 30,
    this.bibleRibbons,
  });

  AppThemeMode get appThemeMode => AppThemeMode.fromCode(appThemeModeCode);
  set appThemeMode(AppThemeMode mode) => appThemeModeCode = mode.code;

  BibleNumberingSystem get bibleNumberingSystem =>
      BibleNumberingSystem.fromCode(bibleNumberingSystemCode);
  set bibleNumberingSystem(BibleNumberingSystem system) =>
      bibleNumberingSystemCode = system.code;

  PrayerLanguage get primaryLanguage => PrayerLanguage.values.firstWhere(
    (e) => e.code == primaryLanguageCode,
    orElse: () => PrayerLanguage.english,
  );

  PrayerLanguage? get compareLanguage {
    if (compareLanguageCode == 'none' || compareLanguageCode.isEmpty) {
      return null;
    }
    final match = PrayerLanguage.values.where(
      (e) => e.code == compareLanguageCode,
    );
    return match.isNotEmpty ? match.first : null;
  }

  int getPreferredVersionIndex(String key) {
    return preferredVersions
            ?.firstWhere(
              (p) => p.key == key,
              orElse: () => PrayerVersionPreference(),
            )
            .versionIndex ??
        0;
  }

  void setPreferredVersionIndex(String key, int versionIndex) {
    final list = List<PrayerVersionPreference>.from(preferredVersions ?? []);
    final idx = list.indexWhere((p) => p.key == key);
    if (idx >= 0) {
      list[idx].versionIndex = versionIndex;
    } else {
      list.add(PrayerVersionPreference(key, versionIndex));
    }
    preferredVersions = list;
  }

  UserSettings copyWith({
    int? id,
    String? primaryLanguageCode,
    String? compareLanguageCode,
    String? primaryBibleTranslation,
    String? compareBibleTranslation,
    List<PrayerVersionPreference>? preferredVersions,
    bool? hapticsEnabled,
    String? appThemeModeCode,
    bool? sundayNotificationsEnabled,
    bool? showBibleTranslationSelectors,
    String? bibleNumberingSystemCode,
    int? prayerCatalogVersion,
    int? lastBibleBookNumber,
    int? lastBibleChapter,
    bool? missalReadingsOnly,
    List<String>? missalHiddenPrayers,
    bool? angelusReminderEnabled,
    bool? angelusMorningEnabled,
    bool? angelusMiddayEnabled,
    bool? angelusEveningEnabled,
    bool? rosaryReminderEnabled,
    int? rosaryReminderHour,
    int? rosaryReminderMinute,
    bool? morningPrayerReminderEnabled,
    int? morningPrayerReminderHour,
    int? morningPrayerReminderMinute,
    bool? nightPrayerReminderEnabled,
    int? nightPrayerReminderHour,
    int? nightPrayerReminderMinute,
    List<BibleRibbonBookmark>? bibleRibbons,
  }) {
    return UserSettings(
      id: id ?? this.id,
      primaryLanguageCode: primaryLanguageCode ?? this.primaryLanguageCode,
      compareLanguageCode: compareLanguageCode ?? this.compareLanguageCode,
      primaryBibleTranslation:
          primaryBibleTranslation ?? this.primaryBibleTranslation,
      compareBibleTranslation:
          compareBibleTranslation ?? this.compareBibleTranslation,
      preferredVersions:
          preferredVersions ??
          this.preferredVersions?.map((p) => p.copyWith()).toList(),
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      appThemeModeCode: appThemeModeCode ?? this.appThemeModeCode,
      sundayNotificationsEnabled:
          sundayNotificationsEnabled ?? this.sundayNotificationsEnabled,
      showBibleTranslationSelectors:
          showBibleTranslationSelectors ?? this.showBibleTranslationSelectors,
      bibleNumberingSystemCode:
          bibleNumberingSystemCode ?? this.bibleNumberingSystemCode,
      prayerCatalogVersion: prayerCatalogVersion ?? this.prayerCatalogVersion,
      lastBibleBookNumber: lastBibleBookNumber ?? this.lastBibleBookNumber,
      lastBibleChapter: lastBibleChapter ?? this.lastBibleChapter,
      missalReadingsOnly: missalReadingsOnly ?? this.missalReadingsOnly,
      missalHiddenPrayers:
          missalHiddenPrayers ??
          (this.missalHiddenPrayers != null
              ? List<String>.from(this.missalHiddenPrayers!)
              : null),
      angelusReminderEnabled:
          angelusReminderEnabled ?? this.angelusReminderEnabled,
      angelusMorningEnabled:
          angelusMorningEnabled ?? this.angelusMorningEnabled,
      angelusMiddayEnabled: angelusMiddayEnabled ?? this.angelusMiddayEnabled,
      angelusEveningEnabled:
          angelusEveningEnabled ?? this.angelusEveningEnabled,
      rosaryReminderEnabled:
          rosaryReminderEnabled ?? this.rosaryReminderEnabled,
      rosaryReminderHour: rosaryReminderHour ?? this.rosaryReminderHour,
      rosaryReminderMinute: rosaryReminderMinute ?? this.rosaryReminderMinute,
      morningPrayerReminderEnabled:
          morningPrayerReminderEnabled ?? this.morningPrayerReminderEnabled,
      morningPrayerReminderHour:
          morningPrayerReminderHour ?? this.morningPrayerReminderHour,
      morningPrayerReminderMinute:
          morningPrayerReminderMinute ?? this.morningPrayerReminderMinute,
      nightPrayerReminderEnabled:
          nightPrayerReminderEnabled ?? this.nightPrayerReminderEnabled,
      nightPrayerReminderHour:
          nightPrayerReminderHour ?? this.nightPrayerReminderHour,
      nightPrayerReminderMinute:
          nightPrayerReminderMinute ?? this.nightPrayerReminderMinute,
      bibleRibbons:
          bibleRibbons ??
          (this.bibleRibbons != null
              ? List<BibleRibbonBookmark>.from(this.bibleRibbons!)
              : null),
    );
  }
}
