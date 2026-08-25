import 'package:flutter/material.dart';
import 'package:twelve_stars/theme/app_theme_tokens.dart';

/// Major categorization of saints for visual icon representation and filtering.
enum SaintCategory {
  group,
  holyFamily,
  angel,
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

  /// Icon corresponding to the category.
  IconData get icon {
    switch (this) {
      case SaintCategory.group:
        return Icons.groups_3_rounded;
      case SaintCategory.holyFamily:
        return Icons.family_restroom_rounded;
      case SaintCategory.angel:
        return Icons.flare_rounded;
      case SaintCategory.apostle:
        return Icons.stars_rounded;
      case SaintCategory.evangelist:
        return Icons.auto_stories_rounded;
      case SaintCategory.doctor:
        return Icons.menu_book_rounded;
      case SaintCategory.pope:
        return Icons.vpn_key_rounded;
      case SaintCategory.bishop:
        return Icons.account_balance_rounded;
      case SaintCategory.priest:
        return Icons.church_rounded;
      case SaintCategory.deacon:
        return Icons.volunteer_activism_rounded;
      case SaintCategory.brother:
        return Icons.diversity_3_rounded;
      case SaintCategory.nun:
        return Icons.auto_awesome_rounded;
      case SaintCategory.monarch:
        return Icons.workspace_premium_rounded;
      case SaintCategory.martyr:
        return Icons.local_fire_department_rounded;
      case SaintCategory.healerMissionary:
        return Icons.healing_rounded;
      case SaintCategory.virgin:
        return Icons.local_florist_rounded;
      case SaintCategory.mystic:
        return Icons.wb_sunny_rounded;
      case SaintCategory.laity:
        return Icons.groups_rounded;
      case SaintCategory.other:
        return Icons.person_rounded;
    }
  }

  /// Color tint for category badge/icon.
  Color color(ThemeData theme) {
    switch (this) {
      case SaintCategory.group:
        return const Color(0xFF4B5563); // Gray 600
      case SaintCategory.holyFamily:
        return const Color(0xFFAD1457); // Crimson / Rose 800
      case SaintCategory.angel:
        return const Color(0xFF00ACC1); // Cyan 600
      case SaintCategory.apostle:
        return AppThemeTokens.marianBlue;
      case SaintCategory.evangelist:
        return const Color(0xFFE65100); // Deep Orange 900
      case SaintCategory.doctor:
        return AppThemeTokens.liturgicalGold;
      case SaintCategory.pope:
        return const Color(0xFFD97706); // Papal Amber / Gold
      case SaintCategory.bishop:
        return AppThemeTokens.liturgicalPurple;
      case SaintCategory.priest:
        return AppThemeTokens.liturgicalGreen;
      case SaintCategory.deacon:
        return const Color(0xFF0284C7); // Sky 600
      case SaintCategory.brother:
        return const Color(0xFF00897B); // Teal 600
      case SaintCategory.nun:
        return const Color(0xFF7B1FA2); // Purple 700
      case SaintCategory.monarch:
        return AppThemeTokens.liturgicalPurple;
      case SaintCategory.martyr:
        return AppThemeTokens.liturgicalRed;
      case SaintCategory.healerMissionary:
        return const Color(0xFF00897B); // Teal 600
      case SaintCategory.virgin:
        return AppThemeTokens.marianBlue;
      case SaintCategory.mystic:
        return AppThemeTokens.liturgicalRose;
      case SaintCategory.laity:
        return const Color(0xFF5C6BC0); // Indigo 400
      case SaintCategory.other:
        return theme.colorScheme.primary;
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
  final List<SaintCategory> _explicitCategories;
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
    List<SaintCategory> categories = const [],
    this.isDoctor = false,
    this.isBlessed = false,
    this.feastDay,
    this.patronage,
    this.summary,
    this.gender,
  }) : _explicitCategories = categories;

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

