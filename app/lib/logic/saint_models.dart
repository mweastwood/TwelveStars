import 'package:flutter/material.dart';
import 'package:twelve_stars/theme/app_theme_tokens.dart';

/// Major categorization of saints for visual icon representation and filtering.
enum SaintCategory {
  doctor,
  apostle,
  martyr,
  popeBishop,
  priestReligious,
  mystic,
  virgin,
  monarch,
  healerMissionary,
  other;

  String get label {
    switch (this) {
      case SaintCategory.doctor:
        return 'Doctor of the Church';
      case SaintCategory.apostle:
        return 'Apostle & Evangelist';
      case SaintCategory.martyr:
        return 'Martyr';
      case SaintCategory.popeBishop:
        return 'Pope & Bishop';
      case SaintCategory.priestReligious:
        return 'Priest & Religious';
      case SaintCategory.mystic:
        return 'Mystic & Contemplative';
      case SaintCategory.virgin:
        return 'Virgin & Consecrated';
      case SaintCategory.monarch:
        return 'Ruler & Monarch';
      case SaintCategory.healerMissionary:
        return 'Healer & Missionary';
      case SaintCategory.other:
        return 'Saint';
    }
  }
}

/// Historical eras for timeline filtering.
enum SaintEra {
  all,
  earlyChurch, // 1st - 5th Century (<= 500)
  medieval, // 6th - 14th Century (501 - 1499)
  reformation, // 15th - 18th Century (1500 - 1799)
  modern; // 19th - 21st Century (1800+)

