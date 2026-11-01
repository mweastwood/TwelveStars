class ThematicPassage {
  final String bookId;
  final String bookTitle;
  final String author;
  final String sectionId;
  final String sectionTitle;
  final int itemIndex;
  final int? questionNumber;
  final String primaryTheme;
  final List<String> secondaryThemes;
  final String keyExcerpt;
  final String oneSentenceSummary;
  final String fullText;
  final String? authorSaintId;

  ThematicPassage({
    required this.bookId,
    required this.bookTitle,
    required this.author,
    required this.sectionId,
    required this.sectionTitle,
    required this.itemIndex,
    this.questionNumber,
    required this.primaryTheme,
    this.secondaryThemes = const [],
    required this.keyExcerpt,
    required this.oneSentenceSummary,
    required this.fullText,
    this.authorSaintId,
  });

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    'bookTitle': bookTitle,
    'author': author,
    'sectionId': sectionId,
    'sectionTitle': sectionTitle,
    'itemIndex': itemIndex,
    if (questionNumber != null) 'questionNumber': questionNumber,
    'primaryTheme': primaryTheme,
    'secondaryThemes': secondaryThemes,
    'keyExcerpt': keyExcerpt,
    'oneSentenceSummary': oneSentenceSummary,
    'fullText': fullText,
  };

  factory ThematicPassage.fromJson(
    Map<String, dynamic> json, {
    String? authorSaintId,
  }) {
    return ThematicPassage(
      bookId: json['bookId'] as String? ?? '',
      bookTitle: json['bookTitle'] as String? ?? '',
      author: json['author'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      sectionTitle: json['sectionTitle'] as String? ?? '',
      itemIndex: json['itemIndex'] as int? ?? 0,
      questionNumber: json['questionNumber'] as int?,
      primaryTheme: json['primaryTheme'] as String? ?? 'theology.trinity',
      secondaryThemes:
          (json['secondaryThemes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      keyExcerpt: json['keyExcerpt'] as String? ?? '',
      oneSentenceSummary: json['oneSentenceSummary'] as String? ?? '',
      fullText: json['fullText'] as String? ?? '',
      authorSaintId: authorSaintId,
    );
  }
}

class ThematicCategoryGroup {
  final String name;
  final String icon;
  final Map<String, String> themes;

  const ThematicCategoryGroup({
    required this.name,
    required this.icon,
    required this.themes,
  });
}

class ThematicTaxonomyData {
  static const List<ThematicCategoryGroup> categoryGroups = [
    ThematicCategoryGroup(
      name: 'The Seven Sacraments',
      icon: '🕊️',
      themes: {
        'sacraments.eucharist': 'The Most Holy Eucharist & The Mass',
        'sacraments.baptism': 'Holy Baptism & Regeneration',
        'sacraments.confirmation': 'Confirmation & Holy Chrism',
        'sacraments.penance': 'Penance, Confession & Absolution',
        'sacraments.holy_orders': 'Holy Orders & The Priesthood',
        'sacraments.matrimony': 'Holy Matrimony & Family',
        'sacraments.anointing_of_sick': 'Anointing of the Sick',
        'sacraments.general_liturgy': 'Sacraments in General & Liturgy',
      },
    ),
    ThematicCategoryGroup(
      name: 'God & Sacred Dogma',
      icon: '🏛️',
      themes: {
        'theology.trinity': 'The Holy Trinity & Divine Nature',
        'theology.christ_incarnation': 'Incarnation & Divinity of Christ',
        'theology.redemption_cross': 'Passion, Redemption & The Cross',
        'theology.holy_spirit_grace': 'Holy Spirit & Sanctifying Grace',
        'theology.creation_providence': 'Creation, Providence & Angels',
        'theology.scripture_tradition': 'Scripture, Tradition & Dogma',
      },
    ),
    ThematicCategoryGroup(
      name: 'Prayer & Mystical Life',
      icon: '🕯️',
      themes: {
        'prayer.vocal_mental_meditation': 'Vocal & Mental Prayer, Our Father',
        'prayer.contemplation_union': 'Contemplation & Divine Union',
        'prayer.spiritual_dryness_dark_night': 'Spiritual Dryness & Dark Night',
        'prayer.conformity_divine_will': 'Conformity to God\'s Will',
      },
    ),
    ThematicCategoryGroup(
      name: 'Spiritual Combat & Ascetics',
      icon: '⚔️',
      themes: {
        'combat.temptation_sin': 'Temptations & Capital Sins',
        'combat.spiritual_warfare': 'Spiritual Warfare & Discernment',
        'combat.mortification_detachment':
            'Fasting, Mortification & Detachment',
        'combat.suffering_cross': 'Suffering & Bearing Trials',
      },
    ),
    ThematicCategoryGroup(
      name: 'Moral Virtues & Christian Living',
      icon: '🌿',
      themes: {
        'virtues.faith_hope_charity':
            'Theological Virtues: Faith, Hope & Charity',
        'virtues.humility_meekness': 'Humility & Meekness',
        'virtues.mercy_neighbor_almsgiving':
            'Love of Neighbor & Works of Mercy',
        'virtues.purity_modesty': 'Purity of Heart & Chastity',
        'virtues.daily_duties_state_in_life': 'Faithfulness in Daily Duties',
      },
    ),
    ThematicCategoryGroup(
      name: 'The Church & Authority',
      icon: '⛪',
      themes: {
        'ecclesiology.church_unity_papacy': 'Unity of the Church & Papacy',
        'ecclesiology.apostolic_succession': 'Apostolic Succession & Bishops',
        'ecclesiology.church_and_state': 'Church in the World & Persecution',
      },
    ),
    ThematicCategoryGroup(
      name: 'Our Lady, Saints & Eternity',
      icon: '👑',
      themes: {
        'devotion.our_lady': 'The Blessed Virgin Mary & Consecration',
        'devotion.angels_communion_of_saints': 'Angels & Communion of Saints',
        'eschatology.death_judgment': 'Death & Particular/General Judgment',
        'eschatology.heaven_beatific_vision': 'Heaven & Beatific Vision',
        'eschatology.purgatory_hell': 'Purgatory & Eternal Hell',
      },
    ),
  ];

  static final Map<String, Map<String, String>> categories = Map.unmodifiable({
    for (final group in categoryGroups)
      group.name: Map<String, String>.unmodifiable(group.themes),
  });

  static final Map<String, String> allThemes = Map.unmodifiable({
    for (final group in categoryGroups) ...group.themes,
  });

  static String getThemeTitle(String themeId) => allThemes[themeId] ?? themeId;

  static bool isValidTheme(String themeId) => allThemes.containsKey(themeId);

  static String? normalizeTheme(String? themeId) {
    if (themeId == null) return null;
    final cleaned = themeId
        .replaceAll('`', '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .trim()
        .toLowerCase();
    for (final key in allThemes.keys) {
      if (key.toLowerCase() == cleaned) return key;
    }
    return null;
  }
}
