import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/library_database.dart';

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

class ThematicHelper {
  static List<ThematicPassage>? _cachedPassages;
  static const String assetPath = 'assets/catechism/thematic_index.json';

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

  static Map<String, String> get allThemes {
    final map = <String, String>{};
    for (final group in categoryGroups) {
      map.addAll(group.themes);
    }
    return map;
  }

  static String getThemeTitle(String themeId) {
    return allThemes[themeId] ?? themeId;
  }

  static Future<List<ThematicPassage>> loadAllPassages({
    bool forceReload = false,
  }) async {
    if (_cachedPassages != null && !forceReload) {
      return _cachedPassages!;
    }

    try {
      final raw = await rootBundle.loadString(assetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final passagesRaw = data['passages'] as List<dynamic>? ?? [];

      final catalog = LibraryHelper.getCatalog();
      final Map<String, String?> bookSaintMap = {};
      for (final b in catalog) {
        bookSaintMap[b.id] = b.authorSaintId;
        if (b.volumes != null) {
          for (final v in b.volumes!) {
            bookSaintMap[v.volumeKey] = b.authorSaintId;
          }
        }
      }

      _cachedPassages = passagesRaw.map((p) {
        final map = p as Map<String, dynamic>;
        final bookId = map['bookId'] as String? ?? '';
        final saintId = bookSaintMap[bookId];
        return ThematicPassage.fromJson(map, authorSaintId: saintId);
      }).toList();

      return _cachedPassages!;
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, int>> getThemeCounts() async {
    final passages = await loadAllPassages();
    final counts = <String, int>{};
    for (final p in passages) {
      counts[p.primaryTheme] = (counts[p.primaryTheme] ?? 0) + 1;
      for (final s in p.secondaryThemes) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    return counts;
  }

  static Future<List<ThematicPassage>> getPassagesForTheme(
    String themeId, {
    bool shuffle = true,
  }) async {
    final passages = await loadAllPassages();
    final filtered = passages
        .where(
          (p) =>
              p.primaryTheme == themeId || p.secondaryThemes.contains(themeId),
        )
        .toList();

    if (shuffle && filtered.isNotEmpty) {
      filtered.shuffle(Random());
    }
    return filtered;
  }
}