  /// Returns all categories matching this saint based on explicit categories or historical fallback,
  /// ordered consistently according to the standard UI category hierarchy.
  List<SaintCategory> get categories {
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
  }) {
    final List<SaintCategory> list = [];
    final profLower = profession.toLowerCase();
    final nameLower = name.toLowerCase();
    final natLower = nationality.toLowerCase();

    // 0. Group
    final isKnownGroup = const {
      'vietnamese-martyrs',
      'korean-martyrs',
      'paul-miki-and-companions',
      'charles-lwanga-and-ugandan-martyrs',
      'perpetua-and-felicity',
    }.contains(id);

    if (isKnownGroup ||
        profLower.contains('martyrs of') ||
        profLower.contains('companions') ||
        nameLower.contains('companions') ||
        nameLower.contains('martyrs')) {
      list.add(SaintCategory.group);
    }

    // 1. Doctor of the Church
    if (isDoctor) {
      list.add(SaintCategory.doctor);
    }

    // 2. Angel
    if (natLower.contains('angelic') ||
        profLower.contains('archangel') ||
        nameLower.contains('archangel') ||
        RegExp(r'\barchangels?\b|\bangels?\b').hasMatch(profLower) ||
        RegExp(r'\barchangels?\b|\bangels?\b').hasMatch(nameLower)) {
      list.add(SaintCategory.angel);
    }

    // 3. Holy Family
    if (profLower.contains('foster father') ||
        profLower.contains('father of jesus') ||
        profLower.contains('spouse of mary') ||
        profLower.contains('spouse of the virgin mary') ||
        profLower.contains('mother of god') ||
        profLower.contains('theotokos') ||
        profLower.contains('holy family') ||
        nameLower.contains('blessed virgin mary') ||
        (nameLower.contains('joseph') && profLower.contains('carpenter'))) {
      list.add(SaintCategory.holyFamily);
    }

    // 4. Apostle
    final isBiblicalApostle = const {
      'andrew-the-apostle',
      'barnabas',
      'bartholomew-the-apostle',
      'james-the-greater',
      'james-the-lesser',
      'john-the-apostle',
      'jude-thaddeus',
      'mary-magdalene',
      'matthew-the-apostle',
      'matthias',
      'paul-the-apostle',
      'peter-the-apostle',
      'philip-the-apostle',
      'simon-the-zealot',
      'thomas-the-apostle',
    }.contains(id);

    if (isBiblicalApostle ||
        profLower.contains('apostle to the apostles') ||
        profLower.contains('apostola apostolorum') ||
        (profLower.contains('apostle') &&
            !profLower.contains('apostle of') &&
            !profLower.contains('apostle to') &&
            !profLower.contains('cyber-apostle') &&
            (nameLower.contains('the apostle') ||
                nameLower.contains('barnabas') ||
                nameLower.contains('matthias') ||
                nameLower.contains('thaddeus') ||
                nameLower.contains('zealot')))) {
      list.add(SaintCategory.apostle);
    }

    // 5. Evangelist
    if (profLower.contains('evangelist') || nameLower.contains('evangelist')) {
      list.add(SaintCategory.evangelist);
    }

    // 6. Pope
    if (profLower.contains('pope') || nameLower.contains('pope')) {
      list.add(SaintCategory.pope);
    }

    // 7. Martyr
    final isMartyredApostleOrEvangelist = const {
      'peter-the-apostle',
      'paul-the-apostle',
      'andrew-the-apostle',
      'james-the-greater',
      'james-the-lesser',
      'philip-the-apostle',
      'bartholomew-the-apostle',
      'thomas-the-apostle',
      'matthew-the-apostle',
      'jude-thaddeus',
      'simon-the-zealot',
      'matthias',
      'barnabas',
      'mark-the-evangelist',
      'polycarp-of-smyrna',
      'teresa-benedicta-of-the-cross',
      'john-of-nepomuk',
    }.contains(id);

    if (profLower.contains('martyr') ||
        nameLower.contains('martyrs') ||
        isMartyredApostleOrEvangelist) {
      list.add(SaintCategory.martyr);
    }

    // 8. Bishop
    final isEpiscopalTitle =
        profLower.contains('bishop') ||
        profLower.contains('archbishop') ||
        profLower.contains('cardinal') ||
        (profLower.contains('patriarch') &&
            !profLower.contains('patriarch of christian monasticism') &&
            !profLower.contains('patriarch of western monasticism') &&
            !profLower.contains('father of faith') &&
            !profLower.contains('man of patience') &&
            !id.contains('abraham') &&
            !id.contains('job'));
    if (isEpiscopalTitle) {
      list.add(SaintCategory.bishop);
    }

    // 9. Monarch / Ruler
    final isMonarchTitle =
        profLower.contains('king') ||
        (profLower.contains('queen') &&
            !profLower.contains('queen of heaven') &&
            !profLower.contains('queen of all saints') &&
            !profLower.contains('queen of the apostles')) ||
        profLower.contains('emperor') ||
        profLower.contains('empress') ||
        profLower.contains('ruler') ||
        (profLower.contains('prince') &&
            !profLower.contains('prince of the heavenly') &&
            !profLower.contains('prince of the apostles')) ||
        profLower.contains('princess') ||
        profLower.contains('duke') ||
        profLower.contains('duchess') ||
        profLower.contains('monarch');
    if (isMonarchTitle) {
      list.add(SaintCategory.monarch);
    }

    // 10. Mystic & Contemplative
    final isProminentMystic = const {
      'mary-mother-of-god',
      'mary-magdalene',
      'anthony-the-great',
      'thomas-aquinas',
      'bonaventure',
      'bernard-of-clairvaux',
      'francis-de-sales',
      'francis-of-assisi',
      'ignatius-of-loyola',
      'peter-damian',
      'gregory-of-narek',
      'charbel-makhlouf',
      'joseph-of-cupertino',
      'paul-of-the-cross',
      'gerard-majella',
      'rita-of-cascia',
      'rafqa-pietra-choboq-ar-rayes',
      'kateri-tekakwitha',
      'rose-of-lima',
      'titus-brandsma',
      'mother-teresa',
      'teresa-of-avila',
      'therese-of-lisieux',
      'john-of-the-cross',
      'catherine-of-siena',
      'faustina-kowalska',
      'bernadette-soubirous',
      'bridget-of-sweden',
      'clare-of-assisi',
      'clare-of-montefalco',
      'gertrude-the-great',
      'mechtilde-of-hackeborn',
      'hildegard-of-bingen',
      'padre-pio',
      'juan-diego',
      'teresa-benedicta-of-the-cross',
    }.contains(id);

    if (isProminentMystic ||
        profLower.contains('mystic') ||
        profLower.contains('stigmatist') ||
        profLower.contains('visionary') ||
        profLower.contains('contemplative') ||
        profLower.contains('divine mercy')) {
      list.add(SaintCategory.mystic);
    }

    // 11. Laity
    final isKnownLaySaint = const {
      'joseph',
      'carlo-acutis',
      'gianna-beretta-molla',
      'giuseppe-moscati',
      'kateri-tekakwitha',
      'thomas-more',
      'margaret-clitherow',
      'maria-goretti',
      'laura-vicuna',
      'dominic-savio',
      'pancras',
      'tarcisius',
      'jose-sanchez-del-rio',
      'pedro-calungsod',
      'lorenzo-ruiz',
      'perpetua-and-felicity',
      'charles-lwanga-and-ugandan-martyrs',
      'roch',
      'philip-howard',
      'cecilia',
      'juan-diego',
      'joan-of-arc',
      'bridget-of-sweden',
      'rita-of-cascia',
      'andre-bessette',
      'martin-de-porres',
      'gerard-majella',
      'louis-ix-of-france',
      'elizabeth-of-hungary',
      'wenceslaus',
      'edward-the-confessor',
      'margaret-of-scotland',
      'stephen-of-hungary',
      'eric-of-sweden',
      'olaf-ii-of-norway',
      'casimir',
      'francis-borgia',
      'vietnamese-martyrs',
      'korean-martyrs',
      'abraham-the-patriarch',
      'moses-the-prophet',
      'elijah-the-prophet',
      'elisha-the-prophet',
      'isaiah-the-prophet',
      'jeremiah-the-prophet',
      'daniel-the-prophet',
      'samuel-the-prophet',
      'david-the-king',
      'job-the-righteous',
    }.contains(id);

    final isExplicitLayKeyword =
        (profLower.contains('layman') ||
            profLower.contains('laywoman') ||
            profLower.contains('layperson') ||
            profLower.contains('laity') ||
            profLower.contains('lay ') ||
            profLower.contains('student') ||
            profLower.contains('pupil') ||
            profLower.contains('peasant girl') ||
            profLower.contains('pediatrician') ||
            profLower.contains('calligrapher') ||
            profLower.contains('programmer') ||
            profLower.contains('web developer') ||
            profLower.contains('married') ||
            profLower.contains('homemaker') ||
            profLower.contains('matron') ||
            profLower.contains('craftsman') ||
            profLower.contains('lawyer') ||
            profLower.contains('statesman') ||
            profLower.contains('chancellor') ||
            profLower.contains('cavalry officer') ||
            (profLower.contains('carpenter') &&
                !profLower.contains('foster father')) ||
            (profLower.contains('mother') &&
                !profLower.contains('mother of god') &&
                !profLower.contains('mother cabrini') &&
                !profLower.contains('mother teresa') &&
                !profLower.contains('mother marianne') &&
                !profLower.contains('mother superior') &&
                !profLower.contains('foundress') &&
                !profLower.contains('seraphic mother')) ||
            (profLower.contains('father') &&
                !profLower.contains('church father') &&
                !profLower.contains('desert father') &&
                !profLower.contains('apostolic father') &&
                !profLower.contains('cappadocian father') &&
                !profLower.contains('latin church father') &&
                !profLower.contains('father of the church') &&
                !profLower.contains('father of western monasticism') &&
                !profLower.contains('father of christian monasticism') &&
                !profLower.contains('foster father') &&
                !profLower.contains('picpus fathers') &&
                !profLower.contains('holy father'))) &&
        !list.contains(SaintCategory.bishop) &&
        !list.contains(SaintCategory.pope);

    if (isExplicitLayKeyword || isKnownLaySaint) {
      list.add(SaintCategory.laity);
    }

    // 12. Healer & Missionary
    final isKnownHealerOrMissionary = const {
      'francis-xavier',
      'damien-of-molokai',
      'marianne-cope',
      'mother-teresa',
      'frances-xavier-cabrini',
      'junipero-serra',
      'peter-claver',
      'camillus-de-lellis',
      'vincent-de-paul',
      'john-bosco',
      'andre-bessette',
      'martin-de-porres',
      'giuseppe-moscati',
      'gianna-beretta-molla',
      'roch',
      'blaise',
      'luke-the-evangelist',
      'raphael-the-archangel',
      'patrick-of-ireland',
      'aidan-of-lindisfarne',
      'columba-of-iona',
      'columbanus',
      'peter-canisius',
      'lawrence-of-brindisi',
      'john-of-avila',
      'louis-marie-de-montfort',
      'turibius-of-mogrovejo',
      'jacques-berthieu',
      'pedro-calungsod',
      'carlo-acutis',
      'barnabas',
      'philip-the-apostle',
      'thomas-the-apostle',
      'simon-the-zealot',
      'paul-the-apostle',
      'nicholas-of-myra',
      'anastasia-of-sirmium',
      'anthony-of-padua',
    }.contains(id);

    if (isKnownHealerOrMissionary ||
        profLower.contains('physician') ||
        profLower.contains('pediatrician') ||
        profLower.contains('surgeon') ||
        profLower.contains('healer') ||
        profLower.contains('nurse') ||
        profLower.contains('medical') ||
        profLower.contains('missionary') ||
        profLower.contains('missionaries') ||
        profLower.contains('apostle of') ||
        profLower.contains('apostle to the lepers') ||
        profLower.contains('cyber-apostle')) {
      list.add(SaintCategory.healerMissionary);
    }

    // 13. Virgin & Consecrated
    final isKnownVirginOrConsecrated = const {
      'mary-mother-of-god',
      'agnes-of-rome',
      'barbara',
      'cecilia',
      'lucy-of-syracuse',
      'maria-goretti',
      'apollonia',
      'anastasia-of-sirmium',
      'kateri-tekakwitha',
      'rose-of-lima',
      'laura-vicuna',
      'scholastica',
      'clare-of-assisi',
      'clare-of-montefalco',
      'catherine-of-bologna',
      'gertrude-the-great',
      'mechtilde-of-hackeborn',
      'rafqa-pietra-choboq-ar-rayes',
      'teresa-of-avila',
      'therese-of-lisieux',
      'catherine-of-siena',
      'hildegard-of-bingen',
      'bernadette-soubirous',
      'faustina-kowalska',
      'joan-of-arc',
      'teresa-benedicta-of-the-cross',
      'dominic-savio',
      'aloysius-gonzaga',
      'stanislaus-kostka',
      'john-berchmans',
      'elizabeth-ann-seton',
      'frances-xavier-cabrini',
      'katharine-drexel',
      'louise-de-marillac',
      'marianne-cope',
      'mary-mackillop',
      'mother-teresa',
      'jane-frances-de-chantal',
    }.contains(id);

    if (isKnownVirginOrConsecrated ||
        profLower.contains('virgin') ||
        profLower.contains('lily of the mohawks') ||
        profLower.contains('consecrated')) {
      list.add(SaintCategory.virgin);
    }

    // 14. Priest
    final isKnownPriest = const {
      'anthony-of-padua',
      'bede-the-venerable',
      'bernard-of-clairvaux',
      'bruno-of-cologne',
      'camillus-de-lellis',
      'charbel-makhlouf',
      'charles-de-foucauld',
      'columba-of-iona',
      'columbanus',
      'damien-of-molokai',
      'dominic-de-guzman',
      'edmund-campion',
      'francis-borgia',
      'francis-xavier',
      'gregory-of-narek',
      'ignatius-of-loyola',
      'jacques-berthieu',
      'jerome',
      'john-bosco',
      'john-damascene',
      'john-of-avila',
      'john-of-nepomuk',
      'john-of-the-cross',
      'john-vianney',
      'josemaria-escriva',
      'joseph-of-cupertino',
      'junipero-serra',
      'lawrence-of-brindisi',
      'louis-marie-de-montfort',
      'maximilian-kolbe',
      'miguel-pro',
      'nimatullah-kassab',
      'padre-pio',
      'paul-of-the-cross',
      'peregrine-laziosi',
      'peter-canisius',
      'peter-claver',
      'philip-neri',
      'raymond-of-penafort',
      'thomas-aquinas',
      'titus-brandsma',
      'vincent-de-paul',
    }.contains(id);

    if (isKnownPriest ||
        ((profLower.contains('priest') ||
                profLower.contains('presbyter') ||
                profLower.contains('parish priest') ||
                profLower.contains('curé') ||
                profLower.contains('confessor')) &&
            !list.contains(SaintCategory.pope) &&
            !list.contains(SaintCategory.bishop))) {
      list.add(SaintCategory.priest);
    }

    // 14.5 Deacon
    final isKnownDeacon = const {
      'stephen-first-martyr',
      'lawrence-of-rome',
      'ephrem-the-syrian',
    }.contains(id);

    if (isKnownDeacon ||
        ((profLower.contains('deacon') || profLower.contains('archdeacon')) &&
            !profLower.contains('deaconess') &&
            !list.contains(SaintCategory.pope) &&
            !list.contains(SaintCategory.bishop) &&
            !list.contains(SaintCategory.priest))) {
      list.add(SaintCategory.deacon);
    }

    // 15. Brother
    final isKnownBrother = const {
      'aloysius-gonzaga',
      'andre-bessette',
      'anthony-the-great',
      'benedict-of-nursia',
      'francis-of-assisi',
      'gerard-majella',
      'john-berchmans',
      'martin-de-porres',
      'pachomius',
      'paul-miki-and-companions',
      'paul-the-first-hermit',
      'romuald',
      'stanislaus-kostka',
      'vincent-of-lerins',
    }.contains(id);

    if (isKnownBrother ||
        ((profLower.contains('brother') ||
                profLower.contains('friar') ||
                profLower.contains('monk') ||
                profLower.contains('abbot') ||
                profLower.contains('hermit') ||
                profLower.contains('novice') ||
                profLower.contains('scholastic')) &&
            !list.contains(SaintCategory.pope) &&
            !list.contains(SaintCategory.bishop) &&
            !list.contains(SaintCategory.priest) &&
            !list.contains(SaintCategory.deacon))) {
      list.add(SaintCategory.brother);
    }

    // 16. Nun
    final isKnownNun = const {
      'bernadette-soubirous',
      'bridget-of-sweden',
      'brigid-of-kildare',
      'catherine-of-bologna',
      'catherine-of-siena',
      'clare-of-assisi',
      'clare-of-montefalco',
      'elizabeth-ann-seton',
      'faustina-kowalska',
      'frances-xavier-cabrini',
      'gertrude-the-great',
      'hildegard-of-bingen',
      'jane-frances-de-chantal',
      'katharine-drexel',
      'louise-de-marillac',
      'marianne-cope',
      'mary-mackillop',
      'mechtilde-of-hackeborn',
      'mother-teresa',
      'rafqa-pietra-choboq-ar-rayes',
      'rita-of-cascia',
      'rose-of-lima',
      'scholastica',
      'teresa-benedicta-of-the-cross',
      'teresa-of-avila',
      'teresa-of-the-andes',
      'therese-of-lisieux',
    }.contains(id);

    if (isKnownNun ||
        profLower.contains('nun') ||
        profLower.contains('abbess') ||
        profLower.contains('sister') ||
        profLower.contains('sisters') ||
        profLower.contains('foundress') ||
        profLower.contains('clares')) {
      list.add(SaintCategory.nun);
    }

    if (list.isEmpty) {
      list.add(SaintCategory.other);
    }

    return list.toSet().toList();
  }

  /// Primary category for backward compatibility.
  SaintCategory get category => categories.first;

  /// Icon corresponding to the category.
  IconData get categoryIcon => category.icon;

  /// Color tint for category badge/icon.
  Color categoryColor(ThemeData theme) => category.color(theme);

  /// Extracts numeric year for chronological sorting.
  int? get approximateYear {
    final dateStr = deathDate ?? birthDate;
    if (dateStr == null || dateStr.isEmpty) {
      if (nationality.toLowerCase().contains('angelic')) return -9999;
      return null;
    }
    final lower = dateStr.toLowerCase();

    // 1. Millennia (e.g. "c. 2nd millennium BC", "2nd Millennium BC")
    final millMatch = RegExp(
      r'(\d{1,2})(?:st|nd|rd|th)?\s*(?:millennium|mill\.)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (millMatch != null) {
      final mNum = int.tryParse(millMatch.group(1)!);
      if (mNum != null) {
        var year = (mNum - 1) * 1000 + 500;
        if (lower.contains('bc') || lower.contains('b.c.')) {
          year = -year;
        }
        return year;
      }
    }

    // 2. Centuries (e.g. "1st century", "c. 9th c. BC", "c. 18th c. BC", "3rd Century")
    final centMatch = RegExp(
      r'(\d{1,2})(?:st|nd|rd|th)?\s*(?:century|cent\.|c\.)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (centMatch != null) {
      final cNum = int.tryParse(centMatch.group(1)!);
      if (cNum != null) {
        var year = (cNum - 1) * 100 + 50;
        if (lower.contains('bc') || lower.contains('b.c.')) {
          year = -year;
        }
        return year;
      }
    }

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

    return Saint(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      birthDate: json['birthDate'] as String?,
      deathDate: json['deathDate'] as String?,
      nationality: json['nationality'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      categories: categories,
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
      if (categories.isNotEmpty)
        'categories': categories.map((c) => c.name).toList(),
      if (gender != null) 'gender': gender,
      'isDoctor': isDoctor,
      if (isBlessed) 'isBlessed': isBlessed,
      if (feastDay != null) 'feastDay': feastDay,
      if (patronage != null) 'patronage': patronage,
      if (summary != null) 'summary': summary,
    };
  }
}
