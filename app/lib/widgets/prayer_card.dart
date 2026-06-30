import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayers.dart';

class _PrayerHistory {
  final String author;
  final String origin;
  final String description;

  const _PrayerHistory({
    required this.author,
    required this.origin,
    required this.description,
  });
}

const Map<String, _PrayerHistory> _prayerHistories = {
  'our_father': _PrayerHistory(
    author: 'Jesus Christ',
    origin: 'Gospel of Matthew 6:9–13',
    description:
        'Taught directly by Jesus to His disciples when they asked Him how to pray. It is the fundamental Christian prayer.',
  ),
  'hail_mary': _PrayerHistory(
    author: 'Angel Gabriel & St. Elizabeth',
    origin: 'Gospel of Luke 1:28, 42',
    description:
        'Combines the Angelic Salutation, Elizabeth’s greeting, and an ecclesial petition finalized in the 16th century.',
  ),
  'glory_be': _PrayerHistory(
    author: 'Early Church Fathers',
    origin: 'Traditional Christian Doxology',
    description:
        'A trinitarian doxology used to glorify the Father, Son, and Holy Spirit, tracing back to the early Councils.',
  ),
};

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
                if (_selectedPhraseId == token.id) {
                  _selectedPhraseId = null;
                } else {
                  _selectedPhraseId = token.id;
                  if (!_isDualMode) {
                    _isDualMode = true;
                  }
                }
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

    final history = _prayerHistories[widget.prayer.prayerId];

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
                // Header Row (Left Column, Middle Split Button, Right Column/Historical Context)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Title 1, Subtitle 1, Dropdown 1
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Text(
                              translation.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Center(
                            child: Text(
                              translation.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: _buildLanguageDropdown(
                              resolvedLanguage,
                              widget.onLanguageChanged,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Middle Column: Split Toggle aligned with dropdowns
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 42), // Alignment offset
                        IconButton(
                          icon: RotatedBox(
                            quarterTurns: 1,
                            child: Icon(
                              _isDualMode
                                  ? Icons.splitscreen
                                  : Icons.splitscreen_outlined,
                              color: _isDualMode
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          tooltip: 'Compare Translations',
                          onPressed: () {
                            setState(() {
                              _isDualMode = !_isDualMode;
                              _selectedPhraseId = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Right Column: Title 2, Subtitle 2, Dropdown 2 OR Historical Context
                    Expanded(
                      child: _isDualMode
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Text(
                                    compareTranslation.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Center(
                                  child: Text(
                                    compareTranslation.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: _buildLanguageDropdown(
                                    resolvedCompareLanguage,
                                    (lang) {
                                      if (lang != null) {
                                        setState(() {
                                          _compareLanguage = lang;
                                          _selectedPhraseId = null;
                                        });
                                      }
                                    },
                                    theme,
                                  ),
                                ),
                              ],
                            )
                          : (history != null
                                ? _buildHistoryPanel(history, theme)
                                : const SizedBox.shrink()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Divider
                Divider(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  height: 1,
                ),
                const SizedBox(height: 16),

                // 4. Content Row: Prayer 1 | Prayer 2 (conditional)
                if (_isDualMode)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildPrayerText(
                            translation,
                            resolvedLanguage,
                            theme,
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
                        Expanded(
                          child: _buildPrayerText(
                            compareTranslation,
                            resolvedCompareLanguage,
                            theme,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildPrayerText(translation, resolvedLanguage, theme),
                const SizedBox(height: 20),

                // Divider for Footer
                Divider(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  height: 1,
                ),
                const SizedBox(height: 12),

                // 5. Source Row: Source 1 | Source 2 (conditional)
                if (_isDualMode)
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: _buildSourceButton(translation, theme),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const SizedBox(width: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Center(
                          child: _buildSourceButton(compareTranslation, theme),
                        ),
                      ),
                    ],
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: _buildSourceButton(translation, theme)),
                    ],
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton(PrayerTranslation translation, ThemeData theme) {
    if (translation.sourceUrl.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: () => widget.onLaunchSource(translation.sourceUrl),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Source: ${translation.sourceName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary.withValues(
                    alpha: 0.5,
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 12,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel(_PrayerHistory history, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_edu,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'HISTORICAL CONTEXT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Origin: ${history.origin}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            history.description,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
