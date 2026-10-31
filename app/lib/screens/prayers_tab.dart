import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/widgets/scripture_footer_quote.dart';
import 'package:twelve_stars/widgets/two_column_sliver_list.dart';

/// Displays the searchable list or widescreen 2-column grid of Catholic prayers
/// in the Prayers tab of [HomeScreen].
class PrayersTab extends StatelessWidget {
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  final List<Prayer>? prayers;
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage? compareLanguage;
  final UserSettings? settings;
  final double fontSize;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final ScrollController scrollController;
  final Animation<double> languageSelectorAnimation;
  final double topSpacerHeight;
  final bool isWide;

  const PrayersTab({
    super.key,
    required this.prayers,
    required this.primaryLanguage,
    required this.compareLanguage,
    required this.settings,
    required this.fontSize,
    required this.searchQuery,
    required this.onClearSearch,
    required this.scrollController,
    required this.languageSelectorAnimation,
    this.topSpacerHeight = 92.0,
    required this.isWide,
  });

  Widget _buildPrayerCard(Prayer prayer) {
    final prefKey = '${prayer.prayerId}_${primaryLanguage.code}';
    final initialVersion = settings?.getPreferredVersionIndex(prefKey) ?? 0;

    return RepaintBoundary(
      child: PrayerCard(
        key: ValueKey(prayer.prayerId),
        prayer: prayer,
        selectedLanguage: primaryLanguage,
        compareLanguage: compareLanguage,
        initialVersionIndex: initialVersion,
        fontSize: fontSize,
        onVersionChanged: (newIndex) async {
          await UserSettingsController.instance.mutate((s) {
            s.setPreferredVersionIndex(prefKey, newIndex);
          });
        },
      ),
    );
  }

  Widget _buildFooterQuote() {
    return const ScriptureFooterQuote(
      quote:
          '“A great sign appeared in heaven: a woman clothed with the sun, with the moon under her feet, and on her head a crown of twelve stars.”',
      attribution: '— Revelation 12:1',
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPrayers = prayers;
    if (allPrayers == null || allPrayers.isEmpty) {
      return const Center(child: Text('No prayers found.'));
    }

    final theme = Theme.of(context);
    final query = searchQuery.trim().toLowerCase();
    final queryWords = query.isEmpty
        ? const <String>[]
        : query.split(_whitespaceRegex).where((w) => w.isNotEmpty).toList();

    final filteredPrayers = allPrayers.where((prayer) {
      if (prayer.category == 'liturgy') return false;
      final transList = prayer.translations[primaryLanguage];
      if (transList == null || transList.isEmpty) return false;
      if (queryWords.isEmpty) return true;

      final compareList =
          (compareLanguage != null && compareLanguage != primaryLanguage)
          ? (prayer.translations[compareLanguage!] ??
                const <PrayerTranslation>[])
          : const <PrayerTranslation>[];
      final defaultTitle = prayer.defaultTitle.toLowerCase();

      bool matchesTranslation(PrayerTranslation trans, String word) {
        return trans.title.toLowerCase().contains(word) ||
            trans.subtitle.toLowerCase().contains(word) ||
            trans.text.toLowerCase().contains(word);
      }

      return queryWords.every((word) {
        return defaultTitle.contains(word) ||
            transList.any((t) => matchesTranslation(t, word)) ||
            compareList.any((t) => matchesTranslation(t, word));
      });
    }).toList();

    if (filteredPrayers.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          SizeTransition(
            sizeFactor: languageSelectorAnimation,
            alignment: Alignment.topCenter,
            child: SizedBox(height: topSpacerHeight),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Text(
                  'No prayers matching "$searchQuery"',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onClearSearch,
                  child: const Text('Clear search'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (isWide) {
      return CustomScrollView(
        controller: scrollController,
        scrollCacheExtent: const ScrollCacheExtent.pixels(10000.0),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 12.0,
              ),
              child: SizeTransition(
                sizeFactor: languageSelectorAnimation,
                alignment: Alignment.topCenter,
                child: SizedBox(height: topSpacerHeight),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: TwoColumnSliverList(
              itemCount: filteredPrayers.length,
              itemBuilder: (context, index) =>
                  _buildPrayerCard(filteredPrayers[index]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 12.0,
              ),
              child: _buildFooterQuote(),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      scrollCacheExtent: const ScrollCacheExtent.pixels(10000.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: filteredPrayers.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return SizeTransition(
            sizeFactor: languageSelectorAnimation,
            alignment: Alignment.topCenter,
            child: SizedBox(height: topSpacerHeight),
          );
        }
        if (index == filteredPrayers.length + 1) {
          return _buildFooterQuote();
        }

        final prayer = filteredPrayers[index - 1];
        return _buildPrayerCard(prayer);
      },
    );
  }
}
