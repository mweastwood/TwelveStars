import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayers.dart';

class PrayerCard extends StatefulWidget {
  final Prayer prayer;
  final PrayerLanguage selectedLanguage;
  final ValueChanged<PrayerLanguage?> onLanguageChanged;
  final Function(String) onLaunchSource;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.onLaunchSource,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
  int _currentVersionIndex = 0;

  @override
  void didUpdateWidget(covariant PrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset version index if language or prayer changes
    if (oldWidget.selectedLanguage != widget.selectedLanguage ||
        oldWidget.prayer.id != widget.prayer.id) {
      _currentVersionIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations =
        widget.prayer.translations[widget.selectedLanguage] ??
        widget.prayer.translations[PrayerLanguage.english]!;

    // Safe bound check
    final versionIndex = _currentVersionIndex < translations.length
        ? _currentVersionIndex
        : 0;
    final translation = translations[versionIndex];
    final theme = Theme.of(context);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (translations.length <= 1) return;

        if (details.primaryVelocity! < 0) {
          // Swiped left -> next version
          setState(() {
            _currentVersionIndex =
                (_currentVersionIndex + 1) % translations.length;
          });
        } else if (details.primaryVelocity! > 0) {
          // Swiped right -> previous version
          setState(() {
            _currentVersionIndex =
                (_currentVersionIndex - 1 + translations.length) %
                translations.length;
          });
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.2,
                ),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon indicator
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getPrayerIcon(widget.prayer.id),
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translation.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (translation.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              translation.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Dropdown language selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PrayerLanguage>(
                          value: widget.selectedLanguage,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          dropdownColor: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          alignment: Alignment.centerRight,
                          onChanged: widget.onLanguageChanged,
                          items: PrayerLanguage.values.map((lang) {
                            return DropdownMenuItem<PrayerLanguage>(
                              value: lang,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    lang.flag,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    lang.nativeName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Divider
                Divider(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  height: 1,
                ),
                const SizedBox(height: 16),
                // Prayer Text
                if (translation.chineseLines != null)
                  Column(
                    children: translation.chineseLines!.map((line) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 2,
                          runSpacing: 4,
                          children: line.map((charItem) {
                            final isPunct = charItem.pinyin.isEmpty;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1.0,
                                vertical: 2.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    charItem.char,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPunct ? '' : charItem.pinyin,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    translation.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.95,
                      ),
                      fontSize: 16.0,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                // Divider
                Divider(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  height: 1,
                ),
                const SizedBox(height: 12),
                // Footer Source link
                InkWell(
                  onTap: () => widget.onLaunchSource(translation.sourceUrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Source: ${translation.sourceName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.open_in_new,
                          size: 12,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Version dots indicator if multiple translations exist
                if (translations.length > 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(translations.length, (index) {
                      final isSelected = index == versionIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.8,
                                ),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPrayerIcon(String id) {
    switch (id) {
      case 'our_father':
        return Icons.person_outline;
      case 'hail_mary':
        return Icons.stars_outlined;
      case 'glory_be':
        return Icons.wb_sunny_outlined;
      default:
        return Icons.auto_stories;
    }
  }
}
