enum BibleApprovalStatus { imprimatur, noImprimatur, canonicalSourceText }

typedef TranslationApprovalStatus = BibleApprovalStatus;

class BibleTranslationSelectorResult {
  final String primary;
  final String? secondary;
  final bool primaryChanged;

  const BibleTranslationSelectorResult({
    required this.primary,
    required this.secondary,
    this.primaryChanged = false,
  });

  String get primaryCode => primary;
  String? get secondaryCode => secondary;
  String? get compareCode => secondary;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleTranslationSelectorResult &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          secondary == other.secondary &&
          primaryChanged == other.primaryChanged;

  @override
  int get hashCode => Object.hash(primary, secondary, primaryChanged);

  @override
  String toString() =>
      'BibleTranslationSelectorResult(primary: $primary, secondary: $secondary, primaryChanged: $primaryChanged)';
}

class BibleTranslationInfo {
  final String code;
  final String name;
  final String shortName;
  final List<String> languages;
  final String primaryLanguageCode;
  final String publicationDate;
  final String publicDomainStatus;
  final BibleApprovalStatus approvalStatus;
  final String originDescription;
  final String churchUsage;
  final bool isOldTestamentOnly;

  const BibleTranslationInfo({
    required this.code,
    required this.name,
    required this.shortName,
    required this.languages,
    required this.primaryLanguageCode,
    required this.publicationDate,
    required this.publicDomainStatus,
    required this.approvalStatus,
    required this.originDescription,
    required this.churchUsage,
    this.isOldTestamentOnly = false,
  });

  bool supportsBook(int bookNumber) {
    if (isOldTestamentOnly && bookNumber > 46) {
      return false;
    }
    return true;
  }

  String? usfmAssetPathForBook(int bookNumber, String abbrev) {
    if (bookNumber < 1 || !supportsBook(bookNumber)) {
      return null;
    }
    final numStr = bookNumber.toString().padLeft(2, '0');
    switch (code.toUpperCase()) {
      case 'DRC':
        return 'assets/bible/drc/usfm/$numStr-$abbrev-ENG[B]DRC1899[pd].usfm';
      case 'JUN':
        return 'assets/bible/jun/usfm/$numStr-$abbrev-SPA[B]JUN1928[pd].usfm';
      case 'TAM':
        return 'assets/bible/tam/usfm/$numStr-$abbrev-SPA[B]TAM1836[pd].usfm';
      case 'VUL':
        return 'assets/bible/vul/usfm/$numStr-$abbrev-LAT[B]VUL1592[pd].usfm';
      case 'LXX':
        return 'assets/bible/lxx/usfm/$numStr-$abbrev-GRC[B]LXX[pd].usfm';
      case 'ORIG':
        return 'assets/bible/orig/usfm/$numStr-$abbrev-ORIG[pd].usfm';
      case 'CPDV':
      case 'CPDV2025':
      case 'CPDV2009':
        return 'assets/bible/cpdv/usfm/$numStr-$abbrev-ENG[B]CPDV2025[pd].usfm';
      default:
        return null;
    }
  }

  String get approvalStatusLabel {
    switch (approvalStatus) {
      case BibleApprovalStatus.imprimatur:
        return 'Imprimatur';
      case BibleApprovalStatus.noImprimatur:
        return 'No Imprimatur';
      case BibleApprovalStatus.canonicalSourceText:
        return 'Canonical Source Text';
    }
  }

  static const List<String> filterTags = [
    'All',
    'English',
    'Catholic Approved',
    'Sacred Languages',
    'Spanish',
    'Chinese',
    'Arabic',
  ];

  static const List<String> dialogFilterTags = [
    'Imprimatur',
    'English',
    'Latin',
    'Spanish',
    'Ancient',
  ];

  bool matchesFilterTag(String tag) {
    final normalized = tag.trim();
    if (normalized.isEmpty || normalized == 'All') {
      return true;
    }
    switch (normalized) {
      case 'Imprimatur':
      case 'Catholic Approved':
        return approvalStatus == BibleApprovalStatus.imprimatur;
      case 'English':
        return primaryLanguageCode == 'en' ||
            languages.any((l) => l.toLowerCase() == 'english');
      case 'Latin':
        return primaryLanguageCode == 'la' ||
            languages.any((l) => l.toLowerCase() == 'latin');
      case 'Spanish':
        return primaryLanguageCode == 'es' ||
            languages.any((l) => l.toLowerCase() == 'spanish');
      case 'Chinese':
        return primaryLanguageCode == 'zh' ||
            languages.any((l) => l.toLowerCase().contains('chinese'));
      case 'Arabic':
        return primaryLanguageCode == 'ar' ||
            languages.any((l) => l.toLowerCase().contains('arabic'));
      case 'Ancient':
        return approvalStatus == BibleApprovalStatus.canonicalSourceText ||
            primaryLanguageCode == 'el' ||
            primaryLanguageCode == 'he';
      case 'Sacred Languages':
        return approvalStatus == BibleApprovalStatus.canonicalSourceText ||
            primaryLanguageCode == 'la' ||
            primaryLanguageCode == 'el' ||
            primaryLanguageCode == 'he';
      default:
        final lower = normalized.toLowerCase();
        return primaryLanguageCode.toLowerCase() == lower ||
            languages.any((l) => l.toLowerCase().contains(lower));
    }
  }

