import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/theme/app_theme_tokens.dart';

/// Presentation-layer UI helpers for [SaintCategory].
extension SaintCategoryUiExtension on SaintCategory {
  /// Icon corresponding to the category.
  IconData get icon {
    switch (this) {
      case SaintCategory.group:
        return Icons.groups_3_rounded;
      case SaintCategory.holyFamily:
        return Icons.family_restroom_rounded;
      case SaintCategory.angel:
        return Icons.flare_rounded;
      case SaintCategory.patriarch:
        return Icons.foundation_rounded;
      case SaintCategory.prophet:
        return Icons.record_voice_over_rounded;
      case SaintCategory.judge:
        return Icons.gavel_rounded;
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
      case SaintCategory.patriarch:
        return const Color(0xFF8D6E63); // Brown 400
      case SaintCategory.prophet:
        return const Color(0xFFC2410C); // Deep Orange / Terracotta 700
      case SaintCategory.judge:
        return const Color(0xFF475569); // Slate 600
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

  /// Identifier key used for UI filter chips and testing.
  String get filterChipKey {
    switch (this) {
      case SaintCategory.group:
        return 'group_filter_chip';
      case SaintCategory.holyFamily:
        return 'holy_family_filter_chip';
      case SaintCategory.angel:
        return 'angels_filter_chip';
      case SaintCategory.patriarch:
        return 'patriarchs_filter_chip';
      case SaintCategory.prophet:
        return 'prophets_filter_chip';
      case SaintCategory.judge:
        return 'judges_filter_chip';
      case SaintCategory.apostle:
        return 'apostles_filter_chip';
      case SaintCategory.evangelist:
        return 'evangelists_filter_chip';
      case SaintCategory.doctor:
        return 'doctor_filter_chip';
      case SaintCategory.pope:
        return 'popes_filter_chip';
      case SaintCategory.bishop:
        return 'bishops_filter_chip';
      case SaintCategory.priest:
        return 'priests_filter_chip';
      case SaintCategory.deacon:
        return 'deacons_filter_chip';
      case SaintCategory.brother:
        return 'brothers_filter_chip';
      case SaintCategory.nun:
        return 'nuns_filter_chip';
      case SaintCategory.monarch:
        return 'monarchs_filter_chip';
      case SaintCategory.martyr:
        return 'martyrs_filter_chip';
      case SaintCategory.healerMissionary:
        return 'healers_filter_chip';
      case SaintCategory.virgin:
        return 'virgins_filter_chip';
      case SaintCategory.mystic:
        return 'mystics_filter_chip';
      case SaintCategory.laity:
        return 'laity_filter_chip';
      case SaintCategory.other:
        return 'other_filter_chip';
    }
  }
}

/// Presentation-layer UI helpers for [SaintSortOption].
extension SaintSortOptionUiExtension on SaintSortOption {
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

/// Presentation-layer UI helpers for [Saint].
extension SaintUiExtension on Saint {
  /// Icon corresponding to the primary category.
  IconData get categoryIcon => category.icon;

  /// Color tint for primary category badge/icon.
  Color categoryColor(ThemeData theme) => category.color(theme);
}
