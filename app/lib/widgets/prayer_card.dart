import 'package:flutter/gestures.dart';
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
  bool _isDualMode = false;
  PrayerLanguage? _compareLanguage;
  String? _selectedPhraseId;

  @override
  void didUpdateWidget(covariant PrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset version index if language or prayer changes
    if (oldWidget.selectedLanguage != widget.selectedLanguage ||
        oldWidget.prayer.prayerId != widget.prayer.prayerId) {
      _currentVersionIndex = 0;
    }
  }

  Widget _buildLanguageDropdown(
    PrayerLanguage value,
    ValueChanged<PrayerLanguage?> onChanged,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PrayerLanguage>(
          value: value,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          dropdownColor: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          alignment: Alignment.centerRight,
          onChanged: onChanged,
          items: PrayerLanguage.values
              .where((lang) => widget.prayer.translations.containsKey(lang))
              .map((lang) {
                return DropdownMenuItem<PrayerLanguage>(
                  value: lang,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 16)),
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
              })
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPrayerText(
    PrayerTranslation trans,
    PrayerLanguage lang,
    ThemeData theme,
  ) {
    // Chinese Character rendering with Pinyin grid
    if (trans.chineseLines != null) {
      return Column(
        children: trans.chineseLines!.map((line) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 4,
              children: (line.chars ?? []).map((charItem) {
                final isPunct = charItem.pinyin.isEmpty;
                final isSelected =
                    charItem.phraseId != null &&
                    charItem.phraseId == _selectedPhraseId;

                return GestureDetector(
                  onTap: charItem.phraseId != null
                      ? () {
                          setState(() {
                            _selectedPhraseId =
                                (_selectedPhraseId == charItem.phraseId)
                                ? null
                                : charItem.phraseId;
                          });
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 1.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.8,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          charItem.char,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPunct ? '' : charItem.pinyin,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.7)
                                : theme.colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      );
    }

    // Text rendering with phrase alignments
    if (trans.tokens != null && trans.tokens!.isNotEmpty) {
      final List<InlineSpan> spans = [];
      for (final token in trans.tokens!) {
        if (token.id != null) {
          final isSelected = token.id == _selectedPhraseId;
          final recognizer = TapGestureRecognizer()
            ..onTap = () {
              setState(() {
                _selectedPhraseId = (_selectedPhraseId == token.id)
                    ? null
                    : token.id;
              });
            };
          spans.add(
            TextSpan(
              text: token.text,
              recognizer: recognizer,
              style: TextStyle(
                backgroundColor: isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.8)
                    : null,
                decoration: isSelected ? null : TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
                decorationColor: theme.colorScheme.primary.withValues(
                  alpha: 0.5,
                ),
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: token.text,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
              ),
            ),
          );
        }
      }
      return Text.rich(
        TextSpan(children: spans),
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          fontSize: 16.0,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
      );
    }

    // Fallback: plain text
    return Text(
      trans.text,
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
        fontSize: 16.0,
        letterSpacing: 0.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedLanguage =
        widget.prayer.translations.containsKey(widget.selectedLanguage)
        ? widget.selectedLanguage
        : (widget.prayer.translations.containsKey(PrayerLanguage.english)
              ? PrayerLanguage.english
              : widget.prayer.translations.keys.first);

    final translations = widget.prayer.translations[resolvedLanguage]!;
    final versionIndex = _currentVersionIndex < translations.length
        ? _currentVersionIndex
        : 0;
    final translation = translations[versionIndex];

    // Dual mode compare language resolution
    final resolvedCompareLanguage =
        _compareLanguage ??
        widget.prayer.translations.keys.firstWhere(
          (lang) => lang != resolvedLanguage,
          orElse: () => resolvedLanguage,
        );
    final compareTranslations =
        widget.prayer.translations[resolvedCompareLanguage]!;
    final compareTranslation =
        compareTranslations[0]; // compare default first version

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (translations.length <= 1) return;
        if (_isDualMode) {
          return; // disable swiping version in dual compare mode to avoid visual clutter
        }

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
                        _getPrayerIcon(widget.prayer.prayerId),
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and Subtitle (single mode) or Dual Mode Title
                    Expanded(
                      child: _isDualMode
                          ? Text(
                              widget.prayer.defaultTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            )
                          : Column(
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
                    // Dual mode toggle and dropdown language selectors
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isDualMode
                                ? Icons.splitscreen
                                : Icons.splitscreen_outlined,
                            color: _isDualMode
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          tooltip: 'Compare Translations',
                          onPressed: () {
                            setState(() {
                              _isDualMode = !_isDualMode;
                              _selectedPhraseId = null; // Reset highlights
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        _buildLanguageDropdown(
                          resolvedLanguage,
                          widget.onLanguageChanged,
                          theme,
                        ),
                        if (_isDualMode) ...[
                          const SizedBox(width: 8),
                          _buildLanguageDropdown(resolvedCompareLanguage, (
                            lang,
                          ) {
                            if (lang != null) {
                              setState(() {
                                _compareLanguage = lang;
                                _selectedPhraseId = null;
                              });
                            }
                          }, theme),
                        ],
                      ],
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

                // Content View (Single Pane or Parallel Dual Columns)
                if (_isDualMode)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Selected Language translation
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Text(
                                  translation.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (translation.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Center(
                                  child: Text(
                                    translation.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _buildPrayerText(
                                translation,
                                resolvedLanguage,
                                theme,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 1,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right Column: Compare Language translation
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Text(
                                  compareTranslation.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (compareTranslation.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Center(
                                  child: Text(
                                    compareTranslation.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _buildPrayerText(
                                compareTranslation,
                                resolvedCompareLanguage,
                                theme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildPrayerText(translation, resolvedLanguage, theme),

                const SizedBox(height: 20),
                // Divider
                Divider(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  height: 1,
                ),
                const SizedBox(height: 12),

                // Footer Source link(s)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: () =>
                            widget.onLaunchSource(translation.sourceUrl),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 8.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                                  _isDualMode
                                      ? '${resolvedLanguage.nativeName} Source'
                                      : 'Source: ${translation.sourceName}',
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
                    ),
                    if (_isDualMode) ...[
                      const SizedBox(width: 16),
                      Flexible(
                        child: InkWell(
                          onTap: () => widget.onLaunchSource(
                            compareTranslation.sourceUrl,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 8.0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                                    '${resolvedCompareLanguage.nativeName} Source',
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
                      ),
                    ],
                  ],
                ),

                // Version dots indicator if multiple translations exist (single mode only)
                if (translations.length > 1 && !_isDualMode) ...[
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
