import 'dart:math';

import 'package:twelve_stars/logic/saint_category_classifier.dart';

export 'package:twelve_stars/logic/saint_category_classifier.dart';

/// Major categorization of saints for visual icon representation and filtering.
enum SaintCategory {
  group,
  holyFamily,
  angel,
  patriarch,
  prophet,
  judge,
  apostle,
  evangelist,
  doctor,
  pope,
  bishop,
  priest,
  deacon,
  brother,
  nun,
  monarch,
  martyr,
  healerMissionary,
  virgin,
  mystic,
  laity,
  other;

  String get label {
    switch (this) {
      case SaintCategory.group:
        return 'Group';
      case SaintCategory.holyFamily:
        return 'Holy Family';
      case SaintCategory.angel:
        return 'Archangel & Angel';
      case SaintCategory.patriarch:
        return 'Patriarch';
      case SaintCategory.prophet:
        return 'Prophet';
      case SaintCategory.judge:
        return 'Judge';
      case SaintCategory.apostle:
        return 'Apostle';
      case SaintCategory.evangelist:
        return 'Evangelist';
      case SaintCategory.doctor:
        return 'Doctor of the Church';
      case SaintCategory.pope:
        return 'Pope';
      case SaintCategory.bishop:
        return 'Bishop';
      case SaintCategory.priest:
        return 'Priest';
      case SaintCategory.deacon:
        return 'Deacon';
      case SaintCategory.brother:
        return 'Brother';
      case SaintCategory.nun:
        return 'Nun';
      case SaintCategory.monarch:
        return 'Ruler & Monarch';
      case SaintCategory.martyr:
        return 'Martyr';
      case SaintCategory.healerMissionary:
        return 'Healer & Missionary';
      case SaintCategory.virgin:
        return 'Virgin & Consecrated';
      case SaintCategory.mystic:
        return 'Mystic & Contemplative';
      case SaintCategory.laity:
        return 'Laity';
      case SaintCategory.other:
        return 'Saint';
    }
  }

  /// Display label formatted for plural filter chips in UI filtering.
  String get filterLabel {
    switch (this) {
      case SaintCategory.group:
        return 'Group';
      case SaintCategory.holyFamily:
        return 'Holy Family';
      case SaintCategory.angel:
        return 'Angels';
      case SaintCategory.patriarch:
        return 'Patriarchs';
      case SaintCategory.prophet:
        return 'Prophets';
      case SaintCategory.judge:
        return 'Judges';
      case SaintCategory.apostle:
        return 'Apostles';
      case SaintCategory.evangelist:
        return 'Evangelists';
      case SaintCategory.doctor:
        return 'Doctors of the Church';
      case SaintCategory.pope:
        return 'Popes';
      case SaintCategory.bishop:
        return 'Bishops';
      case SaintCategory.priest:
        return 'Priests';
      case SaintCategory.deacon:
        return 'Deacons';
      case SaintCategory.brother:
        return 'Brothers';
      case SaintCategory.nun:
        return 'Nuns';
      case SaintCategory.monarch:
        return 'Rulers & Monarchs';
      case SaintCategory.martyr:
        return 'Martyrs';
      case SaintCategory.healerMissionary:
        return 'Healers & Missionaries';
      case SaintCategory.virgin:
        return 'Virgins & Consecrated';
      case SaintCategory.mystic:
        return 'Mystics & Contemplatives';
      case SaintCategory.laity:
        return 'Laity';
      case SaintCategory.other:
        return 'Other';
    }
  }
}

/// Historical eras for timeline filtering.
enum SaintEra {
  all,
  oldCovenant, // Old Testament / BC (<= 0)
  earlyChurch, // 1st - 5th Century (1 - 500)
  medieval, // 6th - 14th Century (501 - 1499)
  reformation, // 15th - 18th Century (1500 - 1799)
  modern; // 19th - 21st Century (1800+)

  String get label {
    switch (this) {
      case SaintEra.all:
        return 'All Eras';
      case SaintEra.oldCovenant:
        return 'Old Covenant (BC)';
      case SaintEra.earlyChurch:
        return 'Early Church (1st–5th c.)';
      case SaintEra.medieval:
        return 'Medieval (6th–14th c.)';
      case SaintEra.reformation:
        return 'Reformation & Early Modern (15th–18th c.)';
      case SaintEra.modern:
        return 'Modern & Contemporary (19th–21st c.)';
    }
  }
}

