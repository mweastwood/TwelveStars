enum BibleApprovalStatus { imprimatur, noImprimatur, canonicalSourceText }

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
  });

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
      originDescription: 'Translated from the Latin Vulgate by English Catholic scholars at Douai & Rheims in 1582–1610, revised into modern English by Bp. Richard Challoner in 1749–1752.',
      churchUsage: 'The historic English Catholic standard for over 200 years, widely used in traditional devotions, missals, and litanies.',
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
      originDescription: 'Authoritative Latin edition ordered by the Council of Trent and promulgated by Pope Clement VIII in 1592, based on St. Jerome\'s 4th-century translation.',
      churchUsage: 'The official Latin Bible of the Roman Catholic Church and the Roman Rite liturgy for over 400 years.',
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
      originDescription: 'Translated directly from the Latin Vulgate into Spanish by Fr. José Miguel Petisco and Bp. Félix Torres Amat.',
      churchUsage: 'The most famous historic Spanish Catholic Bible translation, revered throughout Spain and Latin America.',
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
      originDescription: 'The first complete Spanish Bible translated from the Latin Vulgate by Bp. Felipe Scío de San Miguel under Royal Decree of King Charles III.',
      churchUsage: 'Historic standard for Spanish Catholic biblical study in the 18th and 19th centuries.',
    ),
    BibleTranslationInfo(
      code: 'CPDV',
      name: 'Catholic Public Domain Version',
      shortName: 'CPDV',
      languages: ['English'],
      primaryLanguageCode: 'en',
      publicationDate: '2009',
      publicDomainStatus: 'Public Domain (Open License)',
      approvalStatus: BibleApprovalStatus.noImprimatur,
      originDescription: 'A modern verse-by-verse English translation of the Clementine Latin Vulgate edited independently by lay scholar Ronald L. Conte Jr. in 2009.',
      churchUsage: 'Popular for open-source digital study platforms, side-by-side Vulgate reference, and mobile prayer applications.',
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
      originDescription: 'Ancient Greek translation of the Old Testament prepared by Jewish scholars in Alexandria, Egypt.',
      churchUsage: 'The primary Old Testament text quoted by the New Testament writers and Apostles, approved canonically by the Council of Rome (382) and Council of Trent (1546).',
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
      originDescription: 'The original Hebrew & Aramaic Old Testament manuscripts and Greek New Testament Received Text.',
      churchUsage: 'Recognized by Pope Pius XII (Divino Afflante Spiritu) and Vatican II (Dei Verbum) as the supreme textual authority for Catholic exegesis.',
    ),
  ];

  static BibleTranslationInfo getByCode(String code) {
    return allTranslations.firstWhere(
      (t) => t.code.toUpperCase() == code.toUpperCase(),
      orElse: () => allTranslations.first,
    );
  }
}