  String get label {
    switch (this) {
      case SaintEra.all:
        return 'All Eras';
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

  IconData get icon {
    switch (this) {
      case SaintSortOption.nameAsc:
        return Icons.sort_by_alpha;
      case SaintSortOption.nameDesc:
        return Icons.sort_by_alpha;
      case SaintSortOption.feastDay:
        return Icons.calendar_month;
      case SaintSortOption.chronologicalAsc:
        return Icons.history;
      case SaintSortOption.chronologicalDesc:
        return Icons.update;
      case SaintSortOption.doctorsFirst:
        return Icons.star;
    }
  }
}

/// Representation of a Catholic saint or blessed in the database.
///
/// Canonized saints use the standard prefix "St." in [name] (or "The ...", e.g. "The Vietnamese Martyrs"),
/// while beatified figures not yet canonized use "Blessed" and are flagged with [isBlessed] = true.
/// Recognized Doctors of the Church are flagged with [isDoctor] = true.
class Saint {
  final String id;
  final String name;
  final String? birthDate; // e.g. "1225", "c. 280"
  final String? deathDate; // e.g. "1274", "c. 304"
  final String nationality; // e.g. "Italian", "French", "Roman"
  final String profession; // e.g. "Theologian, Philosopher", "Nun, Mystic"
  final bool isDoctor; // true if recognized as Doctor of the Church
  final bool
  isBlessed; // true if beatified ('Blessed') rather than canonized ('St.')
  final String? feastDay; // e.g. "January 28"
  final String? patronage; // e.g. "Students, Academics, Theologians"
  final String? summary; // Short historical biographical context
  final String? gender; // 'male', 'female', or 'group'

  const Saint({
    required this.id,
    required this.name,
    this.birthDate,
    this.deathDate,
    required this.nationality,
    required this.profession,
    this.isDoctor = false,
    this.isBlessed = false,
    this.feastDay,
    this.patronage,
    this.summary,
    this.gender,
  });

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

  /// Categorizes saint according to titles, doctor status, and profession.
  SaintCategory get category {
    if (isDoctor) {
      return SaintCategory.doctor;
    }
    final profLower = profession.toLowerCase();
    final nameLower = name.toLowerCase();

    if (profLower.contains('apostle') ||
        profLower.contains('evangelist') ||
        profLower.contains('archangel') ||
        nameLower.contains('archangel') ||
        nameLower.contains('apostle')) {
      return SaintCategory.apostle;
    }
    if (profLower.contains('martyr') || nameLower.contains('martyrs')) {
      return SaintCategory.martyr;
    }
    if (profLower.contains('pope') ||
        profLower.contains('bishop') ||
        profLower.contains('patriarch') ||
        profLower.contains('cardinal')) {
      return SaintCategory.popeBishop;
    }
    if (profLower.contains('mystic') || profLower.contains('stigmatist')) {
      return SaintCategory.mystic;
    }
    if (profLower.contains('king') ||
        profLower.contains('queen') ||
        profLower.contains('emperor') ||
        profLower.contains('empress') ||
        profLower.contains('ruler') ||
        profLower.contains('prince') ||
        profLower.contains('princess') ||
        profLower.contains('duke') ||
        profLower.contains('duchess')) {
      return SaintCategory.monarch;
    }
    if (profLower.contains('physician') ||
        profLower.contains('doctor') ||
        profLower.contains('healer') ||
        profLower.contains('nurse') ||
        profLower.contains('missionary') ||
        profLower.contains('apostle of')) {
      return SaintCategory.healerMissionary;
    }
    if (profLower.contains('virgin') ||
        profLower.contains('matron') ||
        profLower.contains('widow')) {
      return SaintCategory.virgin;
    }
    if (profLower.contains('priest') ||
        profLower.contains('friar') ||
        profLower.contains('monk') ||
        profLower.contains('nun') ||
        profLower.contains('abbot') ||
        profLower.contains('abbess') ||
        profLower.contains('deacon') ||
        profLower.contains('brother') ||
        profLower.contains('hermit') ||
        profLower.contains('religious') ||
        profLower.contains('founder') ||
        profLower.contains('carmelite') ||
        profLower.contains('franciscan') ||
        profLower.contains('dominican') ||
        profLower.contains('jesuit') ||
        profLower.contains('benedictine')) {
      return SaintCategory.priestReligious;
    }
    return SaintCategory.other;
  }

  /// Icon corresponding to the category.
  IconData get categoryIcon {
    switch (category) {
      case SaintCategory.doctor:
        return Icons.menu_book_rounded;
      case SaintCategory.apostle:
        return Icons.auto_stories_rounded;
      case SaintCategory.martyr:
        return Icons.local_fire_department_rounded;
      case SaintCategory.popeBishop:
        return Icons.account_balance_rounded;
      case SaintCategory.priestReligious:
        return Icons.church_rounded;
      case SaintCategory.mystic:
        return Icons.wb_sunny_rounded;
      case SaintCategory.virgin:
        return Icons.local_florist_rounded;
      case SaintCategory.monarch:
        return Icons.workspace_premium_rounded;
      case SaintCategory.healerMissionary:
        return Icons.healing_rounded;
      case SaintCategory.other:
        return Icons.person_rounded;
    }
  }

  /// Color tint for category badge/icon.
  Color categoryColor(ThemeData theme) {
    switch (category) {
      case SaintCategory.doctor:
        return AppThemeTokens.liturgicalGold;
      case SaintCategory.apostle:
        return AppThemeTokens.marianBlue;
      case SaintCategory.martyr:
        return AppThemeTokens.liturgicalRed;
      case SaintCategory.popeBishop:
        return AppThemeTokens.liturgicalPurple;
      case SaintCategory.priestReligious:
        return AppThemeTokens.liturgicalGreen;
      case SaintCategory.mystic:
        return AppThemeTokens.liturgicalRose;
      case SaintCategory.virgin:
        return AppThemeTokens.marianBlue;
      case SaintCategory.monarch:
        return AppThemeTokens.liturgicalPurple;
      case SaintCategory.healerMissionary:
        return const Color(0xFF00897B); // Teal 600
      case SaintCategory.other:
        return theme.colorScheme.primary;
    }
  }

  /// Extracts numeric year for chronological sorting.
  int? get approximateYear {
    final dateStr = deathDate ?? birthDate;
    if (dateStr == null || dateStr.isEmpty) {
      if (nationality.toLowerCase().contains('angelic')) return -9999;
      return null;
    }
    final lower = dateStr.toLowerCase();
    if (lower.contains('1st century')) return 50;
    if (lower.contains('2nd century')) return 150;
    if (lower.contains('3rd century')) return 250;
    if (lower.contains('4th century')) return 350;
    if (lower.contains('5th century')) return 450;
    if (lower.contains('6th century')) return 550;
    if (lower.contains('7th century')) return 650;
    if (lower.contains('8th century')) return 750;
    if (lower.contains('9th century')) return 850;
    if (lower.contains('10th century')) return 950;
    if (lower.contains('11th century')) return 1050;
    if (lower.contains('12th century')) return 1150;
    if (lower.contains('13th century')) return 1250;
    if (lower.contains('14th century')) return 1350;
    if (lower.contains('15th century')) return 1450;
    if (lower.contains('16th century')) return 1550;
    if (lower.contains('17th century')) return 1650;
    if (lower.contains('18th century')) return 1750;
    if (lower.contains('19th century')) return 1850;
    if (lower.contains('20th century')) return 1950;

    final match = RegExp(r'(\d{1,4})').firstMatch(dateStr);
    if (match != null) {
      var year = int.tryParse(match.group(1)!);
      if (year != null) {
        if (lower.contains('bc') || lower.contains('b.c.')) {
          year = -year;
        }
        return year;
      }
    }
    return null;
  }

  /// Historical era based on approximate year.
  SaintEra get era {
    final year = approximateYear;
    if (year == null) return SaintEra.all;
    if (year <= 500) return SaintEra.earlyChurch;
    if (year <= 1499) return SaintEra.medieval;
    if (year <= 1799) return SaintEra.reformation;
    return SaintEra.modern;
  }

  static const Map<String, int> _monthMap = {
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
  };

  /// Month number (1-12) of feast day, if specified.
  int? get feastMonth {
    if (feastDay == null || feastDay!.isEmpty) return null;
    final match = RegExp(r'([A-Za-z]+)\s+(\d+)').firstMatch(feastDay!);
    if (match != null) {
      final mStr = match.group(1)?.toLowerCase();
      if (mStr != null && _monthMap.containsKey(mStr)) {
        return _monthMap[mStr];
      }
    }
    return null;
  }

  /// Day of month (1-31) of feast day, if specified.
  int? get feastDayOfMonth {
    if (feastDay == null || feastDay!.isEmpty) return null;
    final match = RegExp(r'([A-Za-z]+)\s+(\d+)').firstMatch(feastDay!);
    if (match != null) {
      return int.tryParse(match.group(2)!);
    }
    return null;
  }

  factory Saint.fromJson(Map<String, dynamic> json) {
    return Saint(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      birthDate: json['birthDate'] as String?,
      deathDate: json['deathDate'] as String?,
      nationality: json['nationality'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      isDoctor: json['isDoctor'] as bool? ?? false,
      isBlessed: json['isBlessed'] as bool? ?? false,
      feastDay: json['feastDay'] as String?,
      patronage: json['patronage'] as String?,
      summary: json['summary'] as String?,
      gender: json['gender'] as String?,
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
      'isDoctor': isDoctor,
      if (isBlessed) 'isBlessed': isBlessed,
      if (feastDay != null) 'feastDay': feastDay,
      if (patronage != null) 'patronage': patronage,
      if (summary != null) 'summary': summary,
      if (gender != null) 'gender': gender,
    };
  }
}