/// Sorting options for the saint database.
enum SaintSortOption {
  nameAsc,
  nameDesc,
  feastDay,
  chronologicalAsc,
  chronologicalDesc,
  doctorsFirst;

  String get label {
    switch (this) {
      case SaintSortOption.nameAsc:
        return 'Name (A–Z)';
      case SaintSortOption.nameDesc:
        return 'Name (Z–A)';
      case SaintSortOption.feastDay:
        return 'Feast Day (Jan–Dec)';
      case SaintSortOption.chronologicalAsc:
        return 'Timeline (Oldest first)';
      case SaintSortOption.chronologicalDesc:
        return 'Timeline (Newest first)';
      case SaintSortOption.doctorsFirst:
        return 'Doctors & Apostles first';
    }
  }
}

/// Multi-dimensional spiritual feature embedding representing a saint's
/// charism, temperament, era, and vocational profile.
class SaintEmbedding {
  /// Contemplative / Monastic / Hermit (-1.0) vs Active Charity / Missionary (+1.0).
  final double contemplativeVsActive;

  /// Intellectual / Doctor / Theologian (-1.0) vs Heart-Centered / Devotional / Simple Faith (+1.0).
  final double intellectualVsDevotional;

  /// Bold Courage / Martyr / Defender (-1.0) vs Gentle Mercy / Peacemaker / Quiet Service (+1.0).
  final double courageVsMercy;

  /// Ancient / Biblical / Early Church (-1.0) vs Modern / Contemporary (+1.0).
  final double ancientVsModern;

  /// Obscurity / Poverty / Mendicant (-1.0) vs Pope / Bishop / Monarch / Leadership (+1.0).
  final double simplicityVsLeadership;

  /// Missionary Pioneer / Founder / Innovator (-1.0) vs Preserver of Tradition / Doctrinal Fidelity (+1.0).
  final double pioneeringVsPreservation;

  const SaintEmbedding({
    this.contemplativeVsActive = 0.0,
    this.intellectualVsDevotional = 0.0,
    this.courageVsMercy = 0.0,
    this.ancientVsModern = 0.0,
    this.simplicityVsLeadership = 0.0,
    this.pioneeringVsPreservation = 0.0,
  });

  /// Converts the embedding fields into a fixed-order list of doubles.
  List<double> toVector() => [
    contemplativeVsActive,
    intellectualVsDevotional,
    courageVsMercy,
    ancientVsModern,
    simplicityVsLeadership,
    pioneeringVsPreservation,
  ];

