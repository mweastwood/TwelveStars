import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/theme/app_theme_tokens.dart';
import 'package:twelve_stars/widgets/saints/saint_ui_extensions.dart';

void main() {
  group('SaintCategory pure domain properties', () {
    test('exposes non-empty label and filterLabel for every value', () {
      for (final category in SaintCategory.values) {
        expect(category.label, isNotEmpty);
        expect(category.filterLabel, isNotEmpty);
      }
      expect(SaintCategory.doctor.label, 'Doctor of the Church');
      expect(SaintCategory.doctor.filterLabel, 'Doctors of the Church');
      expect(SaintCategory.other.label, 'Saint');
      expect(SaintCategory.other.filterLabel, 'Other');
    });
  });

  group('SaintSortOption pure domain properties', () {
    test('exposes non-empty label for every sort option', () {
      for (final option in SaintSortOption.values) {
        expect(option.label, isNotEmpty);
      }
      expect(SaintSortOption.nameAsc.label, 'Name (A–Z)');
      expect(SaintSortOption.nameDesc.label, 'Name (Z–A)');
      expect(SaintSortOption.feastDay.label, 'Feast Day (Jan–Dec)');
      expect(SaintSortOption.chronologicalAsc.label, 'Timeline (Oldest first)');
      expect(
        SaintSortOption.chronologicalDesc.label,
        'Timeline (Newest first)',
      );
      expect(SaintSortOption.doctorsFirst.label, 'Doctors & Apostles first');
    });
  });

  group('Saint pure domain properties', () {
    test('computes primary category, shortName, invocationName, and era', () {
      const saint = Saint(
        id: 'thomas-aquinas',
        name: 'St. Thomas Aquinas',
        birthDate: '1225',
        deathDate: '1274',
        nationality: 'Italian',
        profession: 'Dominican Friar & Theologian',
        categories: [SaintCategory.priest, SaintCategory.doctor],
        isDoctor: true,
        feastDay: 'January 28',
        gender: 'male',
      );

      expect(saint.categories, [SaintCategory.doctor, SaintCategory.priest]);
      expect(saint.category, SaintCategory.doctor);
      expect(saint.shortName, 'Thomas Aquinas');
      expect(saint.invocationName, 'St. Thomas Aquinas');
      expect(saint.dateRange, '1225 – 1274');
      expect(saint.approximateYear, 1274);
      expect(saint.era, SaintEra.medieval);
      expect(saint.feastMonth, 1);
      expect(saint.feastDayOfMonth, 28);
      expect(saint.isMale, isTrue);
      expect(saint.isFemale, isFalse);
    });
  });

  group('SaintCategoryUiExtension', () {
    test('returns expected icon for every SaintCategory', () {
      final expectedIcons = <SaintCategory, IconData>{
        SaintCategory.group: Icons.groups_3_rounded,
        SaintCategory.holyFamily: Icons.family_restroom_rounded,
        SaintCategory.angel: Icons.flare_rounded,
        SaintCategory.patriarch: Icons.foundation_rounded,
        SaintCategory.prophet: Icons.record_voice_over_rounded,
        SaintCategory.judge: Icons.gavel_rounded,
        SaintCategory.apostle: Icons.stars_rounded,
        SaintCategory.evangelist: Icons.auto_stories_rounded,
        SaintCategory.doctor: Icons.menu_book_rounded,
        SaintCategory.pope: Icons.vpn_key_rounded,
        SaintCategory.bishop: Icons.account_balance_rounded,
        SaintCategory.priest: Icons.church_rounded,
        SaintCategory.deacon: Icons.volunteer_activism_rounded,
        SaintCategory.brother: Icons.diversity_3_rounded,
        SaintCategory.nun: Icons.auto_awesome_rounded,
        SaintCategory.monarch: Icons.workspace_premium_rounded,
        SaintCategory.martyr: Icons.local_fire_department_rounded,
        SaintCategory.healerMissionary: Icons.healing_rounded,
        SaintCategory.virgin: Icons.local_florist_rounded,
        SaintCategory.mystic: Icons.wb_sunny_rounded,
        SaintCategory.laity: Icons.groups_rounded,
        SaintCategory.other: Icons.person_rounded,
      };

      for (final category in SaintCategory.values) {
        expect(category.icon, expectedIcons[category]);
      }
    });

    test('returns expected color in light and dark themes', () {
      final lightTheme = ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
      );
      final darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF60A5FA),
          brightness: Brightness.dark,
        ),
      );

      for (final category in SaintCategory.values) {
        if (category == SaintCategory.other) {
          expect(category.color(lightTheme), lightTheme.colorScheme.primary);
          expect(category.color(darkTheme), darkTheme.colorScheme.primary);
          expect(
            category.color(lightTheme),
            isNot(equals(category.color(darkTheme))),
          );
        } else {
          expect(category.color(lightTheme), equals(category.color(darkTheme)));
        }
      }

      expect(
        SaintCategory.apostle.color(lightTheme),
        AppThemeTokens.marianBlue,
      );
      expect(
        SaintCategory.doctor.color(lightTheme),
        AppThemeTokens.liturgicalGold,
      );
      expect(
        SaintCategory.bishop.color(lightTheme),
        AppThemeTokens.liturgicalPurple,
      );
      expect(
        SaintCategory.priest.color(lightTheme),
        AppThemeTokens.liturgicalGreen,
      );
      expect(
        SaintCategory.martyr.color(lightTheme),
        AppThemeTokens.liturgicalRed,
      );
      expect(
        SaintCategory.mystic.color(lightTheme),
        AppThemeTokens.liturgicalRose,
      );
    });

    test('returns expected filterChipKey for every SaintCategory', () {
      for (final category in SaintCategory.values) {
        expect(category.filterChipKey, isNotEmpty);
        expect(category.filterChipKey.endsWith('_filter_chip'), isTrue);
      }
      expect(SaintCategory.group.filterChipKey, 'group_filter_chip');
      expect(SaintCategory.holyFamily.filterChipKey, 'holy_family_filter_chip');
      expect(SaintCategory.angel.filterChipKey, 'angels_filter_chip');
      expect(SaintCategory.doctor.filterChipKey, 'doctor_filter_chip');
      expect(
        SaintCategory.healerMissionary.filterChipKey,
        'healers_filter_chip',
      );
      expect(SaintCategory.other.filterChipKey, 'other_filter_chip');
    });
  });

  group('SaintSortOptionUiExtension', () {
    test('returns expected icon for every SaintSortOption', () {
      expect(SaintSortOption.nameAsc.icon, Icons.sort_by_alpha);
      expect(SaintSortOption.nameDesc.icon, Icons.sort_by_alpha);
      expect(SaintSortOption.feastDay.icon, Icons.calendar_month);
      expect(SaintSortOption.chronologicalAsc.icon, Icons.history);
      expect(SaintSortOption.chronologicalDesc.icon, Icons.update);
      expect(SaintSortOption.doctorsFirst.icon, Icons.star);
    });
  });

  group('SaintUiExtension', () {
    test('delegates categoryIcon and categoryColor to primary category', () {
      final lightTheme = ThemeData.light(useMaterial3: true);
      final darkTheme = ThemeData.dark(useMaterial3: true);

      const doctorSaint = Saint(
        id: 'thomas-aquinas',
        name: 'St. Thomas Aquinas',
        nationality: 'Italian',
        profession: 'Theologian',
        categories: [SaintCategory.doctor, SaintCategory.priest],
        isDoctor: true,
      );

      expect(doctorSaint.categoryIcon, SaintCategory.doctor.icon);
      expect(
        doctorSaint.categoryColor(lightTheme),
        SaintCategory.doctor.color(lightTheme),
      );
      expect(
        doctorSaint.categoryColor(darkTheme),
        SaintCategory.doctor.color(darkTheme),
      );

      const otherSaint = Saint(
        id: 'unknown-saint',
        name: 'St. Unknown',
        nationality: 'Unknown',
        profession: 'Unknown',
        categories: [SaintCategory.other],
      );

      expect(otherSaint.categoryIcon, Icons.person_rounded);
      expect(
        otherSaint.categoryColor(lightTheme),
        lightTheme.colorScheme.primary,
      );
      expect(
        otherSaint.categoryColor(darkTheme),
        darkTheme.colorScheme.primary,
      );
    });
  });
}
