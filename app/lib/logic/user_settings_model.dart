import 'prayers.dart';

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

  static String prayerVersionKey(String prayerId, PrayerLanguage language) =>
      '${prayerId}_${language.code}';

  int getPrayerVersionIndex(String prayerId, PrayerLanguage language) =>
      getPreferredVersionIndex(prayerVersionKey(prayerId, language));

  void setPrayerVersionIndex(
    String prayerId,
    PrayerLanguage language,
    int index,
  ) => setPreferredVersionIndex(prayerVersionKey(prayerId, language), index);

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