  /// Computes cosine similarity with [userVector] with optional random jitter [noiseMagnitude].
  double similarityWith(
    List<double> userVector, {
    double noiseMagnitude = 0.0,
    Random? random,
  }) {
    final v = toVector();
    if (v.length != userVector.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < v.length; i++) {
      dotProduct += v[i] * userVector[i];
      normA += v[i] * v[i];
      normB += userVector[i] * userVector[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    final baseSim = dotProduct / (sqrt(normA) * sqrt(normB));

    if (noiseMagnitude > 0.0) {
      final rng = random ?? Random();
      // Jitter in [-noiseMagnitude, +noiseMagnitude]
      final jitter = (rng.nextDouble() * 2.0 - 1.0) * noiseMagnitude;
      return (baseSim + jitter).clamp(-1.0, 1.0);
    }

    return baseSim;
  }

  Map<String, dynamic> toJson() => {
    'contemplativeVsActive': contemplativeVsActive,
    'intellectualVsDevotional': intellectualVsDevotional,
    'courageVsMercy': courageVsMercy,
    'ancientVsModern': ancientVsModern,
    'simplicityVsLeadership': simplicityVsLeadership,
    'pioneeringVsPreservation': pioneeringVsPreservation,
  };

  factory SaintEmbedding.fromJson(Map<String, dynamic> json) {
    return SaintEmbedding(
      contemplativeVsActive:
          (json['contemplativeVsActive'] as num?)?.toDouble() ?? 0.0,
      intellectualVsDevotional:
          (json['intellectualVsDevotional'] as num?)?.toDouble() ?? 0.0,
      courageVsMercy: (json['courageVsMercy'] as num?)?.toDouble() ?? 0.0,
      ancientVsModern: (json['ancientVsModern'] as num?)?.toDouble() ?? 0.0,
      simplicityVsLeadership:
          (json['simplicityVsLeadership'] as num?)?.toDouble() ?? 0.0,
      pioneeringVsPreservation:
          (json['pioneeringVsPreservation'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Canonical list of English month names (1-indexed via `index + 1`).
const List<String> kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Representation of a Catholic saint or blessed in the database.
///
/// Canonized saints use the standard prefix "St." in [name] (or "The ...", e.g. "The Vietnamese Martyrs"),
/// while beatified figures not yet canonized use "Blessed" and are flagged with [isBlessed] = true.
/// Recognized Doctors of the Church are flagged with [isDoctor] = true.
class Saint {
  static final RegExp _prefixRegex = RegExp(
    r'^(Sts\.|St\.|Blessed|Bl\.|Venerable|Ven\.|The)\s+',
  );
  static final RegExp _millenniumRegex = RegExp(
    r'(\d+)(?:st|nd|rd|th)?\s+millennium',
  );
  static final RegExp _centuryRegex = RegExp(
    r'(\d+)(?:st|nd|rd|th)?\s+(?:c\.|cent\.|century\b|c\b|cent\b)',
  );
  static final RegExp _yearNumberRegex = RegExp(r'(\d{1,4})');
  static final RegExp _feastDaySplitRegex = RegExp(r'[/,;&]');
  static final RegExp _feastDayRegex = RegExp(r'([A-Za-z]+)\s+(\d+)');

  final String id;
  final String name;
  final String? birthDate; // e.g. "1225", "c. 280"
  final String? deathDate; // e.g. "1274", "c. 304"
  final String nationality; // e.g. "Italian", "French", "Roman"
  final String profession; // e.g. "Theologian, Philosopher", "Nun, Mystic"
  final List<SaintCategory> _explicitCategories;
  final bool isDoctor; // true if recognized as Doctor of the Church
  final bool
  isBlessed; // true if beatified ('Blessed') rather than canonized ('St.')
  final String? feastDay; // e.g. "January 28"
  final String? patronage; // e.g. "Students, Academics, Theologians"
  final String? summary; // Short historical biographical context
  final String? gender; // 'male', 'female', or 'group'
  final SaintEmbedding? embedding; // Multi-dimensional spiritual feature vector
  final bool _hasPrecomputedFields;
  final int? _cachedApproximateYear;
  final List<({int month, int day})> _cachedFeastDates;

  const Saint({
    required this.id,
    required this.name,
    this.birthDate,
    this.deathDate,
    required this.nationality,
    required this.profession,
    List<SaintCategory> categories = const [],
    this.isDoctor = false,
    this.isBlessed = false,
    this.feastDay,
    this.patronage,
    this.summary,
    this.gender,
    this.embedding,
  }) : _explicitCategories = categories,
       _hasPrecomputedFields = false,
       _cachedApproximateYear = null,
       _cachedFeastDates = const [];

  const Saint._precomputed({
    required this.id,
    required this.name,
    this.birthDate,
    this.deathDate,
    required this.nationality,
    required this.profession,
    required List<SaintCategory> categories,
    this.isDoctor = false,
    this.isBlessed = false,
    this.feastDay,
    this.patronage,
    this.summary,
    this.gender,
    this.embedding,
    required int? approximateYear,
    required List<({int month, int day})> feastDates,
  }) : _explicitCategories = categories,
       _hasPrecomputedFields = true,
       _cachedApproximateYear = approximateYear,
       _cachedFeastDates = feastDates;

  bool get isMale => gender == 'male';
  bool get isFemale => gender == 'female';

  String get dateRange {
    if (birthDate != null && deathDate != null) {
      return '$birthDate – $deathDate';
    } else if (birthDate != null) {
      return 'b. $birthDate';
    } else if (deathDate != null) {
      return 'd. $deathDate';
    }
    return '';
  }

  /// Returns a clean short name by stripping honorific prefixes ("St.", "Sts.", "Blessed", "Bl.", "The", "Venerable", "Ven.").
  String get shortName {
    return name.replaceFirst(_prefixRegex, '');
  }

  /// Returns the invocation name suitable for intercessory prayers and dossiers.
  /// For Old Covenant figures and entries with existing honorific prefixes, returns [name] directly.
  /// Otherwise defaults to "St. [shortName]".
  String get invocationName {
    if (era == SaintEra.oldCovenant ||
        name.startsWith('St. ') ||
        name.startsWith('Sts. ') ||
        name.startsWith('Blessed ') ||
        name.startsWith('Bl. ') ||
        name.startsWith('The ') ||
        name.startsWith('Ven. ') ||
        name.startsWith('Venerable ')) {
      return name;
    }
    return 'St. $shortName';
  }

  /// Returns all categories matching this saint based on explicit categories or historical fallback,
  /// ordered consistently according to the standard UI category hierarchy.
  List<SaintCategory> get categories {
    if (_hasPrecomputedFields) {
      return _explicitCategories;
    }
    if (_explicitCategories.isNotEmpty) {
      bool isSorted = true;
      for (int i = 1; i < _explicitCategories.length; i++) {
        if (_explicitCategories[i - 1].index > _explicitCategories[i].index) {
          isSorted = false;
          break;
        }
      }
      if (isSorted) return _explicitCategories;
    }
    final raw = _explicitCategories.isNotEmpty
        ? _explicitCategories
        : computeCategories(
            id: id,
            name: name,
            nationality: nationality,
            profession: profession,
            isDoctor: isDoctor,
          );
    final sorted = List<SaintCategory>.from(raw)
      ..sort((a, b) => a.index.compareTo(b.index));
    return sorted;
  }

  /// Returns all categories matching this saint based on status, titles, profession, and history.
  static List<SaintCategory> computeCategories({
    required String id,
    required String name,
    required String nationality,
    required String profession,
    bool isDoctor = false,
  }) => SaintCategoryClassifier.computeCategories(
    id: id,
    name: name,
    nationality: nationality,
    profession: profession,
    isDoctor: isDoctor,
  );

  /// Primary category for backward compatibility.
  SaintCategory get category => categories.first;

  /// Extracts numeric year for chronological sorting.
  int? get approximateYear {
    if (_hasPrecomputedFields) {
      return _cachedApproximateYear;
    }
    return _computeApproximateYear(
      birthDate: birthDate,
      deathDate: deathDate,
      nationality: nationality,
    );
  }

  static int? _computeApproximateYear({
    required String? birthDate,
    required String? deathDate,
    required String nationality,
  }) {
    final dateStr = deathDate ?? birthDate;
    if (dateStr == null || dateStr.isEmpty) {
      if (nationality.toLowerCase().contains('angelic')) return -9999;
      return null;
    }
    final lower = dateStr.toLowerCase();
    final isBc = lower.contains('bc') || lower.contains('b.c.');

    final millenniumMatch = _millenniumRegex.firstMatch(lower);
    if (millenniumMatch != null) {
      final m = int.parse(millenniumMatch.group(1)!);
      final year = m * 1000 - 500;
      return isBc ? -year : year;
    }

    final centuryMatch = _centuryRegex.firstMatch(lower);
    if (centuryMatch != null) {
      final c = int.parse(centuryMatch.group(1)!);
      final year = c * 100 - 50;
      return isBc ? -year : year;
    }

    final match = _yearNumberRegex.firstMatch(dateStr);
    if (match != null) {
      var year = int.tryParse(match.group(1)!);
      if (year != null) {
        if (isBc) {
          year = -year;
        }
        return year;
      }
    }
    return null;
  }

  /// Historical era based on approximate year.
  SaintEra get era {
    if (nationality.toLowerCase().contains('angelic')) return SaintEra.all;
    final year = approximateYear;
    if (year == null) return SaintEra.all;
    if (year <= 0) return SaintEra.oldCovenant;
    if (year <= 500) return SaintEra.earlyChurch;
    if (year <= 1499) return SaintEra.medieval;
    if (year <= 1799) return SaintEra.reformation;
    return SaintEra.modern;
  }

  static final Map<String, int> _monthMap = {
    for (int i = 0; i < kMonthNames.length; i++)
      kMonthNames[i].toLowerCase(): i + 1,
  };

  static List<({int month, int day})> _parseFeastDates(String? feastDay) {
    if (feastDay == null || feastDay.isEmpty) {
      return const [];
    }
    final List<({int month, int day})> dates = [];
    for (final part in feastDay.split(_feastDaySplitRegex)) {
      final match = _feastDayRegex.firstMatch(part.trim());
      if (match == null) continue;
      final mStr = match.group(1)?.toLowerCase();
      final month = mStr != null ? _monthMap[mStr] : null;
      final day = int.tryParse(match.group(2)!);
      if (month != null && day != null && day >= 1 && day <= 31) {
        final entry = (month: month, day: day);
        if (!dates.contains(entry)) {
          dates.add(entry);
        }
      }
    }
    return List<({int month, int day})>.unmodifiable(dates);
  }

  /// All parsed feast dates `(month, day)` for this saint.
  List<({int month, int day})> get feastDates {
    if (_hasPrecomputedFields) {
      return _cachedFeastDates;
    }
    return _parseFeastDates(feastDay);
  }

  /// Month number (1-12) of primary feast day, if specified.
  int? get feastMonth => feastDates.isNotEmpty ? feastDates.first.month : null;

  /// Day of month (1-31) of primary feast day, if specified.
  int? get feastDayOfMonth =>
      feastDates.isNotEmpty ? feastDates.first.day : null;

  /// Returns true if any feast date of this saint falls in [month] (1-12).
  bool hasFeastInMonth(int month) => feastDates.any((d) => d.month == month);

  /// Returns true if any feast date of this saint falls on [month] (1-12) and [day] (1-31).
  bool hasFeastOnDate(int month, int day) =>
      feastDates.any((d) => d.month == month && d.day == day);

  factory Saint.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final birthDate = json['birthDate'] as String?;
    final deathDate = json['deathDate'] as String?;
    final nationality = json['nationality'] as String? ?? '';
    final profession = json['profession'] as String? ?? '';
    final isDoctor = json['isDoctor'] as bool? ?? false;
    final feastDay = json['feastDay'] as String?;

    final List<SaintCategory> categories = [];
    if (json['categories'] is List) {
      for (final item in json['categories'] as List) {
        if (item is String) {
          final cat = SaintCategory.values.cast<SaintCategory?>().firstWhere(
            (c) => c?.name == item,
            orElse: () => null,
          );
          if (cat != null) {
            categories.add(cat);
          }
        }
      }
    }
    if (categories.isEmpty) {
      categories.addAll(
        computeCategories(
          id: id,
          name: name,
          nationality: nationality,
          profession: profession,
          isDoctor: isDoctor,
        ),
      );
    }
    categories.sort((a, b) => a.index.compareTo(b.index));

    final feastDates = _parseFeastDates(feastDay);
    final approximateYear = _computeApproximateYear(
      birthDate: birthDate,
      deathDate: deathDate,
      nationality: nationality,
    );

    return Saint._precomputed(
      id: id,
      name: name,
      birthDate: birthDate,
      deathDate: deathDate,
      nationality: nationality,
      profession: profession,
      categories: List<SaintCategory>.unmodifiable(categories),
      isDoctor: isDoctor,
      isBlessed: json['isBlessed'] as bool? ?? false,
      feastDay: feastDay,
      patronage: json['patronage'] as String?,
      summary: json['summary'] as String?,
      gender: json['gender'] as String?,
      embedding:
          json['embedding'] != null && json['embedding'] is Map<String, dynamic>
          ? SaintEmbedding.fromJson(json['embedding'] as Map<String, dynamic>)
          : null,
      approximateYear: approximateYear,
      feastDates: feastDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (birthDate != null) 'birthDate': birthDate,
      if (deathDate != null) 'deathDate': deathDate,
      'nationality': nationality,
      'profession': profession,
      if (categories.isNotEmpty)
        'categories': categories.map((c) => c.name).toList(),
      if (gender != null) 'gender': gender,
      'isDoctor': isDoctor,
      if (isBlessed) 'isBlessed': isBlessed,
      if (feastDay != null) 'feastDay': feastDay,
      if (patronage != null) 'patronage': patronage,
      if (summary != null) 'summary': summary,
      if (embedding != null) 'embedding': embedding!.toJson(),
    };
  }
}
