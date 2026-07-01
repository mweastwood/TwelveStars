import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayers.dart';

class PrayerCard extends StatefulWidget {
  final Prayer prayer;
  final PrayerLanguage selectedLanguage;
  final PrayerLanguage compareLanguage;
  final Function(String) onLaunchSource;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.selectedLanguage,
    required this.compareLanguage,
    required this.onLaunchSource,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
  int _currentVersionIndex = 0;
  bool _isDualMode = false;
  String? _selectedPhraseId;

  PrayerTranslation? get _activeTranslationWithHistory {
    // 1. Try selected translation
    final selectedTranslations =
        widget.prayer.translations[widget.selectedLanguage];
    if (selectedTranslations != null &&
        _currentVersionIndex < selectedTranslations.length) {
      final selectedTrans = selectedTranslations[_currentVersionIndex];
      if (selectedTrans.historyDescription.isNotEmpty) return selectedTrans;
    }

    // 2. Try compare translation
    if (_isDualMode) {
      final compareTranslations =
          widget.prayer.translations[widget.compareLanguage];
      if (compareTranslations != null && compareTranslations.isNotEmpty) {
        final compareTrans = compareTranslations[0];
        if (compareTrans.historyDescription.isNotEmpty) return compareTrans;
      }
    }

    // 3. Fall back to English translation
    final englishTranslations =
        widget.prayer.translations[PrayerLanguage.english];
    if (englishTranslations != null && englishTranslations.isNotEmpty) {
      final englishTrans = englishTranslations[0];
      if (englishTrans.historyDescription.isNotEmpty) return englishTrans;
    }

    return null;
  }

  @override
  void didUpdateWidget(covariant PrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset version index if language or prayer changes
    if (oldWidget.selectedLanguage != widget.selectedLanguage ||
        oldWidget.prayer.prayerId != widget.prayer.prayerId) {
      _currentVersionIndex = 0;
    }
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
        widget.prayer.translations.containsKey(widget.compareLanguage)
        ? widget.compareLanguage
        : (widget.prayer.translations.containsKey(PrayerLanguage.english)
              ? PrayerLanguage.english
              : widget.prayer.translations.keys.first);
    final compareTranslations =
        widget.prayer.translations[resolvedCompareLanguage]!;
    final compareTranslation =
        compareTranslations[0]; // compare default first version

    final historyTrans = _activeTranslationWithHistory;

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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Row: Titles/Subtitles spanning full width
                  _isDualMode
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column Title/Subtitle
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 32,
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 12),
                            // Right Column Title/Subtitle with padding to avoid overlaying split button
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 36),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      compareTranslation.title,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                    if (compareTranslation
                                        .subtitle
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        compareTranslation.subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: 36),
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
                  const SizedBox(height: 12),

                  // Divider
                  Divider(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  // 2. Content Row: Prayer 1 | Prayer 2 (conditional)
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

                  // 3. Source Row: Source Buttons
                  if (_isDualMode)
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: _buildSourceButton(translation, theme),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 1,
                        ), // spacer matching vertical divider
                        const SizedBox(width: 12),
                        Expanded(
                          child: Center(
                            child: _buildSourceButton(
                              compareTranslation,
                              theme,
                            ),
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
                  ],

                  // 4. Historical Context Row: Rendered below Source
                  if (historyTrans != null) ...[
                    const SizedBox(height: 12),
                    _buildHistoryPanel(
                      historyTrans.historyOrigin,
                      historyTrans.historyDescription,
                      theme,
                    ),
                  ],

                  // 5. Version indicator dots
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
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
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
            ),
          ],
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

  Widget _buildHistoryPanel(
    String origin,
    String description,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.history_edu, size: 14, color: theme.colorScheme.primary),
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
          'Origin: $origin',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