  bool matchesSearchQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    final lower = trimmed.toLowerCase();
    return code.toLowerCase().contains(lower) ||
        name.toLowerCase().contains(lower) ||
        shortName.toLowerCase().contains(lower) ||
        languages.any((l) => l.toLowerCase().contains(lower)) ||
        originDescription.toLowerCase().contains(lower) ||
        churchUsage.toLowerCase().contains(lower);
  }

  static List<BibleTranslationInfo> filterTranslations({
    String query = '',
    String selectedTag = 'All',
    Iterable<String> selectedFilters = const [],
    List<BibleTranslationInfo>? source,
  }) {
    final items = source ?? allTranslations;
    return items.where((t) {
      if (!t.matchesSearchQuery(query)) {
        return false;
      }
      if (selectedTag.isNotEmpty &&
          selectedTag != 'All' &&
          !t.matchesFilterTag(selectedTag)) {
        return false;
      }
      for (final filter in selectedFilters) {
        if (!t.matchesFilterTag(filter)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  static String? normalizeSecondaryCode(String? code) {
    if (code == null || code == 'none' || code.isEmpty) {
      return null;
    }
    return code;
  }

  static BibleTranslationSelectorResult resolvePrimarySelection({
    required String currentPrimary,
    required String? currentSecondary,
    required String newPrimary,
  }) {
    final normalizedSecondary = normalizeSecondaryCode(currentSecondary);
    final nextSecondary = normalizedSecondary == newPrimary
        ? null
        : normalizedSecondary;
    return BibleTranslationSelectorResult(
      primary: newPrimary,
      secondary: nextSecondary,
      primaryChanged: newPrimary != currentPrimary,
    );
  }

  static BibleTranslationSelectorResult resolveSecondarySelection({
    required String currentPrimary,
    required String? currentSecondary,
    required String? newSecondary,
  }) {
    final normalizedCurrentSecondary = normalizeSecondaryCode(currentSecondary);
    final normalizedNewSecondary = normalizeSecondaryCode(newSecondary);

    if (normalizedNewSecondary == null) {
      return BibleTranslationSelectorResult(
        primary: currentPrimary,
        secondary: null,
        primaryChanged: false,
      );
    }

    var nextPrimary = currentPrimary;
    var primaryChanged = false;

    if (currentPrimary == normalizedNewSecondary) {
      if (normalizedCurrentSecondary != null &&
          normalizedCurrentSecondary != normalizedNewSecondary) {
        nextPrimary = normalizedCurrentSecondary;
      } else {
        nextPrimary = allTranslations
            .map((t) => t.code)
            .firstWhere(
              (c) => c != normalizedNewSecondary,
              orElse: () => currentPrimary,
            );
      }
      primaryChanged = true;
    }

    return BibleTranslationSelectorResult(
      primary: nextPrimary,
      secondary: normalizedNewSecondary,
      primaryChanged: primaryChanged,
    );
  }

  static BibleTranslationSelectorResult swapSelections({
    required String currentPrimary,
    required String? currentSecondary,
  }) {
    final normalizedSecondary = normalizeSecondaryCode(currentSecondary);
    if (normalizedSecondary == null) {
      return BibleTranslationSelectorResult(
        primary: currentPrimary,
        secondary: null,
        primaryChanged: false,
      );
    }
    return BibleTranslationSelectorResult(
      primary: normalizedSecondary,
      secondary: currentPrimary,
      primaryChanged: normalizedSecondary != currentPrimary,
    );
  }

  static const List<BibleTranslationInfo> allTranslations = [
    BibleTranslationInfo(
      code: 'DRC',
      name: 'Douay-Rheims Bible (Challoner Revision)',
      shortName: 'Douay-Rheims',
      languages: ['English'],
      primaryLanguageCode: 'en',
      publicationDate: '1749–1752',
      publicDomainStatus: 'Public Domain (Historic)',
      approvalStatus: BibleApprovalStatus.imprimatur,
      originDescription:
          'Translated from the Latin Vulgate by English Catholic scholars at Douai & Rheims in 1582–1610, revised into modern English by Bp. Richard Challoner in 1749–1752.',
      churchUsage:
          'The historic English Catholic standard for over 200 years, widely used in traditional devotions, missals, and litanies.',
    ),
    BibleTranslationInfo(
      code: 'VUL',
      name: 'Sixto-Clementine Vulgate (Biblia Sacra)',
      shortName: 'Clementine Vulgate',
      languages: ['Latin'],
      primaryLanguageCode: 'la',
      publicationDate: '1592',
      publicDomainStatus: 'Public Domain (Historic)',
      approvalStatus: BibleApprovalStatus.imprimatur,
      originDescription:
          'Authoritative Latin edition ordered by the Council of Trent and promulgated by Pope Clement VIII in 1592, based on St. Jerome\'s 4th-century translation.',
      churchUsage:
          'The official Latin Bible of the Roman Catholic Church and the Roman Rite liturgy for over 400 years.',
    ),
    BibleTranslationInfo(
      code: 'JUN',
      name: 'Biblia Torres Amat',
      shortName: 'Torres Amat',
      languages: ['Spanish'],
      primaryLanguageCode: 'es',
      publicationDate: '1825',
      publicDomainStatus: 'Public Domain (Historic)',
      approvalStatus: BibleApprovalStatus.imprimatur,
      originDescription:
          'Translated directly from the Latin Vulgate into Spanish by Fr. José Miguel Petisco and Bp. Félix Torres Amat.',
      churchUsage:
          'The most famous historic Spanish Catholic Bible translation, revered throughout Spain and Latin America.',
    ),
    BibleTranslationInfo(
      code: 'TAM',
      name: 'Biblia de Scío de San Miguel',
      shortName: 'Scío de San Miguel',
      languages: ['Spanish'],
      primaryLanguageCode: 'es',
      publicationDate: '1790–1793',
      publicDomainStatus: 'Public Domain (Historic)',
      approvalStatus: BibleApprovalStatus.imprimatur,
      originDescription:
          'The first complete Spanish Bible translated from the Latin Vulgate by Bp. Felipe Scío de San Miguel under Royal Decree of King Charles III.',
      churchUsage:
          'Historic standard for Spanish Catholic biblical study in the 18th and 19th centuries.',
    ),
    BibleTranslationInfo(
      code: 'CPDV',
      name: 'Catholic Public Domain Version',
      shortName: 'CPDV',
      languages: ['English'],
      primaryLanguageCode: 'en',
      publicationDate: '2025',
      publicDomainStatus: 'Public Domain (Open License)',
      approvalStatus: BibleApprovalStatus.noImprimatur,
      originDescription:
          'A modern verse-by-verse English translation of the Clementine Latin Vulgate edited by Ronald L. Conte Jr., updated with all errata and text revisions through 2025.',
      churchUsage:
          'Popular for open-source digital study platforms, side-by-side Vulgate reference, and mobile prayer applications.',
    ),
    BibleTranslationInfo(
      code: 'LXX',
      name: 'Septuaginta (LXX)',
      shortName: 'Septuagint',
      languages: ['Greek (Ancient)'],
      primaryLanguageCode: 'el',
      publicationDate: 'c. 285–150 BC',
      publicDomainStatus: 'Public Domain (Ancient)',
      approvalStatus: BibleApprovalStatus.canonicalSourceText,
      originDescription:
          'Ancient Greek translation of the Old Testament prepared by Jewish scholars in Alexandria, Egypt.',
      churchUsage:
          'The primary Old Testament text quoted by the New Testament writers and Apostles, approved canonically by the Council of Rome (382) and Council of Trent (1546).',
      isOldTestamentOnly: true,
    ),
    BibleTranslationInfo(
      code: 'ORIG',
      name: 'Original Languages (Hebrew / Aramaic / Greek)',
      shortName: 'Original Languages',
      languages: ['Hebrew', 'Aramaic', 'Greek'],
      primaryLanguageCode: 'he',
      publicationDate: 'Ancient',
      publicDomainStatus: 'Public Domain (Ancient)',
      approvalStatus: BibleApprovalStatus.canonicalSourceText,
      originDescription:
          'The original Hebrew & Aramaic Old Testament manuscripts and Greek New Testament Received Text.',
      churchUsage:
          'Recognized by Pope Pius XII (Divino Afflante Spiritu) and Vatican II (Dei Verbum) as the supreme textual authority for Catholic exegesis.',
    ),
  ];

  static BibleTranslationInfo? tryGetByCode(String code) {
    final upper = code.trim().toUpperCase();
    if (upper == 'CPDV2025' || upper == 'CPDV2009') {
      return allTranslations.firstWhere((t) => t.code == 'CPDV');
    }
    for (final t in allTranslations) {
      if (t.code.toUpperCase() == upper) {
        return t;
      }
    }
    return null;
  }

  static BibleTranslationInfo getByCode(String code) {
    return tryGetByCode(code) ?? allTranslations.first;
  }

  static BibleTranslationInfo resolveForBook(
    String preferredCode,
    int bookNumber, {
    String fallbackCode = 'CPDV',
  }) {
    final preferred = tryGetByCode(preferredCode);
    if (preferred != null && preferred.supportsBook(bookNumber)) {
      return preferred;
    }
    final fallback = tryGetByCode(fallbackCode) ?? getByCode(fallbackCode);
    if (fallback.supportsBook(bookNumber)) {
      return fallback;
    }
    return allTranslations.firstWhere(
      (t) => t.supportsBook(bookNumber),
      orElse: () => allTranslations.first,
    );
  }
}
